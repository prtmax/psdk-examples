import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_print_demo/src/controllers/inspected_device.dart';
import 'package:cloud_print_demo/src/controllers/inspected_wan.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

void main() {
  test(
    'real HTTP reports status without copying private headers, URL or body',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final inspector = ProtocolInspectorController();
      addTearDown(inspector.dispose);
      final client = InspectedWan(inspector).createHttpClient();
      addTearDown(() => client.close(force: true));
      final receive = server.first.then((request) async {
        expect(await utf8.decoder.bind(request).join(), 'private-body');
        request.response.statusCode = 201;
        await request.response.close();
      });
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:${server.port}/?token=private-url'),
      );
      request.headers.set('authorization', 'private-header');
      request.write('private-body');
      final response = await request.close();
      await response.drain<void>();
      await receive;
      expect(inspector.entries.map((e) => e.decodedSummary), [
        'POST',
        'POST HTTP 201',
      ]);
      expect(inspector.exportAll(), isNot(contains('private')));
    },
  );

  for (final mqtt in [false, true]) {
    test(
      'real ${mqtt ? "MQTT" : "printer TCP"} forwards loopback traffic and records both directions',
      () async {
        final inspector = ProtocolInspectorController();
        addTearDown(inspector.dispose);
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final accepted = server.first;
        final payload = [0x58, 3, ...List.filled(100, 1)];
        if (mqtt) {
          final socket = await InspectedWan(
            inspector,
          ).connectMqtt('127.0.0.1', server.port, useTls: false);
          addTearDown(socket.destroy);
          final peer = await accepted;
          addTearDown(peer.destroy);
          final receive = peer.first;
          final reply = socket.first;
          socket.add(payload);
          await socket.flush();
          expect(await receive, payload);
          peer.add([32, 0]);
          expect(await reply, [32, 0]);
        } else {
          final device = await InspectedNetworkBinder(
            inspector,
            CloudPrinterFamily.colorInkjetPjl,
          ).connectDevice('127.0.0.1', server.port);
          addTearDown(device.disconnect);
          final peer = await accepted;
          addTearDown(peer.destroy);
          final receive = peer.first;
          final reply = device.read(null).first;
          await device.write(Uint8List.fromList(payload));
          expect(await receive, payload);
          peer.add([32, 0]);
          expect(await reply, [32, 0]);
        }
        expect(inspector.entries.map((e) => e.direction), [
          WireDirection.tx,
          WireDirection.rx,
        ]);
        expect(inspector.entries.first.rawBytes.length, mqtt ? 0 : 64);
        expect(inspector.entries.last.rawBytes, isEmpty);
      },
    );
  }
}
