import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'local_image_processor.dart';
export 'local_image_processor.dart';

/// 本地选中的图片及其已规范化（去透明通道叠白底）的 RGBA8888 像素。
final class PickedLocalImage {
  const PickedLocalImage({
    required this.name,
    required this.previewBytes,
    required this.width,
    required this.height,
    required this.rgbaBytes,
  });

  factory PickedLocalImage.fromRgba({
    required String name,
    required int width,
    required int height,
    required Uint8List rgbaBytes,
    Uint8List? previewBytes,
  }) {
    final expectedLen = width * height * 4;
    if (width <= 0 || height <= 0 || rgbaBytes.length != expectedLen) {
      throw ArgumentError(
        'Expected ${width}x$height ($expectedLen bytes) RGBA buffer, '
        'got ${rgbaBytes.length}',
      );
    }
    final opaque = LocalImageProcessor.flattenAlphaOnWhite(rgbaBytes);
    final thumb =
        previewBytes ??
        LocalImageProcessor.encodeBmp24(
          width: width,
          height: height,
          rgbaBytes: opaque,
        );
    return PickedLocalImage(
      name: name,
      previewBytes: thumb,
      width: width,
      height: height,
      rgbaBytes: opaque,
    );
  }

  final String name;
  final Uint8List previewBytes;
  final int width;
  final int height;
  final Uint8List rgbaBytes;
}

/// 通过原生平台通道选择系统相册/文件图片，并解码为 RGBA8888。
class LocalImagePickerService {
  const LocalImagePickerService({
    this.pickerOverride,
    this.maxDecodedDimension = 2048,
  });

  static const MethodChannel _channel = MethodChannel(
    'com.psdk.examples.cloud_print_demo/local_image',
  );

  final Future<PickedLocalImage?> Function()? pickerOverride;
  final int maxDecodedDimension;

  Future<PickedLocalImage?> pickImage() async {
    if (pickerOverride != null) {
      return pickerOverride!();
    }
    final Map<Object?, Object?>? raw;
    try {
      raw = await _channel.invokeMethod<Map<Object?, Object?>>('pickImage');
    } on MissingPluginException {
      throw StateError('当前平台不支持原生本地图片选择');
    } on PlatformException catch (e) {
      throw StateError(e.message ?? '选择本地图片失败 (${e.code})');
    }
    if (raw == null) return null;

    final rawName = raw['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'local_image';
    final rawBytes = raw['bytes'];
    if (rawBytes is! Uint8List || rawBytes.isEmpty) {
      throw StateError('读取本地图片数据失败');
    }
    return decodeEncodedBytes(name: name, bytes: rawBytes);
  }

  Future<PickedLocalImage> decodeEncodedBytes({
    required String name,
    required Uint8List bytes,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final origW = descriptor.width;
      final origH = descriptor.height;
      if (origW <= 0 || origH <= 0) {
        throw StateError('无法识别图片尺寸');
      }
      int? targetW;
      int? targetH;
      final longest = math.max(origW, origH);
      if (longest > maxDecodedDimension) {
        final scale = maxDecodedDimension / longest;
        targetW = math.max(1, (origW * scale).round());
        targetH = math.max(1, (origH * scale).round());
      }
      codec = await descriptor.instantiateCodec(
        targetWidth: targetW,
        targetHeight: targetH,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw StateError('无法解码图片像素数据');
      }
      final rawRgba = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final opaque = LocalImageProcessor.flattenAlphaOnWhite(rawRgba);
      return PickedLocalImage(
        name: name,
        previewBytes: bytes,
        width: image.width,
        height: image.height,
        rgbaBytes: opaque,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
