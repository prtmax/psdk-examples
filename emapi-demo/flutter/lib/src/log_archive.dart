import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'entities/emapi_demo_log_entry.dart';

/// 该平台能否直接调起系统分享面板（Android/iOS 上会列出微信、QQ、邮件等）。
bool get canShareLogArchive => Platform.isAndroid || Platform.isIOS;

/// 生成纯文本归档：时间正序 + 每条完整 Hex，方便与固件串口日志按时间对齐。
String buildLogArchive({
  required String name,
  required List<EmapiDemoLogEntry> entries,
  String? meta,
}) {
  final buffer = StringBuffer();
  buffer.writeln('# EMAPI $name 导出');
  buffer.writeln('# 导出时间: ${formatLogDateTime(DateTime.now())}');
  buffer.writeln('# 条目数: ${entries.length}（按时间正序）');
  if (meta != null && meta.isNotEmpty) {
    buffer.writeln('# $meta');
  }
  buffer.writeln(
    '# 说明: Hex 为交给底层连接 write()/read() 的完整字节。'
    '一帧 EMAPI = mtu 字节（mtu 由设备上报，见“查询打印机基本参数”）。',
  );
  buffer.writeln();
  final ordered = entries.reversed.toList(growable: false);
  for (var i = 0; i < ordered.length; i++) {
    final entry = ordered[i];
    buffer.writeln(
      '--- [${(i + 1).toString().padLeft(4, '0')}] ${entry.title}',
    );
    buffer.writeln(entry.message);
    final bytes = entry.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      buffer.writeln('HEX (${bytes.length} bytes):');
      buffer.write(formatHexDump(bytes));
    }
    buffer.writeln();
  }
  return buffer.toString();
}

String formatHexDump(Uint8List bytes, {int bytesPerLine = 32}) {
  final buffer = StringBuffer();
  for (var offset = 0; offset < bytes.length; offset += bytesPerLine) {
    final end = math.min(offset + bytesPerLine, bytes.length);
    final line = <String>[];
    for (var i = offset; i < end; i++) {
      line.add(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    buffer.writeln(
      '${offset.toRadixString(16).padLeft(4, '0').toUpperCase()}: '
      '${line.join(' ')}',
    );
  }
  return buffer.toString();
}

String formatLogDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}:${two(time.second)}'
      '.${time.millisecond.toString().padLeft(3, '0')}';
}

/// 文件名形如 `emapi-链路日志-20261024-103518.txt`。
String buildLogArchiveFileName({required String name, DateTime? now}) {
  final time = now ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp = '${time.year}${two(time.month)}${two(time.day)}-'
      '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  final safeName = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return 'emapi-$safeName-$stamp.txt';
}

/// 复制到剪贴板。
Future<void> copyLogArchiveToClipboard(String content) {
  return Clipboard.setData(ClipboardData(text: content));
}

/// 弹出保存框并落盘。返回最终路径；用户取消返回 null。
Future<String?> saveLogArchive({
  required String fileName,
  required String content,
}) async {
  final path = await FilePicker.saveFile(
    dialogTitle: '导出日志',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['txt'],
    bytes: Uint8List.fromList(utf8.encode(content)),
  );
  if (path == null) {
    return null;
  }
  // 桌面端插件只返回路径，需要自己写盘；移动端已由平台侧写入。
  if (!Platform.isAndroid && !Platform.isIOS) {
    await File(path).writeAsString(content);
  }
  return path;
}

/// 把文本写成临时文件后调起系统分享面板，可直接选微信发给同事。
Future<void> shareLogArchive({
  required String fileName,
  required String content,
  String? title,
}) async {
  final directory = await Directory.systemTemp.createTemp('emapi_share_');
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(content);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/plain')],
      fileNameOverrides: [fileName],
      title: title ?? 'EMAPI 日志',
      subject: title ?? 'EMAPI 日志',
    ),
  );
}
