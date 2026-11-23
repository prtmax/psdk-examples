import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/protocol_inspector.dart';

class _SimSublimationUdpSocket implements SublimationUdpSocket {
  _SimSublimationUdpSocket({required this.localPort, required this.transport});

  @override
  final int localPort;
  final SimulatedSublimationUdpTransport transport;
  final StreamController<SublimationUdpDatagram> _controller =
      StreamController<SublimationUdpDatagram>.broadcast();
  bool _closed = false;

  @override
  Stream<SublimationUdpDatagram> get datagrams => _controller.stream;

  @override
  Future<int> send(Uint8List data, String address, int port) async {
    if (_closed) return 0;
    transport._handleSend(data, address, port, this);
    return data.length;
  }

  void emitDatagram(Uint8List bytes, String sourceIp, int sourcePort) {
    if (_closed || _controller.isClosed) return;
    _controller.add(
      SublimationUdpDatagram(address: sourceIp, port: sourcePort, data: bytes),
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

/// Loopback [SublimationUdpTransport] handling UDP 22368 text discovery.
class SimulatedSublimationUdpTransport implements SublimationUdpTransport {
  SimulatedSublimationUdpTransport({
    required this.inspector,
    this.printerIp = '192.168.1.88',
    this.printerMac = '11:22:33:44:55:66',
    this.modelName = 'SubSim-D300',
  });

  final ProtocolInspectorController inspector;
  final String printerIp;
  final String printerMac;
  final String modelName;
  int _nextEphemeralPort = 41000;

  @override
  Future<List<String>> localIpv4Addresses() async => const <String>[
    '192.168.1.50',
  ];

  @override
  Future<SublimationUdpSocket> bind({
    int port = 0,
    bool broadcastEnabled = true,
  }) async {
    final boundPort = port == 0 ? _nextEphemeralPort++ : port;
    return _SimSublimationUdpSocket(localPort: boundPort, transport: this);
  }

  void _handleSend(
    Uint8List data,
    String address,
    int port,
    _SimSublimationUdpSocket socket,
  ) {
    if (port == 22368) {
      final text = utf8.decode(data, allowMalformed: true).trim();
      inspector.recordText(
        family: CloudPrinterFamily.sublimationRpc,
        transport: 'UDP 22368',
        direction: WireDirection.tx,
        text: text,
        decodedSummary: 'UDP 22368 query: $text',
      );
      if (text == 'DIAGNOSTIC REPORT NETBROADCAST') {
        final rawReply =
            'NET BROADCAST,'
            'MODEL:$modelName,'
            'SOFT:2.4.0,'
            'WLAN DHCP:ON,'
            'WLAN IP:$printerIp,'
            'WLAN SUBNET:255.255.255.0,'
            'WLAN GATEWAY:192.168.1.1,'
            'WLAN MAC:$printerMac,'
            'WIFI NAME:SubOffice-WiFi,'
            'WIFI PASSWORD:sim-sub-password,'
            'WIFI DHCP:ON,'
            'WIFI IP:$printerIp,'
            'WIFI MAC:$printerMac,'
            'BATTERY LEVEL:80%,'
            'SORKET STATUS:IDLE\r\n';
        inspector.recordText(
          family: CloudPrinterFamily.sublimationRpc,
          transport: 'UDP 22368',
          direction: WireDirection.rx,
          text: rawReply,
          decodedSummary:
              'UDP 22368 NET BROADCAST ($modelName @ $printerIp, password redacted)',
        );
        scheduleMicrotask(
          () => socket.emitDatagram(
            Uint8List.fromList(utf8.encode(rawReply)),
            printerIp,
            22368,
          ),
        );
      }
      return;
    }
  }
}

/// Stateful 8B-RPC loopback [ConnectedDevice] for `psdk_fruit_sublimation`.
///
/// Covers `1C 41 50`, `1C 41 4F`, `1C AA 8C`, `1F 54 02`, `1C AA 83`, `1C 72 81`,
/// `1F 52 09`, `1C 72 49`, `1C AA 88`, all `1C 72/77` settings structs, all
/// mechanical actions (`Inject`, `Eject`, `Flip`, `Move`, `MoveBack`, `Recycle`,
/// `Initialize`, `ClearCache`, `SelfTest`, `TestCard`), `1B 43/4D/4B`, `1B 44`
/// bulk planes with `cache > 0` flow control, and `1C 77 46` OTA.
class SimulatedSublimationTcpDevice extends ConnectedDevice<Object> {
  SimulatedSublimationTcpDevice({
    required this.inspector,
    this.serialNumber = 'SUB-D300-001',
    this.modelName = 'SubSim-D300Kp',
  }) {
    _initDefaultSettingFrames();
  }

  final ProtocolInspectorController inspector;
  final String serialNumber;
  final String modelName;
  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  int cardPosition =
      0; // 0=noCard, 1=print, 4=contact, 5=contactless, 10=frontClip
  int mainStatus = 0x4D000201; // Ready
  int errorStatus = 0x45000000;
  int warningStatus = 0x57000000;
  int boxByte = 0x09; // 6-inch paper + 6-inch ribbon
  int battByte = 0xD0; // charging + 8.0V (80%)
  int ribbonRemaining = 88;
  int cardIssuedCount = 12;
  int printTotalCount = 24;
  int printHeadCount = 24;

  // Flow control simulation for cache > 0 & waitPrintFinish
  int cacheZeroPollsRemaining = 0;
  int finishPollsRemaining = 0;
  final List<String> capturedPlanes = <String>[];
  int totalOtaBytes = 0;

  late Uint8List _cardSettingFrame;
  late Uint8List _net1Frame;
  late Uint8List _net2Frame;
  late Uint8List _imgFrontFrame;
  late Uint8List _imgBackFrame;
  late Uint8List _printerSettingFrame;
  late Uint8List _edsSettingFrame;
  late Uint8List _consumablesSettingFrame;
  late Uint8List _maintain1Frame;
  late Uint8List _maintain4Frame;
  late Uint8List _maintain5Frame;
  late Uint8List _maintain6Frame;

  int _bulkExpectedLen = 0;
  final BytesBuilder _bulkBuf = BytesBuilder(copy: false);

  void _initDefaultSettingFrames() {
    _cardSettingFrame = SublimationRpcCodec.buildSetCardSetting(
      cardType: SublimationCardType.pvc.code,
      stdCardExit: SublimationCardExit.front.code,
      errCardExit: SublimationCardExit.front.code,
      feedingCardMode: SublimationFeedingMode.frontBox.code,
    );
    _cardSettingFrame[1] = 0x72;

    _net1Frame = SublimationRpcCodec.buildSetNetworkSetting1(
      printerId: 1,
      useStaticIp: true,
      ip: '192.168.1.88',
      gateway: '192.168.1.1',
      subnetMask: '255.255.255.0',
    );
    _net1Frame[1] = 0x72;

    _net2Frame = _empty40(0x1C, 0x72, 0x45, 0x01);
    _net2Frame.setRange(9, 15, const <int>[0x11, 0x22, 0x33, 0x44, 0x55, 0x66]);
    ByteData.sublistView(_net2Frame).setUint32(23, 30, Endian.little);

    _imgFrontFrame = SublimationRpcCodec.buildSetImageSetting(
      front: true,
      yellowBalance: 0,
      magentaBalance: 0,
      cyanBalance: 0,
      blackBalance: 0,
      overlayBalance: 0,
    )..[1] = 0x72;

    _imgBackFrame = SublimationRpcCodec.buildSetImageSetting(
      front: false,
      yellowBalance: 0,
      magentaBalance: 0,
      cyanBalance: 0,
      blackBalance: 0,
      overlayBalance: 0,
    )..[1] = 0x72;

    _printerSettingFrame = _empty40(0x1C, 0x72, 0x50, 0x00);
    _printerSettingFrame[9] = 1; // buzzer enabled
    _printerSettingFrame[11] = 1; // auto shutdown enabled
    ByteData.sublistView(_printerSettingFrame).setUint16(14, 15, Endian.little);

    _edsSettingFrame = _empty40(0x1C, 0x72, 0x50, 0x02);
    _edsSettingFrame[10] = SublimationLcdLanguage.english.code;
    _edsSettingFrame[13] = 5;
    _edsSettingFrame[16] = 1;
    _edsSettingFrame[22] = SublimationColorBrightness.vivid.code;
    _edsSettingFrame[31] = 1;
    _edsSettingFrame[37] = 1;

    _consumablesSettingFrame = SublimationRpcCodec.buildSetConsumablesSetting(
      ribbonType: SublimationRibbonType.ymcko.code,
      ribbonNearEndAlert: 10,
    )..[1] = 0x72;

    _maintain1Frame = _empty40(0x1C, 0x72, 0x4D, 0x01);
    _maintain4Frame = _empty40(0x1C, 0x72, 0x4D, 0x04);
    _maintain4Frame[12] = 1; // contactless card reader
    _maintain4Frame[13] = 1; // flipper installed
    _maintain4Frame[16] = 1; // front feeding box installed
    _maintain4Frame[17] = 1; // front recycling box installed
    _maintain4Frame[31] = 3;

    _maintain5Frame = _empty44(0x1C, 0x72, 0x4D, 0x05);
    _maintain5Frame[10] = 0; // holdCardWhenEject
    _maintain5Frame[13] = 1; // recyclingBoxFullDetect

    _maintain6Frame = _empty44(0x1C, 0x72, 0x4D, 0x06);
    _maintain6Frame[10] = 0;
  }

  static Uint8List _empty40(int b0, int b1, int b2, int b3) {
    final f = Uint8List(40);
    f[0] = b0;
    f[1] = b1;
    f[2] = b2;
    f[3] = b3;
    ByteData.sublistView(f).setUint32(4, 32, Endian.little);
    return f;
  }

  static Uint8List _empty44(int b0, int b1, int b2, int b3) {
    final f = Uint8List(44);
    f[0] = b0;
    f[1] = b1;
    f[2] = b2;
    f[3] = b3;
    ByteData.sublistView(f).setUint32(4, 36, Endian.little);
    return f;
  }

  @override
  Object origin() => 'sim://sublimation-tcp';

  @override
  String? deviceName() => modelName;

  @override
  String? deviceMac() => '11:22:33:44:55:66';

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

    if (_bulkExpectedLen > 0) {
      _bulkBuf.add(data);
      if (_bulkBuf.length < _bulkExpectedLen) {
        return;
      }
      final full = _bulkBuf.takeBytes();
      _bulkExpectedLen = 0;
      _finalizeBulkFrame(full);
      return;
    }

    if (data.length >= 8 &&
        ((data[0] == 0x1B && data[1] == 0x44) ||
            (data[0] == 0x1C && data[1] == 0x77 && data[2] == 0x46))) {
      final payloadLen = ByteData.sublistView(data).getUint32(4, Endian.little);
      final totalLen = 8 + payloadLen;
      if (data.length < totalLen) {
        _bulkExpectedLen = totalLen;
        _bulkBuf.add(data);
        return;
      }
      _finalizeBulkFrame(data);
      return;
    }

    _dispatchControlFrame(data);
  }

  void _finalizeBulkFrame(Uint8List full) {
    if (full[0] == 0x1B && full[1] == 0x44) {
      final planeName = full.length >= 16
          ? utf8.decode(full.sublist(8, 16), allowMalformed: true).trim()
          : 'Plane';
      capturedPlanes.add(planeName);
      // Force next 2 status polls to see cache == 0 -> exercises waitingCache stage
      cacheZeroPollsRemaining = 2;
      if (planeName.startsWith('OverCort')) {
        finishPollsRemaining = 2;
      }
      inspector.record(
        family: CloudPrinterFamily.sublimationRpc,
        transport: 'TCP :9100 RPC',
        direction: WireDirection.tx,
        rawBytes: full,
        decodedSummary: '1B 44 Bulk Plane "$planeName" (${full.length} B)',
      );
      final ack = Uint8List.fromList(<int>[
        0x1B,
        0x44,
        full[2],
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      _emitReply(ack, '1B 44 Plane ACK ($planeName)');
      return;
    }

    if (full[0] == 0x1C && full[1] == 0x77 && full[2] == 0x46) {
      totalOtaBytes += full.length;
      inspector.record(
        family: CloudPrinterFamily.sublimationRpc,
        transport: 'TCP :9100 RPC',
        direction: WireDirection.tx,
        rawBytes: full,
        decodedSummary: '1C 77 46 OTA chunk (${full.length} B)',
      );
      final ack = Uint8List.fromList(<int>[
        0x1C,
        0x77,
        0x46,
        full[3],
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      _emitReply(ack, '1C 77 46 OTA ACK');
    }
  }

  void _dispatchControlFrame(Uint8List req) {
    final op0 = req[0];
    final op1 = req.length > 1 ? req[1] : 0;
    final op2 = req.length > 2 ? req[2] : 0;
    final op3 = req.length > 3 ? req[3] : 0;

    // 1C 41 50 -> GetPrinterStatus (40B)
    if (op0 == 0x1C && op1 == 0x41 && op2 == 0x50) {
      int cache = 2;
      if (cacheZeroPollsRemaining > 0) {
        cacheZeroPollsRemaining--;
        cache = 0;
      } else if (finishPollsRemaining > 0) {
        finishPollsRemaining--;
        cache = 1;
      }
      _logTx(req, 'GetPrinterStatus (1C 41 50)');
      final frame = _empty40(0x1C, 0x41, 0x50, 0x00);
      final view = ByteData.sublistView(frame);
      view.setInt16(10, 2850, Endian.little); // chassis 28.50C
      view.setInt16(14, 3420, Endian.little); // head 34.20C
      view.setUint32(16, mainStatus, Endian.big);
      view.setUint32(24, errorStatus, Endian.big);
      view.setUint32(28, warningStatus, Endian.big);
      frame[37] = boxByte;
      frame[38] = battByte;
      frame[39] = cache;
      _emitReply(
        frame,
        'PrinterStatus (cache=$cache, pos=$cardPosition, main=0x${mainStatus.toRadixString(16)})',
      );
      return;
    }

    // 1C 41 4F -> GetConsumablesInfo (40B)
    if (op0 == 0x1C && op1 == 0x41 && op2 == 0x4F) {
      _logTx(req, 'GetConsumablesInfo (1C 41 4F)');
      final frame = _empty40(0x1C, 0x41, 0x4F, 0x00);
      frame[26] = ribbonRemaining;
      _emitReply(frame, 'ConsumablesInfo (ribbon=$ribbonRemaining%)');
      return;
    }

    // 1C AA 8C -> GetCardPosition (8B special case, byte[6] = cardPosition)
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x8C) {
      _logTx(req, 'GetCardPosition (1C AA 8C)');
      final frame = Uint8List.fromList(<int>[
        0x1C,
        0xAA,
        0x8C,
        0x00,
        0x01,
        0x00,
        cardPosition & 0xFF,
        0x00,
      ]);
      _emitReply(frame, 'CardPosition = $cardPosition');
      return;
    }

    // 1F 54 02 -> GetPrinterSensor (13B)
    if (op0 == 0x1F && op1 == 0x54 && op2 == 0x02) {
      _logTx(req, 'GetPrinterSensor (1F 54 02)');
      final frame = Uint8List(13);
      frame[0] = 0x1F;
      frame[1] = 0x54;
      frame[2] = 0x02;
      frame[3] = 0x00;
      frame[4] = 0x05;
      var sensorVal = SublimationSensorFlag.ce.mask; // feeding box has cards
      if (cardPosition == 10) sensorVal |= SublimationSensorFlag.cf2.mask;
      if (cardPosition == 11) sensorVal |= SublimationSensorFlag.cf5.mask;
      ByteData.sublistView(frame).setUint32(9, sensorVal, Endian.big);
      _emitReply(frame, 'PrinterSensor (0x${sensorVal.toRadixString(16)})');
      return;
    }

    // 1C AA 83 -> GetPrinterInfo
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x83) {
      _logTx(req, 'GetPrinterInfo (1C AA 83)');
      final text = utf8.encode(
        '$modelName;PSDK;$serialNumber;2026-11-20;USB\\VID_0001;3.1.0',
      );
      final frame = Uint8List(8 + text.length);
      frame[0] = 0x1C;
      frame[1] = 0xAA;
      frame[2] = 0x83;
      ByteData.sublistView(frame).setUint32(4, text.length, Endian.little);
      frame.setRange(8, frame.length, text);
      _emitReply(frame, 'PrinterInfo -> $modelName / $serialNumber');
      return;
    }

    // 1C 72 81 -> GetModelId (6B header + LE16 len)
    if (op0 == 0x1C && op1 == 0x72 && op2 == 0x81) {
      _logTx(req, 'GetModelId (1C 72 81)');
      final text = utf8.encode(modelName);
      final frame = Uint8List(6 + text.length);
      frame[0] = 0x1C;
      frame[1] = 0x72;
      frame[2] = 0x81;
      ByteData.sublistView(frame).setUint16(4, text.length, Endian.little);
      frame.setRange(6, frame.length, text);
      _emitReply(frame, 'ModelId -> $modelName');
      return;
    }

    // 1F 52 09 -> GetSerialNumber (5B header + LE16 len)
    if (op0 == 0x1F && op1 == 0x52 && op2 == 0x09) {
      _logTx(req, 'GetSerialNumber (1F 52 09)');
      final text = utf8.encode(serialNumber);
      final frame = Uint8List(5 + text.length);
      frame[0] = 0x1F;
      frame[1] = 0x52;
      frame[2] = 0x09;
      ByteData.sublistView(frame).setUint16(3, text.length, Endian.little);
      frame.setRange(5, frame.length, text);
      _emitReply(frame, 'SerialNumber -> $serialNumber');
      return;
    }

    // 1C 72 49 00|02 -> VersionInfo1/2
    if (op0 == 0x1C && op1 == 0x72 && op2 == 0x49) {
      _logTx(req, 'GetVersionInfo (1C 72 49 ${op3.toRadixString(16)})');
      final frame = _empty40(0x1C, 0x72, 0x49, op3);
      if (op3 == 0x00) {
        frame[36] = 0x02;
        frame[35] = 0x01;
        frame[34] = 0x00;
        frame[33] = 0x04;
      } else {
        frame[12] = 0x01;
        frame[13] = 0x00;
        frame[14] = 0x03;
        frame[15] = 0x02;
      }
      _emitReply(frame, 'VersionInfo($op3)');
      return;
    }

    // 1C AA 88 -> GetPrintCardCount (32B)
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x88) {
      _logTx(req, 'GetPrintCardCount (1C AA 88)');
      final frame = Uint8List(32);
      frame[0] = 0x1C;
      frame[1] = 0xAA;
      frame[2] = 0x88;
      final view = ByteData.sublistView(frame);
      view.setUint32(4, 24, Endian.little);
      view.setUint32(8, cardIssuedCount, Endian.little);
      view.setUint32(13, printTotalCount, Endian.little);
      view.setUint32(18, printHeadCount, Endian.little);
      _emitReply(
        frame,
        'CardCount(issued=$cardIssuedCount, total=$printTotalCount)',
      );
      return;
    }

    // Get/Set Settings (1C 72 / 1C 77)
    if (op0 == 0x1C && (op1 == 0x72 || op1 == 0x77)) {
      final isWrite = op1 == 0x77;
      if (op2 == 0x43) {
        if (isWrite) _cardSettingFrame = Uint8List.fromList(req)..[1] = 0x72;
        _logTx(req, '${isWrite ? "Set" : "Get"}CardSetting');
        _emitReply(_cardSettingFrame, 'CardSetting');
        return;
      }
      if (op2 == 0x45 && op3 == 0x00) {
        if (isWrite) _net1Frame = Uint8List.fromList(req)..[1] = 0x72;
        _logTx(req, '${isWrite ? "Set" : "Get"}NetworkSetting1');
        _emitReply(_net1Frame, 'NetworkSetting1');
        return;
      }
      if (op2 == 0x45 && op3 == 0x01) {
        if (isWrite) _net2Frame = Uint8List.fromList(req)..[1] = 0x72;
        _logTx(req, '${isWrite ? "Set" : "Get"}NetworkSetting2');
        _emitReply(_net2Frame, 'NetworkSetting2');
        return;
      }
      if (op2 == 0x47) {
        if (op3 == 0x00) {
          if (isWrite) _imgFrontFrame = Uint8List.fromList(req)..[1] = 0x72;
          _logTx(req, '${isWrite ? "Set" : "Get"}ImageSetting(front)');
          _emitReply(_imgFrontFrame, 'ImageSetting(front)');
        } else {
          if (isWrite) _imgBackFrame = Uint8List.fromList(req)..[1] = 0x72;
          _logTx(req, '${isWrite ? "Set" : "Get"}ImageSetting(back)');
          _emitReply(_imgBackFrame, 'ImageSetting(back)');
        }
        return;
      }
      if (op2 == 0x50 && op3 == 0x00) {
        if (isWrite) _printerSettingFrame = Uint8List.fromList(req)..[1] = 0x72;
        _logTx(req, '${isWrite ? "Set" : "Get"}PrinterSetting');
        final autoMin = ByteData.sublistView(
          _printerSettingFrame,
        ).getUint16(14, Endian.little);
        _emitReply(
          _printerSettingFrame,
          'PrinterSetting (autoShutDown=$autoMin min)',
        );
        return;
      }
      if (op2 == 0x50 && op3 == 0x02) {
        if (isWrite) _edsSettingFrame = Uint8List.fromList(req)..[1] = 0x72;
        _logTx(req, '${isWrite ? "Set" : "Get"}EdsSetting');
        _emitReply(_edsSettingFrame, 'EdsSetting');
        return;
      }
      if (op2 == 0x52) {
        if (isWrite) {
          _consumablesSettingFrame = Uint8List.fromList(req)..[1] = 0x72;
        }
        _logTx(req, '${isWrite ? "Set" : "Get"}ConsumablesSetting');
        _emitReply(_consumablesSettingFrame, 'ConsumablesSetting');
        return;
      }
      if (op2 == 0x4D) {
        _logTx(req, '${isWrite ? "Set" : "Get"}MaintainSetting$op3');
        if (op3 == 0x01) {
          _emitReply(_maintain1Frame, 'MaintainSetting1');
          return;
        }
        if (op3 == 0x04) {
          if (isWrite) _maintain4Frame = Uint8List.fromList(req)..[1] = 0x72;
          _emitReply(_maintain4Frame, 'MaintainSetting4');
          return;
        }
        if (op3 == 0x05) {
          if (isWrite) _maintain5Frame = Uint8List.fromList(req)..[1] = 0x72;
          _emitReply(_maintain5Frame, 'MaintainSetting5');
          return;
        }
        if (op3 == 0x06) {
          if (isWrite) _maintain6Frame = Uint8List.fromList(req)..[1] = 0x72;
          _emitReply(_maintain6Frame, 'MaintainSetting6');
          return;
        }
      }
      if (op2 == 0x54) {
        _logTx(req, 'PrintTestCard (1C 77 54)');
        cardIssuedCount++;
        printTotalCount++;
        _emitReply(_echo8(req), 'PrintTestCard ACK');
        return;
      }
    }

    // Mechanical & maintenance actions
    if (op0 == 0x1B && op1 == 0x50) {
      // InjectCard
      cardPosition = 1;
      mainStatus = 0x4D000201;
      _logTx(req, 'InjectCard (1B 50)');
      _emitReply(_echo8(req), 'InjectCard ACK (pos=1)');
      return;
    }
    if (op0 == 0x1B && op1 == 0x45) {
      // EjectCard (byte[8] == 'E' -> holdPaper)
      final hold = req.length > 8 && req[8] == 0x45;
      if (hold) {
        mainStatus = 0x4D000902;
        cardPosition = 10;
      } else {
        mainStatus = 0x4D000201;
        cardPosition = 0;
      }
      _logTx(req, 'EjectCard (${hold ? "holdPaper" : "normal"})');
      _emitReply(_echo8(req), 'EjectCard ACK (pos=$cardPosition)');
      return;
    }
    if (op0 == 0x1B && op1 == 0x52) {
      _logTx(req, 'FlipCard (1B 52)');
      _emitReply(_echo8(req), 'FlipCard ACK');
      return;
    }
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x80) {
      final act = req.length > 23 ? req[23] : 0;
      if (act == 0) {
        mainStatus = 0x4D000201;
        final ext = req.length > 22 ? req[22] : 0;
        switch (ext) {
          case 0:
            cardPosition = 5; // contactless
            break;
          case 2:
            cardPosition = 4; // contact
            break;
          case 3:
            cardPosition = 9; // magneticReady
            break;
          case 4:
            cardPosition = 7; // magneticFinish
            break;
          default:
            cardPosition = 1;
            break;
        }
      }
      _logTx(req, 'MoveCardTo act=$act (pos=$cardPosition)');
      _emitReply(_echo8(req), 'MoveCardTo ACK');
      return;
    }
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x82) {
      final act = req.length > 23 ? req[23] : 0;
      if (act == 0) {
        mainStatus = 0x4D000201;
        cardPosition = 1;
      }
      _logTx(req, 'MoveCardBack act=$act (pos=1)');
      _emitReply(_echo8(req), 'MoveCardBack ACK');
      return;
    }
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x8F) {
      cardPosition = 0;
      mainStatus = 0x4D000201;
      _logTx(req, 'RecycleCard (1C AA 8F)');
      _emitReply(_echo8(req), 'RecycleCard ACK (pos=0)');
      return;
    }
    if (op0 == 0x1B && op1 == 0x49) {
      cardPosition = 0;
      mainStatus = 0x4D000201;
      errorStatus = 0x45000000;
      _logTx(req, 'InitializePrinter (1B 49)');
      _emitReply(_echo8(req), 'InitializePrinter ACK');
      return;
    }
    if (op0 == 0x1C && op1 == 0xAA && op2 == 0x89) {
      cacheZeroPollsRemaining = 0;
      finishPollsRemaining = 0;
      _logTx(req, 'ClearPrinterCache (1C AA 89)');
      _emitReply(_echo8(req), 'ClearPrinterCache ACK');
      return;
    }
    if (op0 == 0x1F && op1 == 0x54 && op2 == 0x04 && op3 == 0x00) {
      cardIssuedCount++;
      printTotalCount++;
      _logTx(req, 'PrintSelfTestCard (1F 54 04 00)');
      _emitReply(
        Uint8List.fromList(const <int>[0x1F, 0x54, 0x04, 0x00]),
        'PrintSelfTestCard ACK',
      );
      return;
    }
    if (op0 == 0x1B && (op1 == 0x43 || op1 == 0x4D || op1 == 0x4B)) {
      _logTx(
        req,
        'PrintSettingFrame (1B ${op1.toRadixString(16).toUpperCase()})',
      );
      _emitReply(_echo8(req), 'PrintSettingFrame ACK');
      return;
    }

    _logTx(req, 'RPC Command (${req.length} B)');
    _emitReply(_echo8(req), 'Generic RPC ACK');
  }

  Uint8List _echo8(Uint8List req) {
    final len = req.length >= 8 ? 8 : req.length;
    final out = Uint8List.fromList(req.sublist(0, len));
    if (out.length >= 8) {
      ByteData.sublistView(out).setUint32(4, 0, Endian.little);
    }
    return out;
  }

  void _logTx(Uint8List bytes, String summary) {
    inspector.record(
      family: CloudPrinterFamily.sublimationRpc,
      transport: 'TCP :9100 RPC',
      direction: WireDirection.tx,
      rawBytes: bytes,
      decodedSummary: summary,
    );
  }

  void _emitReply(Uint8List bytes, String summary) {
    inspector.record(
      family: CloudPrinterFamily.sublimationRpc,
      transport: 'TCP :9100 RPC',
      direction: WireDirection.rx,
      rawBytes: bytes,
      decodedSummary: summary,
    );
    scheduleMicrotask(() {
      if (!_readController.isClosed && _state == ConnectionState.connected) {
        _readController.add(bytes);
      }
    });
  }
}
