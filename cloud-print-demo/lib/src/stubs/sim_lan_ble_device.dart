import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import '../models/protocol_inspector.dart';

/// 热敏与 4 寸热升华共用的蓝牙 Wi-Fi 文本命令模拟器。
class SimulatedLanBleDevice extends ConnectedDevice<Object> {
  SimulatedLanBleDevice({
    required this.inspector,
    this.assignedIp = '192.168.1.88',
    this.family = CloudPrinterFamily.sublimationRpc,
  });

  final ProtocolInspectorController inspector;
  final String assignedIp;
  final CloudPrinterFamily family;
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

    final text = utf8.decode(data, allowMalformed: true).trim();
    inspector.recordText(
      family: family,
      transport: 'BLE 配网',
      direction: WireDirection.tx,
      text: text,
      decodedSummary: ProtocolInspectorController.redactSecrets(text),
    );

    if (text.toUpperCase().startsWith('BLUETOOTH SETSSID,')) {
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

    if (text.toUpperCase() == 'BLUETOOTH GETLINKSTATE') {
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
