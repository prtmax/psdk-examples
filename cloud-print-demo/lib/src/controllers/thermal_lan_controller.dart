import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_thermal_lan_stub.dart';
import 'inspected_device.dart';
import 'real_transport_helper.dart';
import 'lan_setup_controller.dart';
import '../stubs/sim_lan_ble_device.dart';

class ThermalLanController extends ChangeNotifier {
  ThermalLanController({
    required this.inspector,
    required DemoRunMode Function() modeGetter,
    required this.realTransportHelper,
  }) : _modeGetter = modeGetter {
    simBleDevice = SimulatedLanBleDevice(
      inspector: inspector,
      family: CloudPrinterFamily.thermalLanStream,
      assignedIp: '192.168.1.77',
    );
    simLanBackend = SimThermalLanBackend(
      inspector: inspector,
      wifiDevice: simBleDevice,
    );
    setup = LanSetupController(
      family: CloudPrinterFamily.thermalLanStream,
      inspector: inspector,
      modeGetter: modeGetter,
      simBleDevice: simBleDevice,
      simScannerFactory: () {
        _network ??= simLanBackend.createScopedNetwork();
        return _network!.createScanner();
      },
    )..addListener(_notifyIfAlive);
  }

  final ProtocolInspectorController inspector;
  final DemoRunMode Function() _modeGetter;
  final RealTransportHelper realTransportHelper;

  late final SimThermalLanBackend simLanBackend;

  late final LanSetupController setup;
  late final SimulatedLanBleDevice simBleDevice;
  Network? _network;
  ConnectedDevice<dynamic>? _tcpDevice;
  CloudCancelToken? _printCancelToken;
  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _busy = false;
  bool get busy => _busy || setup.busy;
  String statusMessage = '就绪';

  List<DiscoveredCloudPrinter> get discoveredPrinters =>
      setup.discoveredPrinters;
  DiscoveredCloudPrinter? get selectedPrinter => setup.selectedPrinter;
  set selectedPrinter(DiscoveredCloudPrinter? value) =>
      setup.selectedPrinter = value;
  CloudJobProgress? printProgress;
  String? lastStreamResult;

  DemoRunMode get mode => _modeGetter();
  bool get isTcpConnected =>
      _tcpDevice != null &&
      _tcpDevice!.connectionState() == ConnectionState.connected;

  Future<void> connectTcpPrinter([DiscoveredCloudPrinter? target]) async {
    final printer = target ?? selectedPrinter;
    if (printer == null) {
      statusMessage = '请先发现并选择打印机';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在连接 TCP ${printer.host}:${printer.port}...', () async {
      await disconnectTcpPrinter();
      _network ??= mode == DemoRunMode.simulation
          ? simLanBackend.createScopedNetwork()
          : realTransportHelper.createRealNetwork();
      final device = await _network!.connect(
        printer.host,
        printer.port,
        networkInterface: printer.networkInterface,
      );
      if (_disposed) {
        await device.disconnect();
        return;
      }
      _tcpDevice = mode == DemoRunMode.simulation
          ? device
          : InspectedDevice(
              device,
              inspector,
              CloudPrinterFamily.thermalLanStream,
              'TCP',
            );
      selectedPrinter = printer;
      statusMessage = 'TCP 已连接：${printer.host}:${printer.port}';
    });
  }

  Future<void> streamTsplPrintJob({
    String text = 'PSDK Thermal LAN Demo',
    int copies = 1,
  }) async {
    final tcp = _tcpDevice;
    if (tcp == null || tcp.connectionState() != ConnectionState.connected) {
      statusMessage = '请先连接 TCP 9100 打印机';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在通过 TCP 9100 发送 TSPL 任务…', () async {
      final cancelToken = CloudCancelToken();
      _printCancelToken = cancelToken;
      final session = StreamJobSession(
        device: tcp,
        chunkSize: 128,
        cancelToken: cancelToken,
        onProgress: (p) {
          printProgress = p;
          _notifyIfAlive();
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
            message: 'TSPL 数据发送完成',
          ),
        );
        lastStreamResult =
            '已发送 ${session.bytesTransferred} B to ${selectedPrinter?.host ?? "printer"}:${selectedPrinter?.port ?? 9100}';
        statusMessage = lastStreamResult!;
      } on CloudCancelledException catch (e) {
        lastStreamResult = '发送已取消：${e.reason}';
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
    _notifyIfAlive();
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    if (_disposed) return;
    _busy = true;
    statusMessage = label;
    _notifyIfAlive();
    try {
      await action();
    } catch (e) {
      statusMessage = '操作失败：$e';
    } finally {
      _busy = false;
      _notifyIfAlive();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _printCancelToken?.cancel('Disposed');
    await disconnectTcpPrinter();
    _network?.dispose();
    await setup.dispose();
    super.dispose();
  }
}
