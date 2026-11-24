import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';

import 'package:cloud_print_demo/src/models/protocol_inspector.dart';

/// Loopback BLE GATT `0x180A/0xFF00` [ConnectedDevice] handling `psdk_fruit_inkjet`
/// `ACL` frames (`cmd=23` query & `cmd=24` `187B` Wi-Fi config + `16B` ACK).
class SimulatedInkjetBleDevice extends ConnectedDevice<Object> {
  SimulatedInkjetBleDevice({required this.inspector});

  final ProtocolInspectorController inspector;
  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  bool rejectNextProvision = false;
  int simulatedMtu = 512;
  Uint8List? lastAckFrame;
  String lastProvisionedSsid = '';
  String lastProvisionedPassword = '';
  String sapSsid = 'H100-SIM-AP';
  String sapPassword = '12345678';
  String sapIpv4 = '192.168.4.1,255.255.255.0,192.168.4.1';
  final List<int> _aclRxBuf = <int>[];

  @override
  Object origin() => 'sim://inkjet-ble-acl';

  @override
  String? deviceName() => 'SimColorJet-Pro-BLE';

  @override
  String? deviceMac() => '00:11:22:33:44:55';

  @override
  ConnectionState connectionState() => _state;

  @override
  Future<void> disconnect() async {
    _state = ConnectionState.disconnected;
    _aclRxBuf.clear();
    if (!_readController.isClosed) {
      await _readController.close();
    }
  }

  @override
  Stream<Uint8List> read(ReadOptions? options) => _readController.stream;

  InkjetBleGattHooks buildGattHooks() {
    return InkjetBleGattHooks(
      requestMtu: (_) async => simulatedMtu,
      enableNotifications: (_, _) async {},
      readCharacteristic: (_, _) async => lastAckFrame,
      stopScan: () async {},
    );
  }

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {
    if (_state != ConnectionState.connected || data.isEmpty) return;

    _aclRxBuf.addAll(data);
    while (_aclRxBuf.isNotEmpty) {
      // Wait for at least the 34B PJL ACL prefix + 16B ACL header = 50B.
      if (_aclRxBuf.length < 50) {
        return;
      }

      final hasAclHeader = _aclRxBuf[34] == 0xAC && _aclRxBuf[35] == 0x00;
      if (!hasAclHeader) {
        final rawText = utf8.decode(_aclRxBuf, allowMalformed: true);
        if (rawText.contains('@PJL ENTER LANGUAGE=XSL')) {
          final secondUel = rawText.indexOf(XslCodec.uel, XslCodec.uel.length);
          if (secondUel < 0) {
            return;
          }
          _aclRxBuf.clear();
          _handleBleXslSapQuery(rawText);
          return;
        }
        // Non-ACL fallback: consume and avoid logging raw credential tails.
        final frame = Uint8List.fromList(_aclRxBuf);
        _aclRxBuf.clear();
        _handleAclFrame(frame, cmd: 0);
        return;
      }

      final cmd = _aclRxBuf[36] | (_aclRxBuf[37] << 8);
      final payloadLen = _aclRxBuf[38] | (_aclRxBuf[39] << 8);
      // 34B prefix + 16B ACL header + payloadLen + 9B UEL = 59 + payloadLen.
      final expectedTotal = 59 + payloadLen;
      if (_aclRxBuf.length < expectedTotal) {
        // Wait for remaining BLE write chunks before parsing/logging.
        return;
      }

      final frame = Uint8List.fromList(_aclRxBuf.sublist(0, expectedTotal));
      _aclRxBuf.removeRange(0, expectedTotal);
      _handleAclFrame(frame, cmd: cmd);
    }
  }

  void _handleAclFrame(Uint8List frame, {required int cmd}) {
    if (cmd == InkjetAclCodec.commandWifiConfig && frame.length >= 178) {
      lastProvisionedSsid = _decodeFixedCString(frame, 50, 64);
      lastProvisionedPassword = _decodeFixedCString(frame, 114, 64);
      inspector.record(
        family: CloudPrinterFamily.colorInkjetPjl,
        transport: 'BLE 0x180A ACL',
        direction: WireDirection.tx,
        rawBytes: frame.sublist(0, 50),
        decodedSummary:
            'ACL cmd=24 (${frame.length} B): ssid="$lastProvisionedSsid", password=[REDACTED]',
      );
    } else if (cmd == InkjetAclCodec.commandWifiConfig) {
      inspector.record(
        family: CloudPrinterFamily.colorInkjetPjl,
        transport: 'BLE 0x180A ACL',
        direction: WireDirection.tx,
        rawBytes: frame.sublist(0, frame.length.clamp(0, 50)),
        decodedSummary: 'ACL cmd=24 (${frame.length} B): [REDACTED]',
      );
    } else {
      inspector.record(
        family: CloudPrinterFamily.colorInkjetPjl,
        transport: 'BLE 0x180A ACL',
        direction: WireDirection.tx,
        rawBytes: frame,
        decodedSummary: 'ACL cmd=$cmd (${frame.length} B)',
      );
    }

    final ok = !rejectNextProvision;
    final ack = Uint8List(InkjetAclCodec.responseFrameLength);
    final view = ByteData.sublistView(ack);
    view.setUint16(0, InkjetAclCodec.aclMagic, Endian.little);
    view.setUint16(2, cmd, Endian.little);
    view.setUint16(4, 1, Endian.little);
    ack[6] = ok ? 1 : 0;
    lastAckFrame = ack;

    inspector.record(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'BLE 0x180A ACL',
      direction: WireDirection.rx,
      rawBytes: ack,
      decodedSummary: 'ACL cmd=$cmd ACK (status=${ok ? "OK(1)" : "REJECT(0)"})',
    );

    scheduleMicrotask(() {
      if (!_readController.isClosed && _state == ConnectionState.connected) {
        _readController.add(ack);
      }
    });
  }

  void _handleBleXslSapQuery(String queryText) {
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'BLE 0x180A XSL',
      direction: WireDirection.tx,
      text: queryText,
      decodedSummary: 'BLE XSL SoftAP Query',
    );
    final triple = sapIpv4.split(',');
    final ip = triple.isNotEmpty ? triple[0] : '192.168.4.1';
    final mask = triple.length > 1 ? triple[1] : '255.255.255.0';
    final gw = triple.length > 2 ? triple[2] : ip;
    final reply =
        '${XslCodec.uel}'
        '@PJL WIFI SAP ENABLE=ON\r\n'
        '@PJL WIFI SAP CFG="$sapSsid","$sapPassword"\r\n'
        '@PJL WIFI SAP IPV4="$ip","$mask","$gw"\r\n'
        '@PJL XQUERY OK\r\n'
        '${XslCodec.uel}';
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'BLE 0x180A XSL',
      direction: WireDirection.rx,
      text: reply,
      decodedSummary: 'BLE XSL SoftAP Reply: ssid="$sapSsid"',
    );
    final bytes = Uint8List.fromList(utf8.encode(reply));
    scheduleMicrotask(() {
      if (!_readController.isClosed && _state == ConnectionState.connected) {
        _readController.add(bytes);
      }
    });
  }

  String _decodeFixedCString(Uint8List data, int offset, int maxLen) {
    var end = offset;
    final limit = (offset + maxLen).clamp(offset, data.length);
    while (end < limit && data[end] != 0) {
      end++;
    }
    if (end <= offset) return '';
    return utf8.decode(Uint8List.sublistView(data, offset, end));
  }
}

class SimulatedInkjetMdnsBrowser {
  SimulatedInkjetMdnsBrowser({required this.inspector});

  final ProtocolInspectorController inspector;

  Stream<InkjetMdnsEndpoint> browse(
    String serviceType, {
    String? networkInterface,
  }) async* {
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'mDNS',
      direction: WireDirection.tx,
      text: 'mDNS browse $serviceType',
      decodedSummary: 'mDNS browse $serviceType',
    );
    const endpoint = InkjetMdnsEndpoint(
      serviceName: 'SimColorJet-Pro._printer._tcp',
      host: '192.168.1.92',
      port: 9100,
      macAddress: '00:11:22:33:44:55',
      networkInterface: 'sim0',
      txtRecords: <String, String>{
        'product': 'SimColorJet-Pro',
        'sn': 'CJ-SIM-2026001',
        'wifi_pwd': 'hidden-secret',
      },
    );
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'mDNS',
      direction: WireDirection.rx,
      text: 'Found ${endpoint.serviceName} @ ${endpoint.host}:${endpoint.port}',
      decodedSummary: 'mDNS resolved ${endpoint.host}:${endpoint.port}',
    );
    yield endpoint;
  }
}

class SimulatedInkjetSoftApProbe {
  SimulatedInkjetSoftApProbe({
    required this.inspector,
    required this.tcpDevice,
  });

  final ProtocolInspectorController inspector;
  final SimulatedInkjetTcpDevice tcpDevice;

  Future<String> call(
    String host,
    int port,
    Uint8List queryFrame,
    Duration timeout,
    String? networkInterface,
  ) async {
    final queryPayload = utf8.decode(queryFrame, allowMalformed: true);
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'SoftAP :$port',
      direction: WireDirection.tx,
      text: queryPayload,
      decodedSummary: 'SoftAP XQUERY -> $host:$port',
    );
    final reply = tcpDevice.buildXslQueryResponse(queryPayload);
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'SoftAP :$port',
      direction: WireDirection.rx,
      text: reply,
      decodedSummary: 'SoftAP XQUERY reply (${reply.length} chars)',
    );
    return reply;
  }
}

class SimulatedInkjetNetworkBinder implements InkjetNetworkBinder {
  SimulatedInkjetNetworkBinder(this.tcpDevice);

  final SimulatedInkjetTcpDevice tcpDevice;

  @override
  Future<String?> resolveWifiInterfaceName() async => 'sim0';

  @override
  Future<Socket> connectTcp(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 4),
    String? networkInterface,
  }) {
    throw UnsupportedError(
      'Simulation mode uses connectDevice directly without raw OS sockets',
    );
  }

  @override
  Future<ConnectedDevice<dynamic>> connectDevice(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 4),
    String? networkInterface,
  }) async {
    return tcpDevice;
  }
}

/// Stateful `XSL` + `XPL` loopback [ConnectedDevice] for `psdk_fruit_inkjet`.
class SimulatedInkjetTcpDevice extends ConnectedDevice<Object> {
  SimulatedInkjetTcpDevice({
    required this.inspector,
    this.model = 'SimColorJet-Pro',
    this.serialNumber = 'CJ-SIM-2026001',
    this.printerName = 'ColorJet Office Demo',
    this.firmwareVersion = '1.7.0',
  });

  final ProtocolInspectorController inspector;
  final String model;
  final String serialNumber;
  final String printerName;
  final String firmwareVersion;

  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  InkjetDeviceRunStatus runStatus = InkjetDeviceRunStatus.ready;
  InkjetFaultCode faultCode = InkjetFaultCode.noError;

  InkjetInkState cyanState = InkjetInkState.normal;
  int cyanPercent = 85;
  InkjetInkState magentaState = InkjetInkState.normal;
  int magentaPercent = 80;
  InkjetInkState yellowState = InkjetInkState.normal;
  int yellowPercent = 75;
  InkjetInkState blackState = InkjetInkState.normal;
  int blackPercent = 90;

  InkjetBatteryState batteryState = InkjetBatteryState.charge;
  int batteryPercent = 94;

  bool staEnabled = true;
  bool staLinked = true;
  String staSsid = 'InkjetLab-WiFi';
  String staPassword = 'lab-secret-password';
  String staIpv4 = '192.168.1.92,255.255.255.0,192.168.1.1';

  bool sapEnabled = true;
  String sapSsid = 'ColorJet_AP';
  String sapPassword = 'ap-secret-password';
  String sapIpv4 = '192.168.4.1,255.255.255.0,192.168.4.1';

  bool powerSave = true;
  int sleepMinutes = 15;
  InkjetLanguageCode language = InkjetLanguageCode.english;
  int printedTimes = 42;
  InkjetWetScheduleHours lastWetHours = InkjetWetScheduleHours.disabled;
  InkjetMaintenanceAction? lastMaintenanceAction;
  InkjetBuiltInPage? lastBuiltInPage;

  bool pushActive = false;
  bool _inXplMode = false;
  final List<int> _xplBuf = <int>[];
  final StringBuffer _xslRxAccum = StringBuffer();
  int capturedXplBands = 0;
  int capturedXplPages = 0;
  int capturedXplJobs = 0;
  int lastXplTotalBytes = 0;

  void applyInkPreset({
    required InkjetFaultCode fault,
    required InkjetDeviceRunStatus status,
    required int c,
    required InkjetInkState cState,
    required int m,
    required InkjetInkState mState,
    required int y,
    required InkjetInkState yState,
    required int k,
    required InkjetInkState kState,
  }) {
    faultCode = fault;
    runStatus = status;
    cyanPercent = c;
    cyanState = cState;
    magentaPercent = m;
    magentaState = mState;
    yellowPercent = y;
    yellowState = yState;
    blackPercent = k;
    blackState = kState;
    if (pushActive) {
      _emitPushLines(<String>[
        '@PJL DEVICE STATUS=${runStatus.wireToken},CODE=${faultCode.code}\r\n',
        '@PJL CONSUMABLE STATUS=${_formatConsumables()}\r\n',
      ]);
    }
  }

  @override
  Object origin() => 'sim://inkjet-tcp';

  @override
  String? deviceName() => printerName;

  @override
  String? deviceMac() => '00:11:22:33:44:55';

  @override
  ConnectionState connectionState() => _state;

  @override
  Future<void> disconnect() async {
    _state = ConnectionState.disconnected;
    _inXplMode = false;
    _xplBuf.clear();
    _xslRxAccum.clear();
    if (!_readController.isClosed) {
      await _readController.close();
    }
  }

  @override
  Stream<Uint8List> read(ReadOptions? options) => _readController.stream;

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {
    if (_state != ConnectionState.connected || data.isEmpty) return;

    final asText = utf8.decode(data, allowMalformed: true);
    if (_inXplMode &&
        (asText.contains('@PJL ENTER LANGUAGE=XSL') ||
            asText.contains('@PJL ENTER LANGUAGE=XPL'))) {
      _inXplMode = false;
      _xplBuf.clear();
      _xslRxAccum.clear();
      if (asText.contains('@PJL ENTER LANGUAGE=XSL') &&
          !asText.startsWith(XslCodec.uel)) {
        final enterIdx = asText.indexOf('@PJL ENTER LANGUAGE=XSL');
        if (!asText.substring(0, enterIdx).contains(XslCodec.uel)) {
          _xslRxAccum.write(XslCodec.uel);
        }
      }
    }

    if (!_inXplMode) {
      if (asText.contains('LANGUAGE=XPL')) {
        _inXplMode = true;
      } else if (asText.contains('LANGUAGE=XSL') || _xslRxAccum.isNotEmpty) {
        _xslRxAccum.write(asText);
        final full = _xslRxAccum.toString();
        final secondUel = full.indexOf(XslCodec.uel, XslCodec.uel.length);
        if (secondUel >= 0) {
          final frame = full.substring(0, secondUel + XslCodec.uel.length);
          _xslRxAccum.clear();
          if (secondUel + XslCodec.uel.length < full.length) {
            _xslRxAccum.write(full.substring(secondUel + XslCodec.uel.length));
          }
          _handleXslFrame(frame);
        }
        return;
      }
    }

    // XPL binary stream parser
    lastXplTotalBytes += data.length;
    _xplBuf.addAll(data);
    _drainXplBuffer();
  }

  void _handleXslFrame(String frame) {
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'TCP :9100 XSL',
      direction: WireDirection.tx,
      text: frame.replaceAll('\x1b%-12345X', '<UEL>'),
      decodedSummary: _summarizeXslTx(frame),
    );

    if (frame.contains('@PJL XQUERY START')) {
      final reply = buildXslQueryResponse(frame);
      inspector.recordText(
        family: CloudPrinterFamily.colorInkjetPjl,
        transport: 'TCP :9100 XSL',
        direction: WireDirection.rx,
        text: reply.replaceAll('\x1b%-12345X', '<UEL>'),
        decodedSummary: 'XQUERY OK',
      );
      _emitTextChunked(reply, chunkSize: 48);
      return;
    }

    if (frame.contains('@PJL XSET START')) {
      _applyXsetCommands(frame);
      const reply =
          '${XslCodec.uel}${XslCodec.pjlEnterXsl}@PJL XSET OK\r\n${XslCodec.uel}';
      inspector.recordText(
        family: CloudPrinterFamily.colorInkjetPjl,
        transport: 'TCP :9100 XSL',
        direction: WireDirection.rx,
        text: reply.replaceAll('\x1b%-12345X', '<UEL>'),
        decodedSummary: 'XSET OK',
      );
      _emitTextChunked(reply);
      return;
    }

    if (frame.contains('@PJL DEVICE STATUS=ON')) {
      pushActive = true;
      _emitPushLines(<String>[
        '@PJL DEVICE STATUS=${runStatus.wireToken},CODE=${faultCode.code}\r\n',
        '@PJL CONSUMABLE STATUS=${_formatConsumables()}\r\n',
        '@PJL BATTERY STATUS=${batteryState.wireToken},PERCENT=$batteryPercent\r\n',
      ]);
      return;
    }

    if (frame.contains('@PJL DEVICE STATUS=OFF')) {
      pushActive = false;
    }
  }

  String _summarizeXslTx(String frame) {
    if (frame.contains('@PJL XQUERY START')) return 'XSL XQUERY';
    if (frame.contains('@PJL XSET START')) {
      if (frame.contains('NOZZLE WET=')) {
        final m = RegExp(r'NOZZLE WET=(\d+)').firstMatch(frame);
        return 'XSL XSET NOZZLE WET=${m?.group(1) ?? "?"}h';
      }
      if (frame.contains('NOZZLE ')) {
        final m = RegExp(r'@PJL (NOZZLE [A-Z ]+)').firstMatch(frame);
        return 'XSL XSET ${m?.group(1)?.trim() ?? "NOZZLE"}';
      }
      if (frame.contains('PRINT ')) {
        final m = RegExp(r'@PJL (PRINT [A-Z ]+)').firstMatch(frame);
        return 'XSL XSET ${m?.group(1)?.trim() ?? "PRINT"}';
      }
      if (frame.contains('FACTORY RESTORE')) {
        return 'XSL XSET FACTORY RESTORE';
      }
      return 'XSL XSET';
    }
    if (frame.contains('@PJL DEVICE STATUS=ON')) return 'XSL Active Push ON';
    if (frame.contains('@PJL DEVICE STATUS=OFF')) return 'XSL Active Push OFF';
    return 'XSL Frame';
  }

  String buildXslQueryResponse(String queryFrame) {
    final buf = StringBuffer()
      ..write(XslCodec.uel)
      ..write(XslCodec.pjlEnterXsl)
      ..write('@PJL XQUERY START\r\n');

    final lines = queryFrame.split(RegExp(r'\r\n|\n|\r'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      final upper = line.toUpperCase();
      if (!upper.startsWith('@PJL ') || !upper.endsWith('=?')) continue;
      final key = upper.substring(5, upper.length - 2).trim();
      switch (key) {
        case 'PRODUCT MODEL':
          buf.write('@PJL PRODUCT MODEL="$model"\r\n');
          break;
        case 'SERIAL NUMBER':
          buf.write('@PJL SERIAL NUMBER="$serialNumber"\r\n');
          break;
        case 'PRINTER NAME':
          buf.write('@PJL PRINTER NAME="$printerName"\r\n');
          break;
        case 'FIRMWARE VERSION':
          buf.write('@PJL FIRMWARE VERSION="$firmwareVersion"\r\n');
          break;
        case 'PRINTED TIMES':
          buf.write('@PJL PRINTED TIMES=$printedTimes\r\n');
          break;
        case 'STATUS UPDATE':
          buf.write(
            '@PJL DEVICE STATUS=${runStatus.wireToken},CODE=${faultCode.code}\r\n',
          );
          break;
        case 'CONSUMABLE INFO':
          buf.write('@PJL CONSUMABLE INFO=${_formatConsumables()}\r\n');
          break;
        case 'BATTERY STATUS':
          buf.write(
            '@PJL BATTERY STATUS=${batteryState.wireToken},PERCENT=$batteryPercent\r\n',
          );
          break;
        case 'WIFI STA ENABLE':
          buf.write('@PJL WIFI STA ENABLE=${staEnabled ? "ON" : "OFF"}\r\n');
          break;
        case 'WIFI STA LINKED':
          buf.write('@PJL WIFI STA LINKED=${staLinked ? "ON" : "OFF"}\r\n');
          break;
        case 'WIFI STA CFG':
          buf.write('@PJL WIFI STA CFG="$staSsid","$staPassword"\r\n');
          break;
        case 'WIFI STA IPV4':
          buf.write('@PJL WIFI STA IPV4=$staIpv4\r\n');
          break;
        case 'WIFI SAP ENABLE':
          buf.write('@PJL WIFI SAP ENABLE=${sapEnabled ? "ON" : "OFF"}\r\n');
          break;
        case 'WIFI SAP CFG':
          buf.write('@PJL WIFI SAP CFG="$sapSsid","$sapPassword"\r\n');
          break;
        case 'WIFI SAP IPV4':
          buf.write('@PJL WIFI SAP IPV4=$sapIpv4\r\n');
          break;
        case 'BLE DEVICE ENABLE':
          buf.write('@PJL BLE DEVICE ENABLE=ON\r\n');
          break;
        case 'BLE DEVICE NAME':
          buf.write('@PJL BLE DEVICE NAME="$model-BLE"\r\n');
          break;
        case 'POWER SAVE':
          buf.write('@PJL POWER SAVE=${powerSave ? "ON" : "OFF"}\r\n');
          break;
        case 'POWER SLEEP':
          buf.write('@PJL POWER SLEEP=$sleepMinutes\r\n');
          break;
        case 'LANGUAGE CODE':
          buf.write('@PJL LANGUAGE CODE=${language.wireToken}\r\n');
          break;
      }
    }

    buf
      ..write('@PJL XQUERY OK\r\n')
      ..write('@PJL XQUERY END\r\n')
      ..write(XslCodec.uel);
    return buf.toString();
  }

  String _formatConsumables() {
    return '[C=${cyanState.wireToken},PERCENT=$cyanPercent]'
        '[M=${magentaState.wireToken},PERCENT=$magentaPercent]'
        '[Y=${yellowState.wireToken},PERCENT=$yellowPercent]'
        '[K=${blackState.wireToken},PERCENT=$blackPercent]'
        '[CAP=CMYK]';
  }

  void _applyXsetCommands(String frame) {
    final lines = frame.split(RegExp(r'\r\n|\n|\r'));
    for (final raw in lines) {
      final line = raw.trim();
      final upper = line.toUpperCase();
      if (upper == '@PJL NOZZLE CLEAN') {
        lastMaintenanceAction = InkjetMaintenanceAction.nozzleClean;
      } else if (upper == '@PJL NOZZLE DEEP CLEAN') {
        lastMaintenanceAction = InkjetMaintenanceAction.nozzleDeepClean;
      } else if (upper == '@PJL NOZZLE TEST') {
        lastMaintenanceAction = InkjetMaintenanceAction.nozzleTest;
        printedTimes++;
      } else if (upper == '@PJL NOZZLE ADJUST') {
        lastMaintenanceAction = InkjetMaintenanceAction.nozzleAdjust;
      } else if (upper == '@PJL FACTORY RESTORE') {
        lastMaintenanceAction = InkjetMaintenanceAction.factoryRestore;
        powerSave = true;
        sleepMinutes = 15;
        language = InkjetLanguageCode.english;
      } else if (upper.startsWith('@PJL NOZZLE WET=')) {
        final h = int.tryParse(upper.split('=').last.trim()) ?? 0;
        for (final v in InkjetWetScheduleHours.values) {
          if (v.hours == h) {
            lastWetHours = v;
            break;
          }
        }
      } else if (upper == '@PJL PRINT DEMO') {
        lastBuiltInPage = InkjetBuiltInPage.demo;
        printedTimes++;
      } else if (upper == '@PJL PRINT PRINTER INFO') {
        lastBuiltInPage = InkjetBuiltInPage.printerInfo;
        printedTimes++;
      } else if (upper == '@PJL PRINT NETWORK INFO') {
        lastBuiltInPage = InkjetBuiltInPage.networkInfo;
        printedTimes++;
      } else if (upper.startsWith('@PJL WIFI STA CFG=')) {
        final matches = RegExp(r'"([^"]*)"').allMatches(line).toList();
        if (matches.length >= 2) {
          staSsid = matches[0].group(1)!;
          staPassword = matches[1].group(1)!;
        }
      } else if (upper.startsWith('@PJL WIFI STA ENABLE=')) {
        staEnabled = upper.endsWith('ON');
      } else if (upper.startsWith('@PJL WIFI STA IPV4=')) {
        final ip = line.split('=').last.trim();
        staIpv4 = '$ip,255.255.255.0,192.168.1.1';
      } else if (upper.startsWith('@PJL WIFI SAP CFG=')) {
        final matches = RegExp(r'"([^"]*)"').allMatches(line).toList();
        if (matches.length >= 2) {
          sapSsid = matches[0].group(1)!;
          sapPassword = matches[1].group(1)!;
        }
      } else if (upper.startsWith('@PJL WIFI SAP ENABLE=')) {
        sapEnabled = upper.endsWith('ON');
      } else if (upper.startsWith('@PJL POWER SAVE=')) {
        powerSave = upper.endsWith('ON');
      } else if (upper.startsWith('@PJL POWER SLEEP=')) {
        sleepMinutes =
            int.tryParse(line.split('=').last.trim()) ?? sleepMinutes;
      } else if (upper.startsWith('@PJL LANGUAGE CODE=')) {
        language =
            InkjetLanguageCode.fromWireToken(line.split('=').last.trim()) ??
            language;
      }
    }
  }

  void _drainXplBuffer() {
    while (_xplBuf.isNotEmpty) {
      // Check 34B XPL stream open (only when starting with ESC 0x1B)
      const openHeader = '\x1b%-12345X@PJL ENTER LANGUAGE=XPL\r\n';
      if (_xplBuf[0] == 0x1B) {
        if (_xplBuf.length < openHeader.length) break;
        final prefix = utf8.decode(
          _xplBuf.sublist(0, openHeader.length),
          allowMalformed: true,
        );
        if (prefix == openHeader) {
          final consumed = Uint8List.fromList(
            _xplBuf.sublist(0, openHeader.length),
          );
          _xplBuf.removeRange(0, openHeader.length);
          inspector.record(
            family: CloudPrinterFamily.colorInkjetPjl,
            transport: 'TCP :9100 XPL',
            direction: WireDirection.tx,
            rawBytes: consumed,
            decodedSummary: 'XPL Stream Open (34 B)',
          );
          if (pushActive) {
            _emitPushLines(<String>[
              '@PJL DEVICE STATUS=PRINT,CODE=0\r\n',
              '@PJL JOB STATUS=NORMAL,ID=1\r\n',
            ]);
          }
          continue;
        }
      }

      if (_xplBuf.length < 4) break;
      final b0 = _xplBuf[0];
      final b1 = _xplBuf[1];

      // 58 01 d4 00 -> 216B JobHeader
      if (b0 == 0x58 && b1 == 0x01) {
        if (_xplBuf.length < 216) break;
        final frame = Uint8List.fromList(_xplBuf.sublist(0, 216));
        _xplBuf.removeRange(0, 216);
        final view = ByteData.sublistView(frame, 4);
        final quality = frame[4 + 195];
        final copies = view.getUint32(198, Endian.little);
        final dpiX = view.getUint16(202, Endian.little);
        final dpiY = view.getUint16(204, Endian.little);
        final pages = view.getUint32(208, Endian.little);
        inspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XPL',
          direction: WireDirection.tx,
          rawBytes: frame,
          decodedSummary:
              'XPL JobHeader (216 B): ${dpiX}x${dpiY}dpi, quality=$quality, copies=$copies, pages=$pages',
        );
        continue;
      }

      // 58 02 18 00 -> 28B PageHeader
      if (b0 == 0x58 && b1 == 0x02) {
        if (_xplBuf.length < 28) break;
        final frame = Uint8List.fromList(_xplBuf.sublist(0, 28));
        _xplBuf.removeRange(0, 28);
        capturedXplPages++;
        final view = ByteData.sublistView(frame, 4);
        final pageId = view.getUint32(0, Endian.little);
        final paperCode = frame[4 + 4];
        final pageW = view.getUint16(5, Endian.little);
        final pageH = view.getUint16(7, Endian.little);
        final channels = frame[4 + 21];
        inspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XPL',
          direction: WireDirection.tx,
          rawBytes: frame,
          decodedSummary:
              'XPL PageHeader #$pageId (28 B): paper=$paperCode, ${pageW}x$pageH px, channels=$channels',
        );
        if (pushActive) {
          _emitPushLines(<String>[
            '@PJL PAGE STATUS=NORMAL,ID=$pageId,COPIES=1\r\n',
          ]);
        }
        continue;
      }

      // 58 03 12 00 -> 22B Band header + jbigLen
      if (b0 == 0x58 && b1 == 0x03) {
        if (_xplBuf.length < 22) break;
        final headerBytes = Uint8List.fromList(_xplBuf.sublist(0, 22));
        final view = ByteData.sublistView(headerBytes, 4);
        final topRow = view.getUint16(2, Endian.little);
        final rows = view.getUint16(6, Endian.little);
        final ch = headerBytes[4 + 9];
        final jbigLen = view.getUint32(14, Endian.little);
        final totalLen = 22 + jbigLen;
        if (_xplBuf.length < totalLen) break;
        final frame = Uint8List.fromList(_xplBuf.sublist(0, totalLen));
        _xplBuf.removeRange(0, totalLen);
        capturedXplBands++;
        // Log header + first few JBIG bytes for snappy inspector performance
        inspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XPL',
          direction: WireDirection.tx,
          rawBytes: frame.sublist(0, frame.length.clamp(0, 64)),
          decodedSummary:
              'XPL Band (row=$topRow, rows=$rows, ch=$ch, jbig=$jbigLen B)',
        );
        continue;
      }

      // 58 04 00 00 -> 4B PageEnd
      if (b0 == 0x58 && b1 == 0x04) {
        final frame = Uint8List.fromList(_xplBuf.sublist(0, 4));
        _xplBuf.removeRange(0, 4);
        inspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XPL',
          direction: WireDirection.tx,
          rawBytes: frame,
          decodedSummary: 'XPL PageEnd (58 04 00 00)',
        );
        if (pushActive) {
          _emitPushLines(<String>[
            '@PJL PAGE STATUS=DONE,ID=$capturedXplPages,COPIES=1\r\n',
          ]);
        }
        continue;
      }

      // 58 05 00 00 + 9B UEL -> 13B JobEnd
      if (b0 == 0x58 && b1 == 0x05) {
        if (_xplBuf.length < 13) break;
        final frame = Uint8List.fromList(_xplBuf.sublist(0, 13));
        _xplBuf.removeRange(0, 13);
        capturedXplJobs++;
        printedTimes++;
        _inXplMode = false;
        inspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XPL',
          direction: WireDirection.tx,
          rawBytes: frame,
          decodedSummary: 'XPL JobEnd (58 05 00 00 + UEL)',
        );
        if (pushActive) {
          _emitPushLines(<String>[
            '@PJL JOB STATUS=DONE,ID=1\r\n',
            '@PJL DEVICE STATUS=${runStatus.wireToken},CODE=${faultCode.code}\r\n',
          ]);
        }
        continue;
      }

      // Unknown sync byte: bail out of loop and keep buffer
      _inXplMode = false;
      _xplBuf.clear();
      break;
    }
  }

  void _emitPushLines(List<String> lines) {
    final joined = lines.join();
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'TCP :9100 Push',
      direction: WireDirection.rx,
      text: joined,
      decodedSummary: lines.map((e) => e.trim()).join(' | '),
    );
    _emitTextChunked(joined, chunkSize: 19);
  }

  void _emitTextChunked(String text, {int chunkSize = 0}) {
    final bytes = Uint8List.fromList(utf8.encode(text));
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
