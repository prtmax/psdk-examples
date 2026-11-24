import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class InMemoryHttpReply {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  InMemoryHttpReply({
    required this.statusCode,
    this.headers = const <String, String>{},
    Uint8List? bodyBytes,
  }) : bodyBytes = bodyBytes ?? Uint8List(0);

  factory InMemoryHttpReply.json(int statusCode, Map<String, dynamic> body) {
    return InMemoryHttpReply(
      statusCode: statusCode,
      headers: const <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      },
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(body))),
    );
  }
}

typedef InMemoryHttpHandler =
    Future<InMemoryHttpReply> Function(
      String method,
      Uri uri,
      Map<String, String> headers,
      Uint8List body,
    );

/// In-memory [HttpClient] implementation avoiding OS socket binds and
/// `TestWidgetsFlutterBinding` `HttpOverrides` interference.
class InMemoryHttpClient implements HttpClient {
  InMemoryHttpClient(this._handler);

  final InMemoryHttpHandler _handler;
  bool _closed = false;

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void close({bool force = false}) {
    _closed = true;
  }

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    return openUrl(
      method,
      Uri(scheme: 'http', host: host, port: port, path: path),
    );
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (_closed) {
      throw StateError('HttpClient is closed');
    }
    return _InMemoryHttpClientRequest(method.toUpperCase(), url, _handler);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
}

class _InMemoryHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  Map<String, String> toSingleValueMap() {
    final out = <String, String>{};
    _values.forEach((k, v) {
      if (v.isNotEmpty) {
        out[k] = v.join(', ');
      }
    });
    return out;
  }

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = true;

  @override
  int? port;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _values.putIfAbsent(key, () => <String>[]).add(value.toString());
    if (key == HttpHeaders.contentTypeHeader) {
      contentType = ContentType.parse(value.toString());
    }
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {
    _values[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _values.remove(name.toLowerCase());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = name.toLowerCase();
    _values[key] = <String>[value.toString()];
    if (key == HttpHeaders.contentTypeHeader) {
      contentType = ContentType.parse(value.toString());
    }
  }

  @override
  String? value(String name) {
    final list = _values[name.toLowerCase()];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }
}

class _InMemoryHttpClientRequest implements HttpClientRequest {
  _InMemoryHttpClientRequest(this.method, this.uri, this._handler);

  @override
  final String method;

  @override
  final Uri uri;

  final InMemoryHttpHandler _handler;
  final _InMemoryHttpHeaders _headers = _InMemoryHttpHeaders();
  final BytesBuilder _body = BytesBuilder(copy: false);
  final Completer<HttpClientResponse> _doneCompleter =
      Completer<HttpClientResponse>();
  bool _closed = false;

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  Encoding encoding = utf8;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<HttpClientResponse> get done => _doneCompleter.future;

  @override
  HttpHeaders get headers => _headers;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.completeError(
        exception ?? const HttpException('Aborted'),
        stackTrace,
      );
    }
  }

  @override
  void add(List<int> data) {
    if (!_closed) {
      _body.add(data);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    if (_closed && _doneCompleter.isCompleted) {
      return _doneCompleter.future;
    }
    _closed = true;
    try {
      final reply = await _handler(
        method,
        uri,
        _headers.toSingleValueMap(),
        _body.takeBytes(),
      );
      final resp = _InMemoryHttpClientResponse(reply);
      if (!_doneCompleter.isCompleted) {
        _doneCompleter.complete(resp);
      }
      return resp;
    } catch (e, st) {
      if (!_doneCompleter.isCompleted) {
        _doneCompleter.completeError(e, st);
      }
      rethrow;
    }
  }

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {
    if (object != null) {
      add(encoding.encode(object.toString()));
    }
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode & 0xFF]);
  }

  @override
  void writeln([Object? object = '']) {
    write('${object ?? ''}\n');
  }
}

class _InMemoryHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _InMemoryHttpClientResponse(this._reply) {
    _reply.headers.forEach((k, v) => _headers.set(k, v));
    _headers.contentLength = _reply.bodyBytes.length;
  }

  final InMemoryHttpReply _reply;
  final _InMemoryHttpHeaders _headers = _InMemoryHttpHeaders();

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => _reply.bodyBytes.length;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<Socket> detachSocket() async {
    throw UnsupportedError('detachSocket not supported in InMemoryHttpClient');
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => '';

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) async {
    return this;
  }

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  int get statusCode => _reply.statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = _reply.bodyBytes.isEmpty
        ? const Stream<List<int>>.empty()
        : Stream<List<int>>.value(_reply.bodyBytes);
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

/// In-memory [Socket] pair bridging a client and server handler without OS ports.
class InMemorySocket extends Stream<Uint8List> implements Socket {
  InMemorySocket({
    required this.address,
    required this.port,
    required this.remoteAddress,
    required this.remotePort,
    required void Function(Uint8List bytes) onWrite,
    Future<void> Function()? onClose,
  }) : _onWrite = onWrite,
       _onClose = onClose;

  @override
  final InternetAddress address;

  @override
  final int port;

  @override
  final InternetAddress remoteAddress;

  @override
  final int remotePort;

  final void Function(Uint8List bytes) _onWrite;
  final Future<void> Function()? _onClose;

  final StreamController<Uint8List> _rxController =
      StreamController<Uint8List>.broadcast();
  final Completer<void> _doneCompleter = Completer<void>();
  bool _closed = false;

  @override
  Encoding encoding = utf8;

  bool get isClosed => _closed;

  void pushIncoming(Uint8List bytes) {
    if (!_closed && !_rxController.isClosed) {
      _rxController.add(Uint8List.fromList(bytes));
    }
  }

  void closeFromRemote() {
    if (_closed) return;
    _closed = true;
    if (!_rxController.isClosed) {
      _rxController.close();
    }
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _rxController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void add(List<int> data) {
    if (_closed || data.isEmpty) return;
    _onWrite(Uint8List.fromList(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _onClose?.call();
    if (!_rxController.isClosed) {
      await _rxController.close();
    }
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  void destroy() {
    unawaited(close());
  }

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  Future<void> flush() async {}

  @override
  Uint8List getRawOption(RawSocketOption option) => Uint8List(0);

  @override
  void setRawOption(RawSocketOption option) {}

  @override
  bool setOption(SocketOption option, bool enabled) => true;

  @override
  void write(Object? object) {
    if (object != null) {
      add(encoding.encode(object.toString()));
    }
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode & 0xFF]);
  }

  @override
  void writeln([Object? object = '']) {
    write('${object ?? ''}\n');
  }
}

/// In-memory [RawDatagramSocket] for `Network.scoped(udpSocketBinder: ...)`
/// without binding OS UDP ports.
class InMemoryRawDatagramSocket extends Stream<RawSocketEvent>
    implements RawDatagramSocket {
  InMemoryRawDatagramSocket({
    required this.address,
    required this.port,
    required void Function(
      Uint8List data,
      InternetAddress target,
      int targetPort,
      InMemoryRawDatagramSocket socket,
    )
    onSend,
  }) : _onSend = onSend;

  @override
  final InternetAddress address;

  @override
  final int port;

  final void Function(
    Uint8List data,
    InternetAddress target,
    int targetPort,
    InMemoryRawDatagramSocket socket,
  )
  _onSend;

  final StreamController<RawSocketEvent> _events =
      StreamController<RawSocketEvent>.broadcast();
  final List<Datagram> _inbox = <Datagram>[];
  bool _closed = false;

  @override
  bool broadcastEnabled = true;

  @override
  int multicastHops = 1;

  @override
  bool multicastLoopback = false;

  @override
  NetworkInterface? multicastInterface;

  @override
  bool readEventsEnabled = true;

  @override
  bool writeEventsEnabled = false;

  void enqueueDatagram(Datagram datagram) {
    if (_closed || _events.isClosed) return;
    _inbox.add(datagram);
    if (readEventsEnabled) {
      _events.add(RawSocketEvent.read);
    }
  }

  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _events.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Datagram? receive() {
    if (_inbox.isEmpty) return null;
    return _inbox.removeAt(0);
  }

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    if (_closed) return 0;
    final bytes = Uint8List.fromList(buffer);
    _onSend(bytes, address, port, this);
    return bytes.length;
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _events.close();
  }

  @override
  Uint8List getRawOption(RawSocketOption option) => Uint8List(0);

  @override
  void setRawOption(RawSocketOption option) {}

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) {}

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) {}
}
