import 'package:flutter/foundation.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import 'protocol_inspector.dart';

enum DemoFeedbackKind { info, success, error }

class DemoFeedbackEvent {
  const DemoFeedbackEvent({
    required this.id,
    required this.kind,
    required this.message,
    this.family,
  });

  final int id;
  final DemoFeedbackKind kind;
  final String message;
  final CloudPrinterFamily? family;
}

/// Coordinates transient interactive feedback (e.g., floating SnackBars)
/// across all protocol controllers and tabs while keeping messages concise
/// and free of plaintext credentials.
class DemoFeedbackCenter extends ChangeNotifier {
  static final RegExp _sublimationExceptionRegex = RegExp(
    r'SublimationProtocolException\(([^,]+),\s*rawStatusCode:\s*[^,]+,\s*message:\s*([^)]+)\)',
  );

  int _nextId = 1;
  DemoFeedbackEvent? _latest;
  bool _disposed = false;

  DemoFeedbackEvent? get latest => _latest;

  static bool isErrorMessage(String message) {
    final text = message.trim();
    if (text.isEmpty) return false;
    const errorMarkers = <String>[
      '失败',
      '未发现',
      '未在',
      '超时',
      '错误',
      '请先',
      '请输入',
      '不支持',
      '异常',
      '无效',
      '拒绝',
      'blocked',
      'failed',
    ];
    final lower = text.toLowerCase();
    for (final marker in errorMarkers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  static String formatMessage(String raw) {
    var text = ProtocolInspectorController.redactSecrets(raw).trim();
    if (text.isEmpty) return '未知状态';

    final match = _sublimationExceptionRegex.firstMatch(text);
    if (match != null) {
      final code = (match.group(1) ?? '').trim();
      final inner = (match.group(2) ?? '').trim();
      if (inner.isNotEmpty) {
        text = code.isNotEmpty ? '$inner ($code)' : inner;
      }
    }

    // Strip isolate / Dart runtime diagnostic chains after the primary line.
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isNotEmpty) {
      text = lines.first;
    }

    if (text.length > 140) {
      text = '${text.substring(0, 139)}…';
    }
    return text;
  }

  void emit({
    required DemoFeedbackKind kind,
    required String message,
    CloudPrinterFamily? family,
  }) {
    if (_disposed) return;
    final clean = formatMessage(message);
    _latest = DemoFeedbackEvent(
      id: _nextId++,
      kind: kind,
      message: clean,
      family: family,
    );
    notifyListeners();
  }

  void emitSuccess(String message, {CloudPrinterFamily? family}) =>
      emit(kind: DemoFeedbackKind.success, message: message, family: family);

  void emitError(String message, {CloudPrinterFamily? family}) =>
      emit(kind: DemoFeedbackKind.error, message: message, family: family);

  void emitInfo(String message, {CloudPrinterFamily? family}) =>
      emit(kind: DemoFeedbackKind.info, message: message, family: family);

  void emitOutcome(
    String message, {
    bool forceError = false,
    CloudPrinterFamily? family,
  }) {
    final clean = formatMessage(message);
    final DemoFeedbackKind kind;
    if (forceError || isErrorMessage(clean)) {
      kind = DemoFeedbackKind.error;
    } else if (clean.contains('已取消') ||
        clean.contains('已断开') ||
        clean.contains('已切换') ||
        clean.contains('cancelled')) {
      kind = DemoFeedbackKind.info;
    } else {
      kind = DemoFeedbackKind.success;
    }
    emit(kind: kind, message: clean, family: family);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
