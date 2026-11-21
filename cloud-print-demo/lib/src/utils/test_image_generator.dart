import 'dart:typed_data';

/// Pure-Dart RGBA raster pattern generator for offline demos and tests.
final class TestImageGenerator {
  const TestImageGenerator._();

  /// Generates an opaque RGBA8888 test card image for sublimation printing.
  ///
  /// Defaults to compact `96x64` for snappy UI/test responsiveness while still
  /// exercising full `Y/M/C/O/K` plane encoding, `1B 44` headers, and LZO1X.
  static Uint8List generateSublimationCardRgba({
    int width = 96,
    int height = 64,
    int variant = 0,
  }) {
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        int r;
        int g;
        int b;

        // Top color header bar
        if (y < height ~/ 4) {
          final band = (x * 4) ~/ width;
          switch ((band + variant) % 4) {
            case 0:
              r = 37;
              g = 107;
              b = 117;
              break;
            case 1:
              r = 212;
              g = 85;
              b = 64;
              break;
            case 2:
              r = 230;
              g = 175;
              b = 46;
              break;
            default:
              r = 58;
              g = 140;
              b = 110;
              break;
          }
        } else if (x >= 8 &&
            x < 32 &&
            y >= (height ~/ 4) + 6 &&
            y < height - 8) {
          // Badge photo block gradient
          r = ((x * 255) ~/ width).clamp(20, 240);
          g = ((y * 255) ~/ height).clamp(30, 220);
          b = 200 - (((x + y) * 120) ~/ (width + height));
        } else if (x >= 40 &&
            x < width - 8 &&
            ((y >= (height ~/ 2) - 4 && y <= (height ~/ 2) - 2) ||
                (y >= (height ~/ 2) + 4 && y <= (height ~/ 2) + 6) ||
                (y >= (height ~/ 2) + 12 &&
                    y <= (height ~/ 2) + 14 &&
                    (x % 6) < 4))) {
          // Crisp dark bars / barcode-like lines for K plane & fontBeautify
          r = 12;
          g = 12;
          b = 12;
        } else {
          r = 248;
          g = 249;
          b = 247;
        }

        rgba[offset] = r;
        rgba[offset + 1] = g;
        rgba[offset + 2] = b;
        rgba[offset + 3] = 255;
      }
    }
    return rgba;
  }

  /// Generates an opaque RGBA8888 K-only overlay mask (vertical bars + border).
  static Uint8List generateSublimationOverlayMaskRgba({
    int width = 96,
    int height = 64,
  }) {
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        final isBorder = x < 2 || x >= width - 2 || y < 2 || y >= height - 2;
        final isStripe =
            y > height ~/ 2 && y < height - 10 && x > 40 && (x % 8) < 2;
        final v = (isBorder || isStripe) ? 0 : 255;
        rgba[offset] = v;
        rgba[offset + 1] = v;
        rgba[offset + 2] = v;
        rgba[offset + 3] = 255;
      }
    }
    return rgba;
  }

  /// Generates an opaque RGBA8888 inkjet test page with CMYK swatches and page index.
  static Uint8List generateInkjetPageRgba({
    int width = 128,
    int height = 160,
    int pageNumber = 1,
  }) {
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        int r = 255;
        int g = 255;
        int b = 255;

        if (y < 16) {
          // Header strip varied by pageNumber
          switch ((pageNumber - 1) % 3) {
            case 0:
              r = 37;
              g = 107;
              b = 117;
              break;
            case 1:
              r = 180;
              g = 71;
              b = 61;
              break;
            default:
              r = 64;
              g = 115;
              b = 78;
              break;
          }
        } else if (y >= 24 && y < 56) {
          // C M Y K calibration blocks
          final q = (x * 4) ~/ width;
          if (q == 0) {
            r = 0;
            g = 180;
            b = 235;
          } else if (q == 1) {
            r = 225;
            g = 40;
            b = 140;
          } else if (q == 2) {
            r = 245;
            g = 210;
            b = 20;
          } else {
            r = 20;
            g = 20;
            b = 20;
          }
        } else if (y >= 68 &&
            y < height - 16 &&
            x >= 12 &&
            x < width - 12 &&
            (y % 12) < 3) {
          // Horizontal text-like lines + page marker notch
          final isMarker =
              pageNumber > 1 && x > width - 24 && y < 68 + pageNumber * 12;
          r = isMarker ? 37 : 25;
          g = isMarker ? 107 : 25;
          b = isMarker ? 117 : 25;
        }

        rgba[offset] = r;
        rgba[offset + 1] = g;
        rgba[offset + 2] = b;
        rgba[offset + 3] = 255;
      }
    }
    return rgba;
  }
}
