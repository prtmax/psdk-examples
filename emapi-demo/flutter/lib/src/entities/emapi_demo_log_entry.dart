import 'dart:typed_data';

class EmapiDemoLogEntry {
  const EmapiDemoLogEntry({
    required this.title,
    required this.message,
    this.bytes,
  });

  final String title;
  final String message;
  final Uint8List? bytes;
}
