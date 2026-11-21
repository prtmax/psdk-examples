import 'dart:typed_data';

import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';

import '../models/protocol_inspector.dart';

/// Records traffic at the SDK boundary without keeping credential fragments
/// or copying entire print jobs into the inspector.
class InspectedDevice extends ConnectedDevice<dynamic> {
  InspectedDevice(this.device, this.inspector, this.family, this.transport);

  final ConnectedDevice<dynamic> device;
  final ProtocolInspectorController inspector;
  final CloudPrinterFamily family;
  final String transport;

  void _record(WireDirection direction, Uint8List bytes) {
    final isRaster =
        transport == 'TCP' &&
        direction == WireDirection.tx &&
        ((family == CloudPrinterFamily.sublimationRpc &&
                bytes.length >= 2 &&
                bytes[0] == 0x1b &&
                bytes[1] == 0x44) ||
            (family == CloudPrinterFamily.colorInkjetPjl &&
                bytes.length >= 2 &&
                bytes[0] == 0x58 &&
                bytes[1] >= 1 &&
                bytes[1] <= 5));
    inspector.record(
      family: family,
      transport: transport,
      direction: direction,
      rawBytes: isRaster
          ? Uint8List.sublistView(bytes, 0, bytes.length.clamp(0, 64))
          : Uint8List(0),
      decodedSummary:
          '${bytes.length} B ${isRaster ? "print frame" : "device traffic (payload hidden)"}',
    );
  }

  @override
  dynamic origin() => device.origin();
  @override
  String? deviceName() => device.deviceName();
  @override
  String? deviceMac() => device.deviceMac();
  @override
  ConnectionState connectionState() => device.connectionState();
  @override
  Future<void> disconnect() => device.disconnect();
  @override
  Future<bool> cancelWrite() => device.cancelWrite();
  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {
    await device.write(data, sendDone: sendDone);
    _record(WireDirection.tx, data);
  }

  @override
  Stream<Uint8List> read(ReadOptions? options) =>
      device.read(options).map((chunk) {
        _record(WireDirection.rx, chunk);
        return chunk;
      });
}

class InspectedNetworkBinder extends DefaultInkjetNetworkBinder {
  InspectedNetworkBinder(this.inspector, this.family);

  final ProtocolInspectorController inspector;
  final CloudPrinterFamily family;

  @override
  Future<ConnectedDevice<dynamic>> connectDevice(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 4),
    String? networkInterface,
  }) async => InspectedDevice(
    await super.connectDevice(
      host,
      port,
      timeout: timeout,
      networkInterface: networkInterface,
    ),
    inspector,
    family,
    'TCP',
  );
}
