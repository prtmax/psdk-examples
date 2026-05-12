import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart';
import 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';
import 'package:psdk_bluetooth_windows/psdk_bluetooth_windows.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';

const _androidSdkChannel = MethodChannel(
  'com.psdk.examples.emapi_demo/android_sdk',
);

List<Permission> androidBluetoothPermissionsForSdk(int sdkInt) {
  if (sdkInt >= 31) {
    return [Permission.bluetoothScan, Permission.bluetoothConnect];
  }
  return [Permission.location, Permission.bluetooth];
}

class DiscoveredPrinterDevice {
  DiscoveredPrinterDevice({
    required this.rawDevice,
    required this.name,
    required this.mac,
    required this.rssi,
    required this.protocol,
  });

  final FluetoothDevice rawDevice;
  final String name;
  final String mac;
  final int? rssi;
  final BluetoothProtocol protocol;

  String get protocolLabel {
    return switch (protocol) {
      BluetoothProtocol.ble => 'BLE',
      BluetoothProtocol.classic => 'Classic',
    };
  }
}

class BluetoothPrinterConnector {
  final _devicesController =
      StreamController<DiscoveredPrinterDevice>.broadcast();
  final Map<String, DiscoveredPrinterDevice> _devices = {};
  StreamSubscription? _discoveredSubscription;
  dynamic _bluetooth;

  Stream<DiscoveredPrinterDevice> get discoveredDevices {
    return _devicesController.stream;
  }

  List<DiscoveredPrinterDevice> get devices {
    return List.unmodifiable(_devices.values);
  }

  bool get isSupported {
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows;
  }

  Future<void> init() async {
    if (!isSupported || _bluetooth != null) {
      return;
    }
    if (Platform.isAndroid) {
      _bluetooth = ClassicBluetooth();
    } else if (Platform.isIOS) {
      _bluetooth = BLEBluetooth();
    } else if (Platform.isWindows) {
      _bluetooth = WindowsBluetooth();
    }
    _discoveredSubscription = _bluetooth.discovered().listen((device) {
      final discovered = _fromDevice(device);
      if (discovered.name.isEmpty) {
        return;
      }
      final key = discovered.mac.isEmpty ? discovered.name : discovered.mac;
      if (_devices.containsKey(key)) {
        return;
      }
      _devices[key] = discovered;
      _devicesController.add(discovered);
    });
  }

  Future<bool> bluetoothIsEnabled() async {
    await init();
    if (_bluetooth == null) {
      return false;
    }
    return await _bluetooth.bluetoothIsEnabled() == true;
  }

  Future<void> requestPermissions() async {
    final requiredPermissions = await _requiredPermissions();
    if (requiredPermissions.isEmpty) {
      return;
    }
    final statuses = await requiredPermissions.request();
    _checkPermissionStatuses(statuses);
  }

  Future<List<Permission>> _requiredPermissions() async {
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt != null) {
        return androidBluetoothPermissionsForSdk(sdkInt);
      }
      // Keep Android 12+ location out of the runtime request set when the
      // platform channel is unavailable; the manifest caps location at API 30.
      return [Permission.bluetoothScan, Permission.bluetoothConnect];
    }
    if (Platform.isIOS) {
      return [Permission.bluetooth];
    }
    return const [];
  }

  void _checkPermissionStatuses(Map<Permission, PermissionStatus> statuses) {
    final denied = statuses.entries
        .where((entry) => !_permissionGranted(entry.value))
        .map((entry) {
          final permissionLabel = _permissionLabel(entry.key);
          final statusLabel = entry.value.isPermanentlyDenied
              ? '已被永久拒绝，请在系统设置中开启'
              : '未授权';
          return '$permissionLabel$statusLabel';
        })
        .toList();
    if (denied.isNotEmpty) {
      throw StateError('蓝牙扫描需要权限：${denied.join('，')}');
    }
  }

  bool _permissionGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<int?> _androidSdkInt() async {
    try {
      return await _androidSdkChannel.invokeMethod<int>('sdkInt');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  String _permissionLabel(Permission permission) {
    if (permission == Permission.location) {
      return '位置权限';
    }
    if (permission == Permission.bluetoothScan) {
      return '蓝牙扫描权限';
    }
    if (permission == Permission.bluetoothConnect) {
      return '蓝牙连接权限';
    }
    if (permission == Permission.bluetooth) {
      return '蓝牙权限';
    }
    return '权限';
  }

  Future<void> startScan() async {
    await init();
    if (_bluetooth == null) {
      throw UnsupportedError('当前平台不支持蓝牙扫描');
    }
    await requestPermissions();
    _devices.clear();
    final isDiscovery = await _bluetooth.isDiscovery() == true;
    if (isDiscovery) {
      await _bluetooth.stopDiscovery();
    }
    await _bluetooth.startDiscovery(disconnectConnectedDevice: false);
  }

  Future<void> stopScan() async {
    if (_bluetooth == null) {
      return;
    }
    final isDiscovery = await _bluetooth.isDiscovery() == true;
    if (isDiscovery) {
      await _bluetooth.stopDiscovery();
    }
  }

  Future<ConnectedDevice> connect(DiscoveredPrinterDevice device) async {
    await stopScan();
    return await _bluetooth.connect(device.rawDevice);
  }

  Future<void> dispose() async {
    await stopScan();
    await _discoveredSubscription?.cancel();
    await _devicesController.close();
  }

  DiscoveredPrinterDevice _fromDevice(FluetoothDevice device) {
    return DiscoveredPrinterDevice(
      rawDevice: device,
      name: device.name ?? '',
      mac: device.mac ?? '',
      rssi: device.rssi,
      protocol: device.protocol,
    );
  }
}
