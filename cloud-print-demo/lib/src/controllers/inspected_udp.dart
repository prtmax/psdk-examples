import 'dart:typed_data';

import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/protocol_inspector.dart';

class InspectedSublimationUdp extends RawDatagramUdpTransport {
  const InspectedSublimationUdp(this.inspector);

  final ProtocolInspectorController inspector;

  @override
  Future<SublimationUdpSocket> bind({
    int port = 0,
    bool broadcastEnabled = true,
  }) async => _UdpSocket(
    await super.bind(port: port, broadcastEnabled: broadcastEnabled),
    inspector,
  );
}

class _UdpSocket implements SublimationUdpSocket {
  _UdpSocket(this.inner, this.inspector);
  final SublimationUdpSocket inner;
  final ProtocolInspectorController inspector;

  void _record(WireDirection direction, int port, int length) {
    inspector.record(
      family: CloudPrinterFamily.sublimationRpc,
      transport: 'UDP $port',
      direction: direction,
      rawBytes: Uint8List(0),
      decodedSummary: '$length B discovery/control datagram',
    );
  }

  @override
  int get localPort => inner.localPort;

  @override
  Stream<SublimationUdpDatagram> get datagrams =>
      inner.datagrams.map((datagram) {
        _record(WireDirection.rx, datagram.port, datagram.data.length);
        return datagram;
      });

  @override
  Future<int> send(Uint8List data, String address, int port) async {
    final sent = await inner.send(data, address, port);
    _record(WireDirection.tx, port, sent);
    return sent;
  }

  @override
  Future<void> close() => inner.close();
}
