import 'dart:async';

import 'package:flutter/services.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_network/psdk_network.dart';

/// Real-device transport coordinator wrapping `BLEBluetooth` and `Network`
/// with graceful `MissingPluginException` / `PlatformException` guards.
class RealTransportHelper {
  BLEBluetooth? _ble;
  StreamSubscription<BLEBluetoothDevice>? _bleSub;
  final List<BLEBluetoothDevice> discoveredBleDevices = <BLEBluetoothDevice>[];
  String? lastError;

  BLEBluetooth _ensureBle(BleConnectionConfig config) {
    final existing = _ble;
    if (existing != null) {
      existing.updateConfig(config);
      return existing;
    }
    final created = BLEBluetooth.scoped(
      config: config,
      enableStatePolling: false,
    );
    _ble = created;
    return created;
  }

  BleConnectionConfig configForFamily(CloudPrinterFamily family) {
    switch (family) {
      case CloudPrinterFamily.escWanCloud:
      case CloudPrinterFamily.thermalLanStream:
        return const BleConnectionConfig(preferredMtu: 512);
      case CloudPrinterFamily.sublimationRpc:
        return BleConnectionConfig.sublimation;
      case CloudPrinterFamily.colorInkjetPjl:
        return BleConnectionConfig.inkjet;
    }
  }

  Future<List<BLEBluetoothDevice>> scanBle({
    required CloudPrinterFamily family,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    lastError = null;
    discoveredBleDevices.clear();
    final seen = <String>{};
    try {
      final ble = _ensureBle(configForFamily(family));
      final available = await ble.availableBluetooth();
      if (!available) {
        lastError = 'Bluetooth adapter is unavailable on this device';
        return const <BLEBluetoothDevice>[];
      }
      final enabled = await ble.bluetoothIsEnabled();
      if (!enabled) {
        lastError = 'Bluetooth is turned off';
        return const <BLEBluetoothDevice>[];
      }

      await _bleSub?.cancel();
      _bleSub = ble.discovered().listen((dev) {
        final key = '${dev.mac ?? ''}:${dev.name ?? ''}';
        if (seen.add(key)) {
          discoveredBleDevices.add(dev);
        }
      });

      await ble.startDiscovery(timeout: timeout);
      await Future<void>.delayed(timeout);
      await ble.stopDiscovery();
      return List<BLEBluetoothDevice>.unmodifiable(discoveredBleDevices);
    } on MissingPluginException {
      lastError =
          'BLE plugin is not available on this platform (Android/iOS required)';
      return const <BLEBluetoothDevice>[];
    } on PlatformException catch (e) {
      lastError = 'BLE platform error: ${e.message ?? e.code}';
      return const <BLEBluetoothDevice>[];
    } catch (e) {
      lastError = 'BLE scan error: $e';
      return const <BLEBluetoothDevice>[];
    }
  }

  Future<ConnectedDevice<dynamic>?> connectBle({
    required CloudPrinterFamily family,
    required BLEBluetoothDevice device,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    lastError = null;
    try {
      final config = configForFamily(family);
      final ble = _ensureBle(config);
      return await ble.connect(device, timeout: timeout, config: config);
    } on MissingPluginException {
      lastError =
          'BLE plugin is not available on this platform (Android/iOS required)';
      return null;
    } on PlatformException catch (e) {
      lastError = 'BLE connect error: ${e.message ?? e.code}';
      return null;
    } catch (e) {
      lastError = 'BLE connect error: $e';
      return null;
    }
  }

  Network createRealNetwork({void Function(String)? debugLogger}) {
    return Network.scoped(debugLogger: debugLogger);
  }

  Future<void> dispose() async {
    await _bleSub?.cancel();
    _bleSub = null;
    try {
      await _ble?.dispose();
    } catch (_) {}
    _ble = null;
  }
}
