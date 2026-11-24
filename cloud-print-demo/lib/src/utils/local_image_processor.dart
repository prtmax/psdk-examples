import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:psdk_frame_father/father/command/print/commander.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_fruit_tspl/psdk_fruit_tspl.dart';

/// 纯 Dart 图片缩放、旋转、白底去透明与各打印协议载荷构造器（零 Flutter/UI 依赖，可安全在 Isolate 内执行）。
final class LocalImageProcessor {
  const LocalImageProcessor._();

  static Uint8List flattenAlphaOnWhite(Uint8List rgba) {
    final out = Uint8List.fromList(rgba);
    for (var i = 0; i + 3 < out.length; i += 4) {
      final a = out[i + 3];
      if (a == 255) continue;
      if (a == 0) {
        out[i] = 255;
        out[i + 1] = 255;
        out[i + 2] = 255;
        out[i + 3] = 255;
      } else {
        final inv = 255 - a;
        out[i] = ((out[i] * a + 255 * inv) + 127) ~/ 255;
        out[i + 1] = ((out[i + 1] * a + 255 * inv) + 127) ~/ 255;
        out[i + 2] = ((out[i + 2] * a + 255 * inv) + 127) ~/ 255;
        out[i + 3] = 255;
      }
    }
    return out;
  }

  static ({int width, int height, Uint8List rgbaBytes}) rotate90Cw(
    Uint8List rgba,
    int width,
    int height,
  ) {
    if (width <= 0 || height <= 0 || rgba.length != width * height * 4) {
      throw ArgumentError('Invalid RGBA buffer for rotate90Cw');
    }
    final newW = height;
    final newH = width;
    final out = Uint8List(newW * newH * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final srcIdx = (y * width + x) * 4;
        final dstX = height - 1 - y;
        final dstY = x;
        final dstIdx = (dstY * newW + dstX) * 4;
        out[dstIdx] = rgba[srcIdx];
        out[dstIdx + 1] = rgba[srcIdx + 1];
        out[dstIdx + 2] = rgba[srcIdx + 2];
        out[dstIdx + 3] = rgba[srcIdx + 3];
      }
    }
    return (width: newW, height: newH, rgbaBytes: out);
  }

  static Uint8List fitRgbaToCanvas({
    required Uint8List srcRgba,
    required int srcWidth,
    required int srcHeight,
    required int targetWidth,
    required int targetHeight,
    bool cover = false,
    bool autoRotateToMatchOrientation = false,
  }) {
    if (srcWidth <= 0 ||
        srcHeight <= 0 ||
        targetWidth <= 0 ||
        targetHeight <= 0 ||
        srcRgba.length != srcWidth * srcHeight * 4) {
      throw ArgumentError('Invalid dimensions for fitRgbaToCanvas');
    }

    var workW = srcWidth;
    var workH = srcHeight;
    var workRgba = flattenAlphaOnWhite(srcRgba);
    if (autoRotateToMatchOrientation &&
        workW != workH &&
        targetWidth != targetHeight &&
        (workW > workH) != (targetWidth > targetHeight)) {
      final rotated = rotate90Cw(workRgba, workW, workH);
      workW = rotated.width;
      workH = rotated.height;
      workRgba = rotated.rgbaBytes;
    }

    final out = Uint8List(targetWidth * targetHeight * 4);
    out.fillRange(0, out.length, 255);

    if (cover) {
      final scale = math.max(targetWidth / workW, targetHeight / workH);
      final scaledW = workW * scale;
      final scaledH = workH * scale;
      final originX = (targetWidth - scaledW) * 0.5;
      final originY = (targetHeight - scaledH) * 0.5;
      _resampleBilinear(
        src: workRgba,
        srcW: workW,
        srcH: workH,
        dst: out,
        dstW: targetWidth,
        dstXStart: 0,
        dstYStart: 0,
        dstRectW: targetWidth,
        dstRectH: targetHeight,
        sampleOffsetX: -originX / scale,
        sampleOffsetY: -originY / scale,
        invScale: 1.0 / scale,
      );
      return out;
    }

    final scale = math.min(targetWidth / workW, targetHeight / workH);
    final drawW = (workW * scale).round().clamp(1, targetWidth);
    final drawH = (workH * scale).round().clamp(1, targetHeight);
    final offsetX = (targetWidth - drawW) ~/ 2;
    final offsetY = (targetHeight - drawH) ~/ 2;
    _resampleBilinear(
      src: workRgba,
      srcW: workW,
      srcH: workH,
      dst: out,
      dstW: targetWidth,
      dstXStart: offsetX,
      dstYStart: offsetY,
      dstRectW: drawW,
      dstRectH: drawH,
      sampleOffsetX: 0,
      sampleOffsetY: 0,
      invScale: workW / drawW,
      invScaleY: workH / drawH,
    );
    return out;
  }

  static ({int width, int height, Uint8List rgbaBytes}) scaleRgbaToMaxWidth({
    required Uint8List srcRgba,
    required int srcWidth,
    required int srcHeight,
    required int maxWidth,
    int maxHeight = 1600,
    bool alignWidthTo8 = true,
  }) {
    if (srcWidth <= 0 ||
        srcHeight <= 0 ||
        maxWidth <= 0 ||
        maxHeight <= 0 ||
        srcRgba.length != srcWidth * srcHeight * 4) {
      throw ArgumentError('Invalid dimensions for scaleRgbaToMaxWidth');
    }
    final cleanMaxWidth = alignWidthTo8
        ? math.max(8, (maxWidth ~/ 8) * 8)
        : maxWidth;
    final scale = math.min(
      1.0,
      math.min(cleanMaxWidth / srcWidth, maxHeight / srcHeight),
    );
    final drawW = (srcWidth * scale).round().clamp(1, cleanMaxWidth);
    final drawH = (srcHeight * scale).round().clamp(1, maxHeight);
    final finalW = alignWidthTo8
        ? math.min(cleanMaxWidth, math.max(8, ((drawW + 7) ~/ 8) * 8))
        : drawW;

    final cleanSrc = flattenAlphaOnWhite(srcRgba);
    final out = Uint8List(finalW * drawH * 4);
    out.fillRange(0, out.length, 255);
    final offsetX = (finalW - drawW) ~/ 2;
    _resampleBilinear(
      src: cleanSrc,
      srcW: srcWidth,
      srcH: srcHeight,
      dst: out,
      dstW: finalW,
      dstXStart: offsetX,
      dstYStart: 0,
      dstRectW: drawW,
      dstRectH: drawH,
      sampleOffsetX: 0,
      sampleOffsetY: 0,
      invScale: srcWidth / drawW,
      invScaleY: srcHeight / drawH,
    );
    return (width: finalW, height: drawH, rgbaBytes: out);
  }

  static void _resampleBilinear({
    required Uint8List src,
    required int srcW,
    required int srcH,
    required Uint8List dst,
    required int dstW,
    required int dstXStart,
    required int dstYStart,
    required int dstRectW,
    required int dstRectH,
    required double sampleOffsetX,
    required double sampleOffsetY,
    required double invScale,
    double? invScaleY,
  }) {
    final scaleY = invScaleY ?? invScale;
    final maxX = srcW - 1;
    final maxY = srcH - 1;
    for (var dy = 0; dy < dstRectH; dy++) {
      final sy = ((dy + 0.5) * scaleY + sampleOffsetY - 0.5).clamp(
        0.0,
        maxY.toDouble(),
      );
      final y0 = sy.floor();
      final y1 = math.min(maxY, y0 + 1);
      final fy = sy - y0;
      final dstRow = (dstYStart + dy) * dstW;
      final row0 = y0 * srcW;
      final row1 = y1 * srcW;

      for (var dx = 0; dx < dstRectW; dx++) {
        final sx = ((dx + 0.5) * invScale + sampleOffsetX - 0.5).clamp(
          0.0,
          maxX.toDouble(),
        );
        final x0 = sx.floor();
        final x1 = math.min(maxX, x0 + 1);
        final fx = sx - x0;

        final i00 = (row0 + x0) * 4;
        final i10 = (row0 + x1) * 4;
        final i01 = (row1 + x0) * 4;
        final i11 = (row1 + x1) * 4;
        final dstIdx = (dstRow + dstXStart + dx) * 4;

        for (var c = 0; c < 3; c++) {
          final top = src[i00 + c] + (src[i10 + c] - src[i00 + c]) * fx;
          final bottom = src[i01 + c] + (src[i11 + c] - src[i01 + c]) * fx;
          dst[dstIdx + c] = (top + (bottom - top) * fy).round().clamp(0, 255);
        }
        dst[dstIdx + 3] = 255;
      }
    }
  }

  /// 编码未压缩 24-bit BI_RGB BMP（底部向上存储），供 `Pbita` / `EImage` 解码。
  static Uint8List encodeBmp24({
    required int width,
    required int height,
    required Uint8List rgbaBytes,
  }) {
    if (width <= 0 || height <= 0 || rgbaBytes.length != width * height * 4) {
      throw ArgumentError('Invalid RGBA buffer for encodeBmp24');
    }
    final rowStride = ((width * 3 + 3) ~/ 4) * 4;
    final pixelDataSize = rowStride * height;
    final fileSize = 54 + pixelDataSize;
    final out = Uint8List(fileSize);
    final bd = ByteData.sublistView(out);

    out[0] = 0x42; // 'B'
    out[1] = 0x4D; // 'M'
    bd.setUint32(2, fileSize, Endian.little);
    bd.setUint32(10, 54, Endian.little);
    bd.setUint32(14, 40, Endian.little);
    bd.setInt32(18, width, Endian.little);
    bd.setInt32(22, height, Endian.little);
    bd.setUint16(26, 1, Endian.little);
    bd.setUint16(28, 24, Endian.little);
    bd.setUint32(34, pixelDataSize, Endian.little);

    for (var y = 0; y < height; y++) {
      final srcY = height - 1 - y;
      final srcRow = srcY * width * 4;
      final dstRow = 54 + y * rowStride;
      for (var x = 0; x < width; x++) {
        final s = srcRow + x * 4;
        final d = dstRow + x * 3;
        out[d] = rgbaBytes[s + 2]; // B
        out[d + 1] = rgbaBytes[s + 1]; // G
        out[d + 2] = rgbaBytes[s]; // R
      }
    }
    return out;
  }

  /// 生成 ESC/POS 光栅图像命令载荷（`1D 76 30`）。
  static Uint8List buildEscImagePayload({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    int maxWidth = 384,
  }) {
    final scaled = scaleRgbaToMaxWidth(
      srcRgba: rgbaBytes,
      srcWidth: width,
      srcHeight: height,
      maxWidth: maxWidth,
      maxHeight: 1200,
      alignWidthTo8: true,
    );
    final bmpBytes = encodeBmp24(
      width: scaled.width,
      height: scaled.height,
      rgbaBytes: scaled.rgbaBytes,
    );
    return Commander.make()
        .pushArg(EEnable())
        .pushArg(EImage(image: bmpBytes, compress: false, mode: Mode.normal))
        .pushArg(ELineDot(dot: 48))
        .command()
        .binary();
  }

  /// 生成 TSPL `BITMAP` 标签打印载荷（供 TCP 9100 热敏打印）。
  static Uint8List buildTsplBitmapPayload({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    int maxWidth = 576,
    int copies = 1,
  }) {
    final scaled = scaleRgbaToMaxWidth(
      srcRgba: rgbaBytes,
      srcWidth: width,
      srcHeight: height,
      maxWidth: maxWidth,
      maxHeight: 640,
      alignWidthTo8: true,
    );
    final bmpBytes = encodeBmp24(
      width: scaled.width,
      height: scaled.height,
      rgbaBytes: scaled.rgbaBytes,
    );
    final widthMm = (scaled.width / 8).ceil().clamp(30, 80);
    final heightMm = ((scaled.height / 8).ceil() + 4).clamp(20, 120);
    return Commander.make()
        .pushArg(TPage(width: widthMm, height: heightMm))
        .pushArg(TLabel(height: 2, offset: 0))
        .pushArg(TClear())
        .pushArg(TImage(x: 0, y: 0, image: bmpBytes, threshold: 190))
        .pushArg(TPrint(copies: copies.clamp(1, 99)))
        .command()
        .binary();
  }
}

/// 顶层 Isolate 辅助函数（不捕获控制器实例，避免 unsendable 对象跨 Isolate 失败）。
Future<Uint8List> buildEscImagePayloadInIsolate({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
}) => Isolate.run(
  () => LocalImageProcessor.buildEscImagePayload(
    rgbaBytes: rgbaBytes,
    width: width,
    height: height,
  ),
);

Future<Uint8List> buildTsplBitmapPayloadInIsolate({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
  int copies = 1,
}) => Isolate.run(
  () => LocalImageProcessor.buildTsplBitmapPayload(
    rgbaBytes: rgbaBytes,
    width: width,
    height: height,
    copies: copies,
  ),
);

Future<Uint8List> fitSublimationRgbaInIsolate({
  required Uint8List srcRgba,
  required int srcWidth,
  required int srcHeight,
  required int targetWidth,
  required int targetHeight,
}) => Isolate.run(
  () => LocalImageProcessor.fitRgbaToCanvas(
    srcRgba: srcRgba,
    srcWidth: srcWidth,
    srcHeight: srcHeight,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    cover: false,
    autoRotateToMatchOrientation: true,
  ),
);

Future<({int width, int height, Uint8List rgbaBytes})>
scaleInkjetRgbaInIsolate({
  required Uint8List srcRgba,
  required int srcWidth,
  required int srcHeight,
  required int maxWidth,
  required int maxHeight,
}) => Isolate.run(
  () => LocalImageProcessor.scaleRgbaToMaxWidth(
    srcRgba: srcRgba,
    srcWidth: srcWidth,
    srcHeight: srcHeight,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    alignWidthTo8: false,
  ),
);
