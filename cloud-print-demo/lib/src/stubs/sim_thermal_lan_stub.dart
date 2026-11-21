import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/protocol_inspector.dart';
import 'in_memory_io.dart';

/// Loopback BLE/Serial [ConnectedDevice] supporting both `psdk_fruit_wifi`
/// text dialects (`BluetoothAtWifiCommands` & `TsplWlanCommands`).
class SimThermalWifiDevice extends ConnectedDevice<String> {
  SimThermalWifiDevice({
    required this.inspector,
    this.printerIp = '192.168.1.77',
  });

  final ProtocolInspectorController inspector;
  final String printerIp;
  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  bool dhcpEnabled = true;
  String staticIp = '192.168.1.77';
  String subnetMask = '255.255.255.0';
  String gateway = '192.168.1.1';
  String staSsid = 'ThermalShop-5G';
  String staPassword = 'shop-secret-password';
  int wifiRole = 1; // 1=STA, 2=AP, 3=Shared
  String apSsid = 'ThermalPrinter_AP';
  String apPassword = 'ap-secret-password';
  String apIp = '192.168.1.1';
  bool staLinked = true;
  int _atPollCount = 0;

  @override
  String origin() => 'sim://thermal-wifi';

  @override
  String? deviceName() => 'SimThermal-WiFi-80';

  @override
  String? deviceMac() => 'AA:BB:CC:11:22:34';

  @override
  ConnectionState connectionState() => _state;

  @override
  Future<void> disconnect() async {
    _state = ConnectionState.disconnected;
    if (!_readController.isClosed) {
      await _readController.close();
    }
  }

  @override
  Stream<Uint8List> read(ReadOptions? options) => _readController.stream;

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {
    if (_state != ConnectionState.connected || data.isEmpty) return;
    final rawText = utf8.decode(data, allowMalformed: true);
    final lines = rawText
        .split(RegExp(r'\r\n|\n|\r'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    for (final line in lines) {
      final trimmed = line.trim();
      inspector.recordText(
        family: CloudPrinterFamily.thermalLanStream,
        transport: trimmed.startsWith('BLUETOOTH') ? 'BLE AT' : 'TSPL WLAN',
        direction: WireDirection.tx,
        text: trimmed,
        decodedSummary: ProtocolInspectorController.redactSecrets(trimmed),
      );
      _processLine(trimmed);
    }
  }

  void _processLine(String line) {
    final upper = line.toUpperCase();
    if (upper.startsWith('BLUETOOTH SETSSID,')) {
      final payload = line.substring('BLUETOOTH SETSSID,'.length);
      final comma = payload.indexOf(',');
      if (comma >= 0) {
        staSsid = payload.substring(0, comma).trim();
        staPassword = payload.substring(comma + 1).trim();
      } else {
        staSsid = payload.trim();
        staPassword = '';
      }
      _atPollCount = 0;
      staLinked = false;
      _emitChunked('OK\r\n', 'BLE AT', 'AT SETSSID ACK: OK');
      return;
    }
    if (upper == 'BLUETOOTH GETSSID') {
      _emitChunked('$staSsid\r\n', 'BLE AT', 'AT GETSSID -> $staSsid');
      return;
    }
    if (upper == 'BLUETOOTH GETPASSWORD') {
      _emitChunked(
        '$staPassword\r\n',
        'BLE AT',
        'AT GETPASSWORD -> [REDACTED]',
        redactRxText: '[REDACTED]\r\n',
      );
      return;
    }
    if (upper == 'BLUETOOTH GETLINKSTATE') {
      _atPollCount++;
      if (!staLinked && _atPollCount >= 2) {
        staLinked = true;
      }
      final reply = staLinked
          ? 'GETLINKSTATE:Connected,$printerIp\r\n'
          : 'GETLINKSTATE:Disconnected\r\n';
      _emitChunked(
        reply,
        'BLE AT',
        'AT GETLINKSTATE -> ${reply.trim()}',
        chunkSize: 8,
      );
      return;
    }

    // TSPL WLAN / DIAGNOSTIC dialect
    if (upper == 'WLAN DHCP') {
      dhcpEnabled = true;
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN DHCP -> OK');
      return;
    }
    if (upper.startsWith('WLAN IP ')) {
      final matches = RegExp(r'"([^"]*)"').allMatches(line).toList();
      if (matches.length >= 3) {
        dhcpEnabled = false;
        staticIp = matches[0].group(1)!;
        subnetMask = matches[1].group(1)!;
        gateway = matches[2].group(1)!;
      }
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN IP -> OK ($staticIp)');
      return;
    }
    if (upper.startsWith('WLAN SSID ')) {
      final m = RegExp(r'"([^"]*)"').firstMatch(line);
      if (m != null) staSsid = m.group(1)!;
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN SSID -> OK');
      return;
    }
    if (upper.startsWith('WLAN PWD ')) {
      final m = RegExp(r'"([^"]*)"').firstMatch(line);
      if (m != null) staPassword = m.group(1)!;
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN PWD -> OK');
      return;
    }
    if (upper.startsWith('WLAN ROLE ')) {
      wifiRole = int.tryParse(line.split(' ').last.trim()) ?? wifiRole;
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN ROLE=$wifiRole -> OK');
      return;
    }
    if (upper.startsWith('WLAN LAP ')) {
      final args = line
          .substring('WLAN LAP '.length)
          .split(',')
          .map((e) => e.trim())
          .toList();
      if (args.length >= 3) {
        apSsid = args[0];
        apPassword = args[1];
        apIp = args[2];
      } else if (args.length == 2) {
        apSsid = args[0];
        apPassword = '';
        apIp = args[1];
      }
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN LAP -> OK');
      return;
    }
    if (upper == 'WLAN DEFAULT') {
      dhcpEnabled = true;
      wifiRole = 1;
      staSsid = 'ThermalShop-5G';
      staPassword = 'shop-secret-password';
      _emitChunked('OK\r\n', 'TSPL WLAN', 'WLAN DEFAULT -> OK');
      return;
    }
    if (upper.startsWith('DIAGNOSTIC REPORT ')) {
      final key = upper.substring('DIAGNOSTIC REPORT '.length).trim();
      switch (key) {
        case 'WIFIDHCP':
          _emitChunked(
            '${dhcpEnabled ? "ON" : "OFF"}\r\n',
            'TSPL WLAN',
            'DIAGNOSTIC WIFIDHCP',
          );
          break;
        case 'WIFIIP':
          _emitChunked('$staticIp\r\n', 'TSPL WLAN', 'DIAGNOSTIC WIFIIP');
          break;
        case 'WIFIMASK':
          _emitChunked('$subnetMask\r\n', 'TSPL WLAN', 'DIAGNOSTIC WIFIMASK');
          break;
        case 'WIFIGATEWAY':
          _emitChunked('$gateway\r\n', 'TSPL WLAN', 'DIAGNOSTIC WIFIGATEWAY');
          break;
        case 'WIFISSID':
          _emitChunked('$staSsid\r\n', 'TSPL WLAN', 'DIAGNOSTIC WIFISSID');
          break;
        case 'WIFIPWD':
          _emitChunked(
            '$staPassword\r\n',
            'TSPL WLAN',
            'DIAGNOSTIC WIFIPWD -> [REDACTED]',
            redactRxText: '[REDACTED]\r\n',
          );
          break;
        case 'WIFIROLE':
          _emitChunked('$wifiRole\r\n', 'TSPL WLAN', 'DIAGNOSTIC WIFIROLE');
          break;
        case 'APSSID':
          _emitChunked('$apSsid\r\n', 'TSPL WLAN', 'DIAGNOSTIC APSSID');
          break;
        case 'APPASSWORD':
          _emitChunked(
            '$apPassword\r\n',
            'TSPL WLAN',
            'DIAGNOSTIC APPASSWORD -> [REDACTED]',
            redactRxText: '[REDACTED]\r\n',
          );
          break;
        default:
          final info =
              'SSID:$staSsid,IP:$staticIp,DHCP:${dhcpEnabled ? "ON" : "OFF"},ROLE:$wifiRole\r\n';
          _emitChunked(info, 'TSPL WLAN', 'DIAGNOSTIC $key -> ${info.trim()}');
          break;
      }
    }
  }

  void _emitChunked(
    String rawText,
    String transport,
    String summary, {
    String? redactRxText,
    int chunkSize = 0,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(rawText));
    final logText = redactRxText ?? rawText;
    inspector.record(
      family: CloudPrinterFamily.thermalLanStream,
      transport: transport,
      direction: WireDirection.rx,
      rawBytes: Uint8List.fromList(utf8.encode(logText)),
      decodedSummary: summary,
      textPreview: logText.trimRight(),
    );
    scheduleMicrotask(() {
      if (_readController.isClosed || _state != ConnectionState.connected) {
        return;
      }
      if (chunkSize <= 0 || bytes.length <= chunkSize) {
        _readController.add(bytes);
      } else {
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length)
              ? i + chunkSize
              : bytes.length;
          _readController.add(Uint8List.sublistView(bytes, i, end));
        }
      }
    });
  }
}

/// In-memory UDP 22368 discovery + TCP :9100 loopback backend wired into
/// `Network.scoped(...)` for `CloudPrinterFamily.thermalLanStream`.
class SimThermalLanBackend {
  SimThermalLanBackend({required this.inspector, required this.wifiDevice});

  final ProtocolInspectorController inspector;
  final SimThermalWifiDevice wifiDevice;

  final List<Uint8List> capturedTcpJobs = <Uint8List>[];
  int totalTcpBytesReceived = 0;

  Network createScopedNetwork() {
    return Network.scoped(
      udp22368BindPort: 0,
      udp22368TargetPort: 22368,
      broadcastAddressesOverride: const <String>['127.0.0.1'],
      allowLoopbackResponses: true,
      localIpv4Provider: () async => const <LocalIpv4Interface>[
        LocalIpv4Interface(name: 'sim0', address: '192.168.1.50'),
      ],
      udpSocketBinder: _bindSimUdpSocket,
      tcpSocketConnector: _connectSimTcpSocket,
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
  }

  Future<RawDatagramSocket> _bindSimUdpSocket(
    InternetAddress address,
    int port, {
    bool reuseAddress = true,
    String? networkInterface,
  }) async {
    return InMemoryRawDatagramSocket(
      address: InternetAddress.loopbackIPv4,
      port: 22369,
      onSend: (data, target, targetPort, sock) {
        final query = utf8.decode(data, allowMalformed: true).trim();
        inspector.recordText(
          family: CloudPrinterFamily.thermalLanStream,
          transport: 'UDP $targetPort',
          direction: WireDirection.tx,
          text: query,
          decodedSummary: 'UDP $targetPort probe: $query',
        );
        if (targetPort == DiagnosticNetBroadcastParser.printerPort &&
            query == 'DIAGNOSTIC REPORT NETBROADCAST') {
          final rawReply =
              'NET BROADCAST,'
              'MODEL:Thermal-WiFi-80,'
              'SOFT:2.1.0,'
              'WLAN DHCP:${wifiDevice.dhcpEnabled ? "ON" : "OFF"},'
              'WLAN IP:${wifiDevice.staticIp},'
              'WLAN SUBNET:${wifiDevice.subnetMask},'
              'WLAN GATEWAY:${wifiDevice.gateway},'
              'WLAN MAC:AA:BB:CC:11:22:33,'
              'WIFI NAME:${wifiDevice.staSsid},'
              'WIFI PASSWORD:${wifiDevice.staPassword},'
              'WIFI DHCP:${wifiDevice.dhcpEnabled ? "ON" : "OFF"},'
              'WIFI IP:${wifiDevice.staticIp},'
              'WIFI MAC:AA:BB:CC:11:22:34,'
              'BATTERY LEVEL:92%,'
              'SORKET STATUS:IDLE\r\n';
          final replyBytes = Uint8List.fromList(utf8.encode(rawReply));
          inspector.recordText(
            family: CloudPrinterFamily.thermalLanStream,
            transport: 'UDP 22368',
            direction: WireDirection.rx,
            text: rawReply,
            decodedSummary:
                'UDP 22368 NET BROADCAST (${wifiDevice.staticIp}, password redacted)',
          );
          scheduleMicrotask(() {
            sock.enqueueDatagram(
              Datagram(
                replyBytes,
                InternetAddress.loopbackIPv4,
                DiagnosticNetBroadcastParser.printerPort,
              ),
            );
          });
        }
      },
    );
  }

  Future<Socket> _connectSimTcpSocket(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
    String? networkInterface,
  }) async {
    final buffer = BytesBuilder(copy: false);
    late final InMemorySocket sock;
    sock = InMemorySocket(
      address: InternetAddress.loopbackIPv4,
      port: 51000,
      remoteAddress:
          InternetAddress.tryParse(host) ?? InternetAddress.loopbackIPv4,
      remotePort: port,
      onWrite: (bytes) {
        buffer.add(bytes);
        totalTcpBytesReceived += bytes.length;
        final preview = utf8.decode(bytes, allowMalformed: true);
        inspector.record(
          family: CloudPrinterFamily.thermalLanStream,
          transport: 'TCP :$port',
          direction: WireDirection.tx,
          rawBytes: bytes,
          decodedSummary: 'TCP :$port stream chunk (${bytes.length} B)',
          textPreview: preview.length > 240
              ? '${preview.substring(0, 240)}...'
              : preview,
        );
        if (preview.contains('PRINT ')) {
          final ack = Uint8List.fromList(utf8.encode('PRINTED\r\n'));
          inspector.recordText(
            family: CloudPrinterFamily.thermalLanStream,
            transport: 'TCP :$port',
            direction: WireDirection.rx,
            text: 'PRINTED\r\n',
            decodedSummary: 'TCP :$port ACK -> PRINTED',
          );
          scheduleMicrotask(() => sock.pushIncoming(ack));
        }
      },
      onClose: () async {
        final taken = buffer.takeBytes();
        if (taken.isNotEmpty) {
          capturedTcpJobs.add(taken);
        }
      },
    );
    return sock;
  }
}
