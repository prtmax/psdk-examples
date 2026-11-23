import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps Android's multicast receive path enabled while LAN discovery runs.
class AndroidMulticastLock {
  AndroidMulticastLock({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel(channelName),
      _isAndroid = isAndroid ?? Platform.isAndroid;

  static const String channelName =
      'com.psdk.examples.cloud_print_demo/android_sdk';

  final MethodChannel _channel;
  final bool _isAndroid;
  bool _held = false;

  bool get isHeld => _held;

  Future<bool> acquire() async {
    if (!_isAndroid || _held) return _held;
    await _channel.invokeMethod<void>('acquireMulticastLock');
    _held = true;
    return true;
  }

  Future<void> release() async {
    if (!_held) return;
    try {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    } finally {
      _held = false;
    }
  }
}
