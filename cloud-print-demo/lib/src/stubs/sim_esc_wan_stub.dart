import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:psdk_cloud_wan/psdk_cloud_wan.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../models/protocol_inspector.dart';
import 'in_memory_io.dart';

/// Loopback BLE/Serial [ConnectedDevice] implementing `psdk_fruit_esc`
/// binary Wi-Fi provisioning & info commands (`ESetWifi`, `ESetHost`, `ESetKey`,
/// `EGetKey`, `EGetWifiSta`, `EGetWifiName`, `EResetNetworkInfo`, `ESN`, `EMac`,
/// `EPrinterVersion`).
class SimEscConnectedDevice extends ConnectedDevice<String> {
  SimEscConnectedDevice({
    required this.inspector,
    this.serialNumber = 'SIM-ESC-2026001',
    this.macBytes = const <int>[0xAA, 0xBB, 0xCC, 0x11, 0x22, 0x33],
    this.firmwareVersion = '1.4.2',
  });

  final ProtocolInspectorController inspector;
  final String serialNumber;
  final List<int> macBytes;
  final String firmwareVersion;

  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>.broadcast();

  ConnectionState _state = ConnectionState.connected;
  String configuredSsid = 'DemoOfficeWiFi';
  String configuredPassword = '';
  int configuredMode = 0;
  List<String> configuredHosts = <String>['cprint-api.iprtapp.com:30501'];
  String deviceKey = 'sim-key-001';
  int _linkPolls = 0;
  int _staState = 0; // 0=disconnected, 1=wifiConnected, 2=cloudConnected
  int lastSetWifiPayloadLen = 0;

  @override
  String origin() => 'sim://esc-ble/$serialNumber';

  @override
  String? deviceName() => 'SimESC-$serialNumber';

  @override
  String? deviceMac() => macBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');

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
    if (_state != ConnectionState.connected || data.length < 4) return;
    if (data[0] == 0x10 && data[1] == 0xFF) {
      final cmd2 = data[2];
      final cmd3 = data[3];

      if (cmd2 == 0x31 && cmd3 == 0x02) {
        // ESetWifi: [10 FF 31 02][totalLenLE16][TLVs...]
        _handleSetWifi(data);
        return;
      }
      if (cmd2 == 0x31 && cmd3 == 0x06) {
        // ESetHost: [10 FF 31 06][hosts|...][00]
        final rawHosts = _decodeCString(data, 4);
        configuredHosts = rawHosts.isEmpty
            ? <String>[]
            : rawHosts.split('|').where((e) => e.isNotEmpty).toList();
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'ESetHost -> ${configuredHosts.join("|")}',
          textPreview: rawHosts,
        );
        _emitReply(utf8.encode('OK\r\n'), 'ESetHost ACK: OK');
        return;
      }
      if (cmd2 == 0x31 && cmd3 == 0x07) {
        // ESetKey: [10 FF 31 07][key][00]
        deviceKey = _decodeCString(data, 4);
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data.sublist(0, data.length.clamp(0, 4)),
          decodedSummary: 'ESetKey -> [REDACTED] (${deviceKey.length} chars)',
        );
        _emitReply(const <int>[0xAA], 'ESetKey ACK: 0xAA');
        return;
      }
      if (cmd2 == 0x20 && cmd3 == 0x00) {
        // EGetKey
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EGetKey',
        );
        _emitReply(
          utf8.encode('$deviceKey\r\n'),
          'EGetKey -> [REDACTED] (${deviceKey.length} chars)',
          logRawBytes: Uint8List.fromList(utf8.encode('[REDACTED]\r\n')),
        );
        return;
      }
      if (cmd2 == 0x31 && cmd3 == 0x01) {
        // EGetWifiSta
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EGetWifiSta',
        );
        if (_staState < 2 && configuredSsid.isNotEmpty) {
          _linkPolls++;
          _staState = _linkPolls >= 2 ? 2 : 1;
        }
        _emitReply(<int>[
          configuredMode & 0xFF,
          _staState & 0xFF,
        ], 'EGetWifiSta -> mode=$configuredMode, state=$_staState');
        return;
      }
      if (cmd2 == 0x31 && cmd3 == 0x03) {
        // EGetWifiName
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EGetWifiName',
        );
        _emitReply(
          utf8.encode('$configuredSsid\r\n'),
          'EGetWifiName -> $configuredSsid',
        );
        return;
      }
      if (cmd2 == 0x33 && cmd3 == 0x05) {
        // EResetNetworkInfo
        configuredSsid = '';
        configuredPassword = '';
        _staState = 0;
        _linkPolls = 0;
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EResetNetworkInfo',
        );
        _emitReply(const <int>[0x00], 'EResetNetworkInfo ACK: 0x00');
        return;
      }
      if (cmd2 == 0x20 && cmd3 == 0xF2) {
        // ESN
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'ESN',
        );
        _emitReply(
          utf8.encode('PRINTER_SN $serialNumber\r\n'),
          'ESN -> PRINTER_SN $serialNumber',
        );
        return;
      }
      if (cmd2 == 0x30 && cmd3 == 0x12) {
        // EMac
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EMac',
        );
        _emitReply(macBytes, 'EMac -> ${deviceMac()}');
        return;
      }
      if (cmd2 == 0x20 && cmd3 == 0xF1) {
        // EPrinterVersion
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'BLE ESC',
          direction: WireDirection.tx,
          rawBytes: data,
          decodedSummary: 'EPrinterVersion',
        );
        _emitReply(
          utf8.encode('$firmwareVersion\r\n'),
          'EPrinterVersion -> $firmwareVersion',
        );
        return;
      }
    }

    inspector.record(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'BLE ESC',
      direction: WireDirection.tx,
      rawBytes: data,
      decodedSummary: 'Raw ESC command (${data.length} B)',
    );
  }

  void _handleSetWifi(Uint8List data) {
    if (data.length >= 6) {
      final totalLen = (data[4] & 0xFF) | ((data[5] & 0xFF) << 8);
      lastSetWifiPayloadLen = totalLen;
      var pos = 6;
      final end = (6 + totalLen).clamp(6, data.length);
      while (pos + 3 <= end) {
        final tag = data[pos];
        final len = (data[pos + 1] & 0xFF) | ((data[pos + 2] & 0xFF) << 8);
        pos += 3;
        if (pos + len > end) break;
        final val = Uint8List.sublistView(data, pos, pos + len);
        pos += len;
        if (tag == 0x01) {
          configuredSsid = utf8.decode(val, allowMalformed: true);
        } else if (tag == 0x02) {
          configuredPassword = utf8.decode(val, allowMalformed: true);
        } else if (tag == 0x03 && val.isNotEmpty) {
          configuredMode = val[0];
        }
      }
    }
    _linkPolls = 0;
    _staState = 0;
    // Redact raw password bytes from logged frame preview
    inspector.record(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'BLE ESC',
      direction: WireDirection.tx,
      rawBytes: data.sublist(0, data.length.clamp(0, 6)),
      decodedSummary:
          'ESetWifi TLV(len=$lastSetWifiPayloadLen): ssid="$configuredSsid", '
          'password=[REDACTED (${configuredPassword.length} B)], mode=$configuredMode',
    );
    _emitReply(utf8.encode('OK\r\n'), 'ESetWifi ACK: OK');
  }

  String _decodeCString(Uint8List data, int start) {
    var end = data.length;
    for (var i = start; i < data.length; i++) {
      if (data[i] == 0) {
        end = i;
        break;
      }
    }
    if (end <= start) return '';
    return utf8.decode(Uint8List.sublistView(data, start, end));
  }

  void _emitReply(List<int> bytes, String summary, {Uint8List? logRawBytes}) {
    final frame = Uint8List.fromList(bytes);
    inspector.record(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'BLE ESC',
      direction: WireDirection.rx,
      rawBytes: logRawBytes ?? frame,
      decodedSummary: summary,
    );
    scheduleMicrotask(() {
      if (!_readController.isClosed && _state == ConnectionState.connected) {
        _readController.add(frame);
      }
    });
  }
}

enum SimCloudJobOutcome { success, failWithFault, stopPrintEvent }

/// In-memory HTTP REST + OSS Multipart + MQTT v5 broker backend for
/// `psdk_cloud_wan` Simulation Mode.
class SimCloudWanBackend {
  SimCloudWanBackend({
    required this.inspector,
    this.serialNumber = 'SIM-ESC-2026001',
    this.autoPublishJobProgression = true,
    this.jobStepDelay = const Duration(milliseconds: 25),
    this.pollInterval = const Duration(seconds: 5),
  });

  final ProtocolInspectorController inspector;
  final String serialNumber;
  final bool autoPublishJobProgression;
  final Duration jobStepDelay;
  final Duration pollInterval;

  String currentToken = 'Bearer sim_wan_tok_001';
  int activeFaultCode = 0; // 0, 6001, 6003, 6004, 6006, 6013
  bool simulateHttpPollFailure = false;
  String simulatedOnlineState = 'online';
  SimCloudJobOutcome nextJobOutcome = SimCloudJobOutcome.success;
  int _jobSeq = 1;
  int _serverPacketId = 1;
  int pollCount = 0;
  int ossUploadCount = 0;
  int lastUploadedBytes = 0;
  String? lastUploadedFileName;

  InMemorySocket? _activeMqttSocket;
  final List<int> _mqttRxBuffer = <int>[];
  final List<Timer> _pendingTimers = <Timer>[];

  CloudWanConfig createConfig({String? overrideSerialNumber}) {
    return CloudWanConfig.custom(
      apiBaseUrl: 'http://sim-cloud.local',
      mqttHost: 'sim-mqtt.local',
      mqttPort: 30501,
      mqttUseTls: false,
      serialNumber: overrideSerialNumber ?? serialNumber,
      pollInterval: pollInterval,
      maxPollFailures: 3,
      autoReconnectMqtt: false,
      httpClientFactory: () => InMemoryHttpClient(_handleHttpRequest),
      mqttSocketConnector: _connectMqttSocket,
    );
  }

  void injectFaultCode(int code) {
    activeFaultCode = code;
    publishCurrentStateOverMqtt();
  }

  void publishCurrentStateOverMqtt() {
    final sock = _activeMqttSocket;
    if (sock == null || sock.isClosed) return;
    final payload = jsonEncode(<String, dynamic>{
      'deviceId': serialNumber,
      'onlineState': simulatedOnlineState,
      'battery': activeFaultCode == 6004 ? 12 : 91,
      'charging': activeFaultCode != 6004,
      'paper': activeFaultCode == 6001 ? 0 : 88,
      'paperType': 'roll',
      'errCode': <int>[activeFaultCode],
      'firmware': const <Map<String, dynamic>>[
        <String, dynamic>{
          'firmwareType': 'printer',
          'firmwareVersion': '1.4.2',
        },
      ],
    });
    _pushMqttPublish('devices/$serialNumber/state', payload);
  }

  Future<InMemoryHttpReply> _handleHttpRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    Uint8List body,
  ) async {
    final path = uri.path;
    final bodyText = utf8.decode(body, allowMalformed: true);
    inspector.recordText(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'WAN HTTP',
      direction: WireDirection.tx,
      text:
          '$method $path ${body.length > 512 ? "(${body.length} B)" : bodyText}',
      decodedSummary: 'HTTP $method $path',
    );

    if (method == 'POST' && path == '/api/v1/cloud-print/device-token') {
      final reply = <String, dynamic>{
        'err': 0,
        'msg': '',
        'code': '',
        'data': <String, dynamic>{'token': currentToken},
      };
      _logHttpRx(path, 200, '{"err":0,"data":{"token":"[REDACTED]"}}');
      return InMemoryHttpReply.json(200, reply);
    }

    if (method == 'GET' && path == '/api/v1/public/device/info') {
      final sn = uri.queryParameters['sn'] ?? serialNumber;
      final reply = <String, dynamic>{
        'code': 0,
        'message': '',
        'data': <String, dynamic>{
          'id': 'dev_$sn',
          'printerSn': sn,
          'localName': 'CloudESC-$sn',
          'modelCode': 'ESC_CLOUD_P1',
          'onlineState': simulatedOnlineState,
          'protocolVersion': '0.1',
          'subscribeTopic': 'devices/$sn/#',
          'printMaxFileSize': 10485760,
        },
      };
      _logHttpRx(path, 200, jsonEncode(reply));
      return InMemoryHttpReply.json(200, reply);
    }

    if (method == 'GET' && path == '/api/v1/device-app/device/state') {
      pollCount++;
      if (simulateHttpPollFailure) {
        _logHttpRx(path, 503, '{"error":"simulated poll failure"}');
        return InMemoryHttpReply.json(503, <String, dynamic>{
          'code': 503,
          'message': 'Simulated HTTP polling outage',
        });
      }
      final reply = <String, dynamic>{
        'code': 0,
        'message': '',
        'data': <String, dynamic>{
          'deviceId': serialNumber,
          'onlineState': simulatedOnlineState,
          'battery': activeFaultCode == 6004 ? 12 : 91,
          'charging': activeFaultCode != 6004,
          'paper': activeFaultCode == 6001 ? 0 : 88,
          'paperType': 'roll',
          'errCode': <int>[activeFaultCode],
          'firmware': const <Map<String, dynamic>>[
            <String, dynamic>{
              'firmwareType': 'printer',
              'firmwareVersion': '1.4.2',
            },
          ],
        },
      };
      _logHttpRx(path, 200, jsonEncode(reply));
      return InMemoryHttpReply.json(200, reply);
    }

    if (method == 'POST' && path == '/api/v1/device-app/files/upload-token') {
      final json = jsonDecode(bodyText) as Map<String, dynamic>;
      final reqFiles = (json['files'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final tokenFiles = <Map<String, dynamic>>[];
      for (var i = 0; i < reqFiles.length; i++) {
        final f = reqFiles[i];
        tokenFiles.add(<String, dynamic>{
          'fileId': 'sim_file_${_jobSeq}_$i',
          'filename': f['fileName'],
          'objectKey': 'print/${f['fileName']}',
          'uploadUrl': 'http://sim-oss.local/oss-upload',
          'isExist': false,
          'postData': <String, dynamic>{
            'key': 'print/${f['fileName']}',
            'policy': 'sim_policy',
            'signature': 'sim_sig',
          },
        });
      }
      final reply = <String, dynamic>{
        'code': 0,
        'message': '',
        'data': <String, dynamic>{'expiresIn': 600, 'files': tokenFiles},
      };
      _logHttpRx(path, 200, jsonEncode(reply));
      return InMemoryHttpReply.json(200, reply);
    }

    if (method == 'POST' && path == '/oss-upload') {
      ossUploadCount++;
      lastUploadedBytes = body.length;
      final nameMatch = RegExp(r'filename="([^"]+)"').firstMatch(bodyText);
      lastUploadedFileName = nameMatch?.group(1) ?? 'job.prn';
      _logHttpRx(
        path,
        200,
        'OSS multipart uploaded (${body.length} B, file=$lastUploadedFileName)',
      );
      return InMemoryHttpReply(statusCode: 200);
    }

    if (method == 'POST' && path == '/api/v1/device-app/print-jobs') {
      final jobId = 'wan_job_${_jobSeq++}';
      final reply = <String, dynamic>{
        'code': 0,
        'message': '',
        'data': <String, dynamic>{'id': jobId},
      };
      _logHttpRx(path, 200, jsonEncode(reply));
      if (autoPublishJobProgression) {
        _scheduleJobProgression(jobId);
      }
      return InMemoryHttpReply.json(200, reply);
    }

    _logHttpRx(path, 404, '{"error":"not found"}');
    return InMemoryHttpReply.json(404, <String, dynamic>{'error': 'Not found'});
  }

  void _logHttpRx(String path, int status, String summary) {
    inspector.recordText(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'WAN HTTP',
      direction: WireDirection.rx,
      text: '$status $path -> $summary',
      decodedSummary: 'HTTP $status $path',
    );
  }

  Future<Socket> _connectMqttSocket(
    String host,
    int port, {
    bool useTls = false,
    Duration timeout = const Duration(seconds: 8),
    bool Function(X509Certificate cert)? onBadCertificate,
  }) async {
    _mqttRxBuffer.clear();
    late final InMemorySocket socket;
    socket = InMemorySocket(
      address: InternetAddress.loopbackIPv4,
      port: 43001,
      remoteAddress: InternetAddress.loopbackIPv4,
      remotePort: port,
      onWrite: (bytes) => _onMqttClientWrite(socket, bytes),
      onClose: () async {
        if (identical(_activeMqttSocket, socket)) {
          _activeMqttSocket = null;
        }
      },
    );
    _activeMqttSocket = socket;
    return socket;
  }

  void _onMqttClientWrite(InMemorySocket socket, Uint8List chunk) {
    _mqttRxBuffer.addAll(chunk);
    while (true) {
      final consumed = MqttV5PacketCodec.tryReadPacket(_mqttRxBuffer);
      if (consumed == null) break;
      final rawPacket = Uint8List.fromList(
        _mqttRxBuffer.sublist(0, consumed.bytesConsumed),
      );
      _mqttRxBuffer.removeRange(0, consumed.bytesConsumed);
      _handleMqttPacket(socket, consumed.packet, rawPacket);
    }
  }

  void _handleMqttPacket(
    InMemorySocket socket,
    MqttV5RawPacket packet,
    Uint8List rawBytes,
  ) {
    switch (packet.type) {
      case MqttV5PacketTypes.connect:
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.tx,
          // Log fixed/protocol header only; omit username/password/token payload bytes.
          rawBytes: rawBytes.sublist(0, rawBytes.length.clamp(0, 10)),
          decodedSummary: 'MQTT CONNECT (sn=$serialNumber, token=[REDACTED])',
        );
        final connack = Uint8List.fromList(const <int>[
          0x20,
          0x03,
          0x00,
          0x00,
          0x00,
        ]);
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.rx,
          rawBytes: connack,
          decodedSummary: 'MQTT CONNACK (reasonCode=0)',
        );
        socket.pushIncoming(connack);
        break;
      case MqttV5PacketTypes.subscribe:
        final body = packet.body;
        final packetId = ((body[0] & 0xFF) << 8) | (body[1] & 0xFF);
        final props = MqttV5PacketCodec.parseProperties(body, 2);
        final topicRes = MqttV5PacketCodec.decodeUtf8String(
          body,
          props.nextOffset,
        );
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.tx,
          rawBytes: rawBytes,
          decodedSummary: 'MQTT SUBSCRIBE "${topicRes.value}" (id=$packetId)',
        );
        final suback = Uint8List.fromList(<int>[
          0x90,
          0x04,
          (packetId >> 8) & 0xFF,
          packetId & 0xFF,
          0x00,
          0x01,
        ]);
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.rx,
          rawBytes: suback,
          decodedSummary: 'MQTT SUBACK (id=$packetId, QoS=1)',
        );
        socket.pushIncoming(suback);
        break;
      case MqttV5PacketTypes.puback:
        final ack = MqttV5PacketCodec.decodePuback(packet);
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.tx,
          rawBytes: rawBytes,
          decodedSummary: 'MQTT PUBACK (id=${ack.packetId})',
        );
        break;
      case MqttV5PacketTypes.pingreq:
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.tx,
          rawBytes: rawBytes,
          decodedSummary: 'MQTT PINGREQ',
        );
        final pingresp = MqttV5PacketCodec.encodePingresp();
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.rx,
          rawBytes: pingresp,
          decodedSummary: 'MQTT PINGRESP',
        );
        socket.pushIncoming(pingresp);
        break;
      case MqttV5PacketTypes.disconnect:
        inspector.record(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'MQTT v5',
          direction: WireDirection.tx,
          rawBytes: rawBytes,
          decodedSummary: 'MQTT DISCONNECT',
        );
        break;
      default:
        break;
    }
  }

  void _scheduleJobProgression(String jobId) {
    final outcome = nextJobOutcome;
    _scheduleAfter(jobStepDelay, () {
      _pushMqttPublish(
        'devices/$serialNumber/print',
        jsonEncode(<String, dynamic>{
          'jobId': jobId,
          'status': 'confirm',
          'page': 0,
          'message': 'Printer confirmed WAN job',
        }),
      );
    });

    if (outcome == SimCloudJobOutcome.stopPrintEvent) {
      _scheduleAfter(jobStepDelay * 2, () {
        _pushMqttPublish(
          'devices/$serialNumber/event',
          jsonEncode(<String, dynamic>{
            'eventType': 'stop_print',
            'jobId': jobId,
            'message': 'Operator pressed cancel on printer',
          }),
        );
      });
      return;
    }

    _scheduleAfter(jobStepDelay * 2, () {
      _pushMqttPublish(
        'devices/$serialNumber/print',
        jsonEncode(<String, dynamic>{
          'jobId': jobId,
          'status': 'printing',
          'page': 1,
          'message': 'Pulling & printing from OSS',
        }),
      );
    });

    _scheduleAfter(jobStepDelay * 3, () {
      if (outcome == SimCloudJobOutcome.failWithFault) {
        final code = activeFaultCode == 0 ? 6001 : activeFaultCode;
        _pushMqttPublish(
          'devices/$serialNumber/print',
          jsonEncode(<String, dynamic>{
            'jobId': jobId,
            'status': 'failed',
            'page': 1,
            'errCode': <int>[code],
            'message': 'Remote printer fault $code',
          }),
        );
      } else {
        _pushMqttPublish(
          'devices/$serialNumber/print',
          jsonEncode(<String, dynamic>{
            'jobId': jobId,
            'status': 'success',
            'page': 1,
            'message': 'Cloud print complete',
          }),
        );
      }
    });
  }

  void _scheduleAfter(Duration delay, void Function() fn) {
    late final Timer timer;
    timer = Timer(delay, () {
      _pendingTimers.remove(timer);
      fn();
    });
    _pendingTimers.add(timer);
  }

  void _pushMqttPublish(String topic, String jsonPayload) {
    final sock = _activeMqttSocket;
    if (sock == null || sock.isClosed) return;
    final packetId = _serverPacketId++;
    final body = BytesBuilder(copy: false)
      ..add(MqttV5PacketCodec.encodeUtf8String(topic))
      ..addByte((packetId >> 8) & 0xFF)
      ..addByte(packetId & 0xFF)
      ..addByte(0x00)
      ..add(utf8.encode(jsonPayload));
    final bodyBytes = body.takeBytes();
    final remLen = MqttV5PacketCodec.encodeVbi(bodyBytes.length);
    final packet = Uint8List.fromList(<int>[
      ((MqttV5PacketTypes.publish << 4) | 0x02) & 0xFF,
      ...remLen,
      ...bodyBytes,
    ]);
    inspector.record(
      family: CloudPrinterFamily.escWanCloud,
      transport: 'MQTT v5',
      direction: WireDirection.rx,
      rawBytes: packet,
      decodedSummary: 'MQTT PUBLISH "$topic" -> $jsonPayload',
      textPreview: jsonPayload,
    );
    sock.pushIncoming(packet);
  }

  void dispose() {
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _pendingTimers.clear();
    _activeMqttSocket?.closeFromRemote();
    _activeMqttSocket = null;
  }
}
