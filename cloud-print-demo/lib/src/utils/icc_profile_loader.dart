import 'package:flutter/services.dart';

class IccProfileLoader {
  IccProfileLoader._();

  static const String h100Chart = 'assets/icc/h100-chart.icc';
  static const String z11D380 = 'assets/icc/z11-d380.icc';

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static Future<Uint8List> load(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _cache[assetPath] = bytes;
    return bytes;
  }
}
