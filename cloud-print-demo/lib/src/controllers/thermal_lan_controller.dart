import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_wifi/psdk_fruit_wifi.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_thermal_lan_stub.dart';
import 'real_transport_helper.dart';

class ThermalLanController extends ChangeNotifier {
  ThermalLanController({
    required this.inspector,
    required DemoRunMode Function() modeGetter,
    required this.realTransportHelper,
  }) : _modeGetter = modeGetter {
    simWifiDevice = SimThermalWifiDevice(inspector: inspector);
    simLanBackend = SimThermalLanBackend(
      inspector: inspector,
      wifiDevice: simWifiDevice,
    );
  }

  final ProtocolInspectorController inspector;
  final DemoRunMode Function() _modeGetter;
  final RealTransportHelper realTransportHelper;

  late final SimThermalWifiDevice simWifiDevice;
  late final SimThermalLanBackend simLanBackend;

  ConnectedDevice<dynamic>? realBleDevice;
  Network? _network;
  ConnectedDevice<dynamic>? _tcpDevice;
  CloudCancelToken? _printCancelToken;

  WifiTextDialect selectedDialect = WifiTextDialect.bluetoothAt;
  bool busy = false;
  String statusMessage = 'Ready (Simulation Mode)';

  BluetoothWifiLinkState lastAtLinkState = BluetoothWifiLinkState.unknown;
  String? lastAtSsid;
  String? lastTsplDiagSummary;
  List<DiscoveredCloudPrinter> discoveredPrinters = <DiscoveredCloudPrinter>[];
  DiscoveredCloudPrinter? selectedPrinter;
  CloudJobProgress? printProgress;
  String? lastStreamResult;

  DemoRunMode get mode => _modeGetter();
  bool get isTcpConnected =>
      _tcpDevice != null &&
      _tcpDevice!.connectionState() == ConnectionState.connected;

  ConnectedDevice<dynamic> get _activeWifiDevice {
    if (mode == DemoRunMode.simulation) return simWifiDevice;
    final dev = realBleDevice;
    if (dev == null) {
      throw StateError('No Real BLE Thermal device connected');
    }
    return dev;
  }

  void setDialect(WifiTextDialect dialect) {
    selectedDialect = dialect;
    notifyListeners();
  }

  Future<void> runBluetoothAtProvisioning({
    required String ssid,
    required String password,
  }) async {
    await _runBusy('Running BLUETOOTH AT provisioning...', () async {
      BluetoothAtWifiCommands.validateStaCredentials(
        ssid: ssid,
        password: password,
      );
      final dev = _activeWifiDevice;
      final lineBuffer = BluetoothAtLinkStateBuffer();

      await _sendWifiCommand(
        dev,
        BluetoothAtWifiCommands.setSsidBytes(name: ssid, password: password),
      );
      final ssidReply = await _sendWifiCommand(
        dev,
        BluetoothAtWifiCommands.getSsidBytes(),
      );
      lastAtSsid = utf8.decode(ssidReply, allowMalformed: true).trim();

      // Exercise GETPASSWORD (redacted in inspector)
      await _sendWifiCommand(dev, BluetoothAtWifiCommands.getPasswordBytes());

      BluetoothWifiLinkState link = BluetoothWifiLinkState.unknown;
      for (var attempt = 0; attempt < 4; attempt++) {
        final chunk = await _sendWifiCommand(
          dev,
          BluetoothAtWifiCommands.getLinkStateBytes(),
        );
        final parsed = lineBuffer.addBytes(chunk);
        if (parsed != null && parsed != BluetoothWifiLinkState.unknown) {
          link = parsed;
        }
        if (link == BluetoothWifiLinkState.connected) break;
      }
      lastAtLinkState = link;
      statusMessage =
          'AT dialect: SSID="$lastAtSsid", Link=${lastAtLinkState.name}';
    });
  }

  Future<void> runTsplWlanProvisioning({
    required String ssid,
    required String password,
    bool dhcp = true,
    String staticIp = '192.168.1.77',
    String mask = '255.255.255.0',
    String gateway = '192.168.1.1',
    int role = 1,
    String lapSsid = 'ThermalPrinter_AP',
    String lapPassword = '',
    String lapIp = '192.168.1.1',
  }) async {
    await _runBusy('Running TSPL WLAN provisioning...', () async {
      final dev = _activeWifiDevice;
      final wifi = WIFI.genericWithConnectedDevice(dev);
      // Exercise BasicWIFI compatibility + TsplWlanCommands dialect
      await _sendBasicWifi(
        wifi.setWifiSSID(arg: WSetWifiSSID(name: ssid)),
        dev,
      );
      await _sendBasicWifi(
        wifi.setWifiPWD(arg: WSetWifiPWD(password: password)),
        dev,
      );
      if (dhcp) {
        await _sendBasicWifi(wifi.setWifiDHCP(), dev);
      } else {
        await _sendBasicWifi(
          wifi.setWifiIP(
            arg: WSetWifiIP(ip: staticIp, mask: mask, gateway: gateway),
          ),
          dev,
        );
      }
      await _sendWifiCommand(dev, TsplWlanCommands.setRoleBytes(role: role));
      await _sendWifiCommand(
        dev,
        TsplWlanCommands.setApParamsBytes(
          ssid: lapSsid,
          password: lapPassword,
          ip: lapIp,
        ),
      );
      final infoBytes = await _sendWifiCommand(
        dev,
        TsplWlanCommands.getInfoBytes(),
      );
      lastTsplDiagSummary = utf8.decode(infoBytes, allowMalformed: true).trim();
      statusMessage = 'TSPL WLAN configured -> $lastTsplDiagSummary';
    });
  }

  Future<void> resetTsplWlanDefaults() async {
    await _runBusy('Resetting TSPL WLAN defaults...', () async {
      final dev = _activeWifiDevice;
      final reply = await _sendWifiCommand(dev, TsplWlanCommands.resetBytes());
      lastTsplDiagSummary = utf8.decode(reply, allowMalformed: true).trim();
      statusMessage = 'WLAN DEFAULT -> $lastTsplDiagSummary';
    });
  }

  Future<void> discoverLanPrinters() async {
    await _runBusy('Scanning UDP 22368 printers...', () async {
      _network?.dispose();
      _network = mode == DemoRunMode.simulation
          ? simLanBackend.createScopedNetwork()
          : realTransportHelper.createRealNetwork(
              debugLogger: (msg) {
                inspector.recordText(
                  family: CloudPrinterFamily.thermalLanStream,
                  transport: 'Network',
                  direction: WireDirection.rx,
                  text: msg,
                  decodedSummary: msg,
                );
              },
            );

      final found = <DiscoveredCloudPrinter>[];
      await for (final printer in _network!.discoverPrinters(
        protocols: const <LanDiscoveryProtocol>{
          LanDiscoveryProtocol.udp22368Text,
        },
        timeout: mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 120)
            : const Duration(seconds: 4),
        probeInterval: mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 50)
            : const Duration(seconds: 1),
      )) {
        final idx = found.indexWhere((e) => e.id == printer.id);
        if (idx >= 0) {
          found[idx] = found[idx].mergeWith(printer);
        } else {
          found.add(printer);
        }
      }
      discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(found);
      if (discoveredPrinters.isNotEmpty) {
        selectedPrinter = discoveredPrinters.first;
      }
      statusMessage =
          'Discovered ${discoveredPrinters.length} printer(s) via UDP 22368';
    });
  }

  Future<void> connectTcpPrinter([DiscoveredCloudPrinter? target]) async {
    final printer = target ?? selectedPrinter;
    if (printer == null) {
      statusMessage = 'Discover or select a printer first';
      notifyListeners();
      return;
    }
    await _runBusy(
      'Connecting TCP ${printer.host}:${printer.port}...',
      () async {
        await disconnectTcpPrinter();
        _network ??= mode == DemoRunMode.simulation
            ? simLanBackend.createScopedNetwork()
            : realTransportHelper.createRealNetwork();
        _tcpDevice = await _network!.connect(
          printer.host,
          printer.port,
          networkInterface: printer.networkInterface,
        );
        selectedPrinter = printer;
        statusMessage = 'TCP connected to ${printer.host}:${printer.port}';
      },
    );
  }

  Future<void> streamTsplPrintJob({
    String text = 'PSDK Thermal LAN Demo',
    int copies = 1,
  }) async {
    final tcp = _tcpDevice;
    if (tcp == null || tcp.connectionState() != ConnectionState.connected) {
      statusMessage = 'Connect TCP :9100 printer first';
      notifyListeners();
      return;
    }
    await _runBusy('Streaming TSPL job over TCP :9100...', () async {
      final cancelToken = CloudCancelToken();
      _printCancelToken = cancelToken;
      final session = StreamJobSession(
        device: tcp,
        chunkSize: 128,
        cancelToken: cancelToken,
        onProgress: (p) {
          printProgress = p;
          notifyListeners();
        },
      );
      try {
        final tspl =
            'SIZE 80 mm,50 mm\r\n'
            'GAP 2 mm,0 mm\r\n'
            'CLS\r\n'
            'TEXT 30,40,"TSS24.BF2",0,1,1,"$text"\r\n'
            'BARCODE 30,90,"128",60,1,0,2,2,"PSDK-LAN-9100"\r\n'
            'PRINT $copies,1\r\n';
        final payload = Uint8List.fromList(utf8.encode(tspl));
        await session.writeChunked(
          payload,
          stage: CloudJobStage.sending,
          currentPage: 1,
          totalPages: 1,
          totalJobBytes: payload.length,
          sendDoneAtEnd: true,
        );
        session.reportProgress(
          CloudJobProgress(
            stage: CloudJobStage.completed,
            currentPage: 1,
            totalPages: 1,
            bytesSent: session.bytesTransferred,
            totalBytes: payload.length,
            message: 'TSPL stream completed',
          ),
        );
        lastStreamResult =
            'Streamed ${session.bytesTransferred} B to ${selectedPrinter?.host ?? "printer"}:${selectedPrinter?.port ?? 9100}';
        statusMessage = lastStreamResult!;
      } on CloudCancelledException catch (e) {
        lastStreamResult = 'Stream cancelled: ${e.reason}';
        statusMessage = lastStreamResult!;
      } finally {
        _printCancelToken = null;
        await session.dispose();
      }
    });
  }

  void cancelTsplPrintJob() {
    _printCancelToken?.cancel('Cancelled by user');
  }

  Future<void> disconnectTcpPrinter() async {
    await _tcpDevice?.disconnect();
    _tcpDevice = null;
    notifyListeners();
  }

  Future<Uint8List> _sendBasicWifi(
    GenericWIFI wifi,
    ConnectedDevice<dynamic> dev,
  ) async {
    final completer = Completer<Uint8List>();
    final buf = <int>[];
    Timer? idle;
    late StreamSubscription<Uint8List> sub;
    sub = dev.read(ReadOptions(timeout: 2)).listen((chunk) {
      buf.addAll(chunk);
      idle?.cancel();
      idle = Timer(const Duration(milliseconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(Uint8List.fromList(buf));
        }
      });
    });
    try {
      await wifi.write();
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      idle?.cancel();
      await sub.cancel();
    }
  }

  Future<Uint8List> _sendWifiCommand(
    ConnectedDevice<dynamic> dev,
    Uint8List bytes,
  ) async {
    final completer = Completer<Uint8List>();
    final buf = <int>[];
    Timer? idle;
    late StreamSubscription<Uint8List> sub;
    sub = dev.read(ReadOptions(timeout: 2)).listen((chunk) {
      buf.addAll(chunk);
      idle?.cancel();
      idle = Timer(const Duration(milliseconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(Uint8List.fromList(buf));
        }
      });
    });
    try {
      await dev.write(bytes, sendDone: true);
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      idle?.cancel();
      await sub.cancel();
    }
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    busy = true;
    statusMessage = label;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      statusMessage = 'Error: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    await disconnectTcpPrinter();
    _network?.dispose();
    await simWifiDevice.disconnect();
    super.dispose();
  }
}
