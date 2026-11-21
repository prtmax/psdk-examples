import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../models/protocol_inspector.dart';

/// The cloud driver supplies these factories for its HTTP and MQTT traffic.
/// Keep bodies, headers and URL parameters out of the inspector.
class InspectedWan {
  InspectedWan(this.inspector);
  final ProtocolInspectorController inspector;

  void _record(String transport, WireDirection direction, String summary) {
    inspector.record(
      family: CloudPrinterFamily.escWanCloud,
      transport: transport,
      direction: direction,
      rawBytes: Uint8List(0),
      decodedSummary: summary,
    );
  }

  HttpClient createHttpClient() => _HttpClient(HttpClient(), this);

  Future<Socket> connectMqtt(
    String host,
    int port, {
    bool useTls = true,
    Duration timeout = const Duration(seconds: 8),
    bool Function(X509Certificate cert)? onBadCertificate,
  }) async {
    final socket = useTls
        ? await SecureSocket.connect(
            host,
            port,
            timeout: timeout,
            onBadCertificate: onBadCertificate,
          )
        : await Socket.connect(host, port, timeout: timeout);
    return _MqttSocket(socket, this);
  }
}

// The SDK uses openUrl for its API and postUrl for object uploads. Pass the
// original request/response streams through so uploads and timeouts stay native.
class _HttpClient implements HttpClient {
  _HttpClient(this.inner, this.wan);
  final HttpClient inner;
  final InspectedWan wan;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await inner.openUrl(method, url);
    wan._record('HTTP', WireDirection.tx, method);
    unawaited(
      request.done.then<void>(
        (response) {
          wan._record(
            'HTTP',
            WireDirection.rx,
            '$method HTTP ${response.statusCode}',
          );
        },
        onError: (Object _, StackTrace _) {
          wan._record('HTTP', WireDirection.rx, '$method failed');
        },
      ),
    );
    return request;
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  void close({bool force = false}) => inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MqttSocket extends Stream<Uint8List> implements Socket {
  _MqttSocket(this.inner, this.wan);
  final Socket inner;
  final InspectedWan wan;

  @override
  void add(List<int> bytes) {
    inner.add(bytes);
    wan._record('MQTT', WireDirection.tx, '${bytes.length} B');
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => inner
      .map((chunk) {
        wan._record('MQTT', WireDirection.rx, '${chunk.length} B');
        return chunk;
      })
      .listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  Future<void> flush() => inner.flush();
  @override
  Future<void> close() => inner.close();
  @override
  Future<void> get done => inner.done;
  @override
  void destroy() => inner.destroy();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
