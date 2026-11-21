import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

enum WireDirection { tx, rx }

class ProtocolTrafficEntry {
  final int id;
  final DateTime timestamp;
  final CloudPrinterFamily family;
  final String transport;
  final WireDirection direction;
  final Uint8List rawBytes;
  final String decodedSummary;
  final String? textPreview;

  ProtocolTrafficEntry({
    required this.id,
    required this.family,
    required this.transport,
    required this.direction,
    required Uint8List rawBytes,
    required String decodedSummary,
    String? textPreview,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc(),
       rawBytes = Uint8List.fromList(rawBytes),
       decodedSummary = ProtocolInspectorController.redactSecrets(
         decodedSummary,
       ),
       textPreview = textPreview == null
           ? null
           : ProtocolInspectorController.redactSecrets(textPreview);

  String get hexPreview {
    if (rawBytes.isEmpty) {
      return '(0 B)';
    }
    const maxBytes = 64;
    final limit = rawBytes.length > maxBytes ? maxBytes : rawBytes.length;
    final hex = rawBytes
        .sublist(0, limit)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    return rawBytes.length > maxBytes
        ? '$hex ... (${rawBytes.length} B total)'
        : hex;
  }

  String get formattedTimestamp {
    final t = timestamp.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }

  String toExportLine() {
    final dir = direction == WireDirection.tx ? 'TX' : 'RX';
    final buf = StringBuffer()
      ..writeln(
        '[$formattedTimestamp] [${family.name}] [$transport] $dir '
        '(${rawBytes.length} B) $decodedSummary',
      )
      ..writeln('  HEX: $hexPreview');
    if (textPreview != null && textPreview!.isNotEmpty) {
      buf.writeln('  TXT: $textPreview');
    }
    return buf.toString();
  }
}

class ProtocolInspectorController extends ChangeNotifier {
  ProtocolInspectorController({this.maxEntries = 300});

  final int maxEntries;
  final List<ProtocolTrafficEntry> _entries = <ProtocolTrafficEntry>[];
  int _nextId = 1;
  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<ProtocolTrafficEntry> get entries =>
      List<ProtocolTrafficEntry>.unmodifiable(_entries);

  int get count => _entries.length;

  void record({
    required CloudPrinterFamily family,
    required String transport,
    required WireDirection direction,
    required Uint8List rawBytes,
    required String decodedSummary,
    String? textPreview,
  }) {
    _entries.add(
      ProtocolTrafficEntry(
        id: _nextId++,
        family: family,
        transport: transport,
        direction: direction,
        rawBytes: rawBytes,
        decodedSummary: decodedSummary,
        textPreview: textPreview,
      ),
    );
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    _notifyIfAlive();
  }

  void recordText({
    required CloudPrinterFamily family,
    required String transport,
    required WireDirection direction,
    required String text,
    required String decodedSummary,
  }) {
    final redacted = redactSecrets(text);
    record(
      family: family,
      transport: transport,
      direction: direction,
      rawBytes: Uint8List.fromList(utf8.encode(redacted)),
      decodedSummary: decodedSummary,
      textPreview: redacted.trimRight(),
    );
  }

  List<ProtocolTrafficEntry> filtered({
    CloudPrinterFamily? family,
    WireDirection? direction,
  }) {
    return _entries
        .where((e) {
          if (family != null && e.family != family) return false;
          if (direction != null && e.direction != direction) return false;
          return true;
        })
        .toList(growable: false);
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    _notifyIfAlive();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String exportAll({CloudPrinterFamily? family, WireDirection? direction}) {
    final list = filtered(family: family, direction: direction);
    return list.map((e) => e.toExportLine()).join('\n');
  }

  /// Redacts Wi-Fi / ACL / AT / WLAN / JSON credentials before storing or rendering.
  static String redactSecrets(String raw) {
    var out = raw;
    // NET BROADCAST password field: WIFI PASSWORD:secret
    out = out.replaceAllMapped(
      RegExp(r'(WIFI\s*PASSWORD\s*:\s*)([^,\r\n]*)', caseSensitive: false),
      (m) => '${m.group(1)}[REDACTED]',
    );
    // AT SETSSID: BLUETOOTH SETSSID,ssid,password
    out = out.replaceAllMapped(
      RegExp(
        r'(BLUETOOTH\s+SETSSID\s*,\s*[^,\r\n]+\s*,\s*)([^\r\n]+)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}[REDACTED]',
    );
    // AT GETPASSWORD reply
    out = out.replaceAllMapped(
      RegExp(
        r'(BLUETOOTH\s+GETPASSWORD\s*(?:->|:|=)\s*)([^\r\n]+)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}[REDACTED]',
    );
    // TSPL WLAN PWD "secret" or WLAN LAP ssid,pwd,ip
    out = out.replaceAllMapped(
      RegExp(r'(WLAN\s+PWD\s+)"([^"]*)"', caseSensitive: false),
      (m) => '${m.group(1)}"[REDACTED]"',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'(WLAN\s+LAP\s+[^,\r\n]+,\s*)([^,\r\n]+)(\s*,)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}[REDACTED]${m.group(3)}',
    );
    // PJL XSL WIFI STA/SAP CFG="ssid","pwd"
    out = out.replaceAllMapped(
      RegExp(
        r'(WIFI\s+(?:STA|SAP)\s+CFG\s*=\s*"[^"]*"\s*,\s*)"([^"]*)"',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}"[REDACTED]"',
    );
    // Generic JSON / quoted key-value pairs (e.g. {"deviceToken":"...","token":"Bearer ..."})
    out = out.replaceAllMapped(
      RegExp(
        r'("?\b(?:password|passwd|pwd|deviceToken|token)\b"?\s*[:=]\s*)"([^"\r\n]*)"',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}"[REDACTED]"',
    );
    // Generic unquoted password=... / pwd=... / deviceToken=... / token=... key-value pairs
    out = out.replaceAllMapped(
      RegExp(
        r'("?\b(?:password|passwd|pwd|deviceToken|token)\b"?\s*[:=]\s*)([^",\r\n\s\}]+)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}[REDACTED]',
    );
    return out;
  }
}
