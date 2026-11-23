import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/protocol_inspector.dart';
import 'in_memory_io.dart';
import 'sim_lan_ble_device.dart';

/// In-memory UDP 22368 discovery + TCP :9100 loopback backend wired into
/// `Network.scoped(...)` for `CloudPrinterFamily.thermalLanStream`.
class SimThermalLanBackend {
  SimThermalLanBackend({required this.inspector, required this.wifiDevice});

  final ProtocolInspectorController inspector;
  final SimulatedLanBleDevice wifiDevice;

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
              'WLAN DHCP:ON,'
              'WLAN IP:${wifiDevice.assignedIp},'
              'WLAN SUBNET:255.255.255.0,'
              'WLAN GATEWAY:192.168.1.1,'
              'WLAN MAC:AA:BB:CC:11:22:33,'
              'WIFI NAME:${wifiDevice.routerSsid},'
              'WIFI PASSWORD:${wifiDevice.routerPassword},'
              'WIFI DHCP:ON,'
              'WIFI IP:${wifiDevice.assignedIp},'
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
                'UDP 22368 NET BROADCAST (${wifiDevice.assignedIp}, password redacted)',
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
