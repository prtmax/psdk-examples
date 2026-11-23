import 'dart:io';

import 'package:flutter/services.dart';

class AndroidLanDiscoveryNetwork {
  const AndroidLanDiscoveryNetwork({
    required this.address,
    required this.prefixLength,
    this.interfaceName,
  });

  final String address;
  final int prefixLength;
  final String? interfaceName;
}

/// Binds Android process traffic to the active Wi-Fi network for one scan.
class AndroidLanDiscoverySession {
  AndroidLanDiscoverySession({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel(channelName),
      _isAndroid = isAndroid ?? Platform.isAndroid;

  static const String channelName =
      'com.psdk.examples.cloud_print_demo/android_sdk';

  final MethodChannel _channel;
  final bool _isAndroid;
  bool _active = false;
  Future<bool>? _beginFuture;

  bool get isActive => _active;

  Future<bool> begin() {
    if (!_isAndroid) return Future<bool>.value(false);
    final pending = _beginFuture;
    if (pending != null) return pending;

    final future = _begin();
    _beginFuture = future;
    return future;
  }

  Future<bool> _begin() async {
    try {
      final bound = await _channel.invokeMethod<bool>(
        'beginLanDiscoveryNetwork',
      );
      if (bound != true) {
        throw StateError('Android did not bind LAN discovery to Wi-Fi');
      }
      _active = true;
      return true;
    } catch (_) {
      _active = false;
      rethrow;
    } finally {
      _beginFuture = null;
    }
  }

  Future<AndroidLanDiscoveryNetwork?> currentNetwork() async {
    if (!_isAndroid || !_active) return null;
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'lanDiscoveryNetworkInfo',
    );
    if (raw == null) return null;
    final address = raw['address'];
    final prefixLength = raw['prefixLength'];
    final interfaceName = raw['interfaceName'];
    if (address is! String || prefixLength is! int) return null;
    return AndroidLanDiscoveryNetwork(
      address: address,
      prefixLength: prefixLength,
      interfaceName: interfaceName is String ? interfaceName : null,
    );
  }

  Future<void> end() async {
    final pending = _beginFuture;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    if (!_active) return;
    try {
      await _channel.invokeMethod<void>('endLanDiscoveryNetwork');
    } finally {
      _active = false;
      _beginFuture = null;
    }
  }
}
