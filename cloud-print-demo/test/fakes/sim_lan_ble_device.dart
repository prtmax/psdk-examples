import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';

/// 热敏与 4 寸热升华共用的蓝牙 Wi-Fi 文本命令及热点查询模拟器。
class SimulatedLanBleDevice extends ConnectedDevice<Object> {
  SimulatedLanBleDevice({
    required this.inspector,
    this.assignedIp = '192.168.1.88',
    this.family = CloudPrinterFamily.sublimationRpc,
    this.apSsid = 'Z11_SIM_AP',
    this.apPassword = '12345678',
    this.apIp = '192.168.4.1',
  });

  final ProtocolInspectorController inspector;
  final String assignedIp;
  final CloudPrinterFamily family;
  String apSsid;
  String apPassword;
  String apIp;
  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  String routerSsid = 'SubOffice-WiFi';
  String routerPassword = '';
  int _linkPolls = 0;

  @override
  Object origin() => 'sim://sublimation-ble';

  @override
  String? deviceName() => 'SubSim-D300Kp-BLE';

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

    if (data.length >= SublimationBleMeshCodec.minFrameLength &&
        data[0] == SublimationBleMeshCodec.headerByte0 &&
        data[1] == SublimationBleMeshCodec.headerByte1) {
      final req = SublimationBleMeshCodec.decodeFrame(
        data,
        strictChecksum: false,
      );
      inspector.record(
        family: family,
        transport: 'BLE Mesh',
        direction: WireDirection.tx,
        rawBytes: data,
        decodedSummary: 'BLE Mesh cmd=0x${req.rawCommand.toRadixString(16)}',
      );
      if (req.command == SublimationBleMeshCommand.getLocalWifiSsid) {
        final reply = SublimationBleMeshCodec.encodeCommand(
          SublimationBleMeshCommand.getLocalWifiSsid,
          utf8.encode(apSsid),
        );
        _emitBytes(reply, 'BLE Mesh', 'AP SSID: $apSsid');
      } else if (req.command ==
          SublimationBleMeshCommand.getLocalWifiPassword) {
        final reply = SublimationBleMeshCodec.encodeCommand(
          SublimationBleMeshCommand.getLocalWifiPassword,
          utf8.encode(apPassword),
        );
        _emitBytes(
          reply,
          'BLE Mesh',
          'AP Password: [REDACTED]',
          logRawBytes: Uint8List(0),
        );
      } else if (req.command ==
          SublimationBleMeshCommand.getLocalWifiIpParams) {
        final ipParts = SublimationIpv4Codec.encodeReversed(apIp);
        final payload = Uint8List.fromList(<int>[
          ...ipParts,
          0x00,
          0xFF,
          0xFF,
          0xFF,
          ...ipParts,
          0x8C,
          0x23,
          0x6D,
          0x07,
        ]);
        final reply = SublimationBleMeshCodec.encodeCommand(
          SublimationBleMeshCommand.getLocalWifiIpParams,
          payload,
        );
        _emitBytes(reply, 'BLE Mesh', 'AP IP Params: $apIp:9100');
      } else if (req.command == SublimationBleMeshCommand.getLocalWifiStatus) {
        final reply = SublimationBleMeshCodec.encodeCommand(
          SublimationBleMeshCommand.getLocalWifiStatus,
          <int>[0, 1],
        );
        _emitBytes(reply, 'BLE Mesh', 'AP Status: AP connected');
      }
      return;
    }

    final text = utf8.decode(data, allowMalformed: true).trim();
    inspector.recordText(
      family: family,
      transport: 'BLE 配网',
      direction: WireDirection.tx,
      text: text,
      decodedSummary: ProtocolInspectorController.redactSecrets(text),
    );

    final upper = text.toUpperCase();
    if (upper.startsWith('BLUETOOTH SETSSID,')) {
      final rest = text.substring('BLUETOOTH SETSSID,'.length);
      final comma = rest.indexOf(',');
      if (comma >= 0) {
        routerSsid = rest.substring(0, comma).trim();
        routerPassword = rest.substring(comma + 1).trim();
      } else {
        routerSsid = rest.trim();
        routerPassword = '';
      }
      _linkPolls = 0;
      _emitBytes(
        Uint8List.fromList(utf8.encode('OK\r\n')),
        'BLE 配网',
        'SETSSID 回复：OK',
        chunkSize: 0,
      );
      return;
    }

    if (upper == 'DIAGNOSTIC REPORT APSSID') {
      final reply = 'APSSID:$apSsid\r\n';
      _emitBytes(
        Uint8List.fromList(utf8.encode(reply)),
        'BLE 配网',
        'APSSID 回复：$apSsid',
        chunkSize: 7,
      );
      return;
    }

    if (upper == 'DIAGNOSTIC REPORT APPASSWORD') {
      final reply = 'APPASSWORD:$apPassword\r\n';
      _emitBytes(
        Uint8List.fromList(utf8.encode(reply)),
        'BLE 配网',
        'APPASSWORD 回复：[REDACTED]',
        chunkSize: 7,
        logRawBytes: Uint8List(0),
      );
      return;
    }

    if (upper == 'BLUETOOTH GETSSID') {
      final reply = 'GETSSID:$apSsid\r\n';
      _emitBytes(
        Uint8List.fromList(utf8.encode(reply)),
        'BLE 配网',
        'GETSSID 回复：$apSsid',
      );
      return;
    }

    if (upper == 'BLUETOOTH GETPASSWORD') {
      final reply = 'GETPASSWORD:$apPassword\r\n';
      _emitBytes(
        Uint8List.fromList(utf8.encode(reply)),
        'BLE 配网',
        'GETPASSWORD 回复：[REDACTED]',
        logRawBytes: Uint8List(0),
      );
      return;
    }

    if (upper == 'BLUETOOTH GETLINKSTATE') {
      _linkPolls++;
      final connected = _linkPolls >= 2;
      final reply = connected
          ? 'GETLINKSTATE:connected\r\n'
          : 'GETLINKSTATE:disconnected\r\n';
      _emitBytes(
        Uint8List.fromList(utf8.encode(reply)),
        'BLE 配网',
        'GETLINKSTATE 回复： ${reply.trim()}',
        chunkSize: 7,
      );
    }
  }

  void _emitBytes(
    Uint8List bytes,
    String transport,
    String summary, {
    int chunkSize = 0,
    Uint8List? logRawBytes,
  }) {
    inspector.record(
      family: family,
      transport: transport,
      direction: WireDirection.rx,
      rawBytes: logRawBytes ?? bytes,
      decodedSummary: summary,
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
