import 'dart:async';
import 'dart:io';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart'
    hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:psdk_bluetooth_windows/psdk_bluetooth_windows.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart' as ios_ble;
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/protocol_inspector.dart';
import 'inspected_device.dart';

/// bluetooth_windows 使用 bluetooth_low_energy，包含 Android 原生实现。
class RealTransportHelper extends ChangeNotifier {
  RealTransportHelper(this.inspector);

  final ProtocolInspectorController inspector;
  WindowsBluetooth? _ble;
  ios_ble.BLEBluetooth? _iosBle;
  bool get _useIosBle => Platform.isIOS;
  StreamSubscription<dynamic>? _bleSub;
  final List<DemoBleDevice> discoveredBleDevices = [];
  final List<ConnectedDevice<dynamic>> _connections = [];
  bool _disposed = false;
  bool _scanning = false;
  bool _connecting = false;
  Completer<void>? _scanStop;
  Completer<void>? _scanDone;
  final Set<String> _seenScanIds = {};
  String? lastError;
  String? wifiNameError;
  Future<String?>? _wifiNameRead;

  /// 多个配网页面同时打开时，共用一次权限请求和 SSID 读取。
  Future<String?> readCurrentWifiName() => _wifiNameRead ??=
      _readCurrentWifiName().whenComplete(() => _wifiNameRead = null);

  Future<String?> _readCurrentWifiName() async {
    wifiNameError = null;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final permission = await Permission.locationWhenInUse.request();
        if (!permission.isGranted) {
          wifiNameError = '读取 Wi-Fi 名称需要定位权限，可在设置中允许后重试，或手动输入';
          return null;
        }
        if (!await Permission.locationWhenInUse.serviceStatus.isEnabled) {
          wifiNameError = '请开启系统定位服务以读取 Wi-Fi 名称，或手动输入';
          return null;
        }
      }
      var name = await NetworkInfo().getWifiName();
      // Android 可能将 SSID 包在引号内；不裁掉 SSID 本身合法的空格。
      if (Platform.isAndroid &&
          name != null &&
          name.length >= 2 &&
          name.startsWith('"') &&
          name.endsWith('"')) {
        name = name.substring(1, name.length - 1);
      }
      if (name == null ||
          name.trim().isEmpty ||
          name.toLowerCase() == '<unknown ssid>') {
        wifiNameError = '未读取到当前 Wi-Fi 名称，请确认已连接 Wi-Fi、允许精确定位，或手动输入';
        return null;
      }
      return name;
    } catch (_) {
      wifiNameError = '无法读取当前 Wi-Fi 名称，请手动输入';
      return null;
    }
  }

  bool get scanning => _scanning;
  bool get connecting => _connecting;
  bool get _scanCancelled => _disposed || (_scanStop?.isCompleted ?? true);

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  void _onDiscovered(DemoBleDevice device) {
    if (_scanCancelled || !device.hasDisplayName) return;
    if (!_seenScanIds.add(device.mac ?? device.name!.trim())) return;
    discoveredBleDevices.add(device);
    _notifyIfAlive();
  }

  Future<void> _waitForScan(Duration timeout) async {
    final elapsed = Completer<void>();
    final timer = Timer(timeout, elapsed.complete);
    try {
      await Future.any([elapsed.future, _scanStop!.future]);
    } finally {
      timer.cancel();
    }
  }

  Future<void> stopBleScan() async {
    final stop = _scanStop;
    if (stop != null && !stop.isCompleted) stop.complete();
    await _scanDone?.future;
  }

  WindowsBluetooth _ensureBle() => _ble ??= WindowsBluetooth.scoped();

  BleGattProfile? configForFamily(CloudPrinterFamily family) =>
      family == CloudPrinterFamily.colorInkjetPjl
      ? BleGattProfile.inkjet
      : null;

  static int? mtuOf(ConnectedDevice<dynamic> device) =>
      device is DemoBleConnection ? device.negotiatedMtu : null;

  static InkjetBleGattHooks? inkjetHooksOf(ConnectedDevice<dynamic> device) =>
      device is DemoBleConnection ? device.inkjetHooks : null;

  Future<List<DemoBleDevice>> scanBle({
    required CloudPrinterFamily family,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_disposed || _scanning || _connecting) return const [];
    _scanning = true;
    _scanStop = Completer<void>();
    final done = Completer<void>();
    _scanDone = done;
    lastError = null;
    discoveredBleDevices.clear();
    _seenScanIds.clear();
    _notifyIfAlive();
    try {
      if (Platform.isAndroid) {
        const sdk = MethodChannel(
          'com.psdk.examples.cloud_print_demo/android_sdk',
        );
        final version = await sdk.invokeMethod<int>('sdkInt');
        final permissions = (version ?? 31) >= 31
            ? [Permission.bluetoothScan, Permission.bluetoothConnect]
            : [Permission.locationWhenInUse];
        final statuses = await permissions.request();
        if (permissions.any((p) => statuses[p]?.isGranted != true)) {
          lastError = '请在系统设置中允许蓝牙扫描和连接权限';
          return const [];
        }
      }
      if (_scanCancelled) return const [];
      if (_useIosBle) return await _scanIos(family, timeout);
      final ble = _ensureBle();
      final manager = ble.origin();
      if (manager.state == BluetoothLowEnergyState.unknown) {
        await manager.stateChanged
            .firstWhere(
              (event) => event.state != BluetoothLowEnergyState.unknown,
            )
            .timeout(const Duration(seconds: 5));
      }
      if (manager.state == BluetoothLowEnergyState.unauthorized) {
        await manager.authorize();
      }
      // 直接读取原生状态，规避旧版 availableBluetooth 返回值方向相反。
      if (manager.state != BluetoothLowEnergyState.poweredOn) {
        lastError = '蓝牙不可用，请开启蓝牙并检查权限（${manager.state.name}）';
        return const [];
      }
      if (_scanCancelled) return const [];
      await _bleSub?.cancel();
      _bleSub = ble.discovered().listen((device) {
        _onDiscovered(DemoBleDevice.windows(device));
      });
      if (_scanCancelled) return const [];
      await ble.startDiscovery(timeout: timeout);
      await _waitForScan(timeout);
      await ble.stopDiscovery();
      return _disposed ? const [] : List.unmodifiable(discoveredBleDevices);
    } on MissingPluginException {
      lastError = '当前构建未包含蓝牙原生插件，请重新构建并安装';
      return const [];
    } catch (error) {
      lastError = '蓝牙扫描失败：$error';
      return const [];
    } finally {
      await _bleSub?.cancel();
      _bleSub = null;
      try {
        await _stopDiscovery();
      } catch (_) {}
      _scanning = false;
      done.complete();
      _notifyIfAlive();
    }
  }

  Future<ConnectedDevice<dynamic>?> connectBle({
    required CloudPrinterFamily family,
    required DemoBleDevice device,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_disposed || _connecting) return null;
    _connecting = true;
    _notifyIfAlive();
    lastError = null;
    ConnectedDevice<dynamic>? connection;
    try {
      if (_useIosBle) {
        connection = await _connectIos(family, device, timeout);
        if (_disposed) {
          await connection.disconnect();
          return null;
        }
        _connections.add(connection);
        return connection;
      }
      final nativeDevice = device.windows;
      if (nativeDevice == null) throw StateError('设备与当前蓝牙实现不匹配，请重新扫描');
      final ble = _ensureBle();
      final profile = configForFamily(family);
      connection = await ble.connect(
        nativeDevice,
        timeout: timeout,
        allowedWriteCharacteristic: profile?.writeCharacteristicUuid,
        allowedReadCharacteristic: profile?.notifyCharacteristicUuid,
        // 配网不启用打印数据流的辅助 credit 通道。
        allowDetectDifferentCharacteristic: profile == null,
      );
      final nativeConnection = connection;
      if (nativeConnection is! WindowsConnectedDevice) {
        throw StateError('蓝牙连接类型不匹配');
      }
      await nativeConnection.ready;
      if (_disposed) {
        await connection.disconnect();
        return null;
      }
      final manager = ble.origin();
      final peripheral = nativeDevice.origin.peripheral;
      final mtu = Platform.isAndroid && connection is WindowsConnectedDevice
          ? connection.negotiatedMtu
          : await manager.getMaximumWriteLength(
                  peripheral,
                  type: GATTCharacteristicWriteType.withResponse,
                ) +
                3;
      final inspected = DemoBleConnection(
        connection,
        inspector,
        family,
        mtu,
        inkjetHooks: profile == BleGattProfile.inkjet
            ? InkjetBleGattHooks(
                stopScan: ble.stopDiscovery,
                requestMtu: (_) async => mtu,
                // ready already enabled notifications when supported. Reuse
                // that GATT snapshot for both writes and explicit ACK reads.
                enableNotifications: (_, _) async {},
                readCharacteristic: (_, _) =>
                    nativeConnection.readCharacteristic(),
              )
            : null,
      );
      if (_disposed) {
        await inspected.disconnect();
        return null;
      }
      _connections.add(inspected);
      return inspected;
    } catch (error) {
      try {
        await connection?.disconnect();
      } catch (_) {}
      lastError = '蓝牙连接失败：$error';
      return null;
    } finally {
      _connecting = false;
      _notifyIfAlive();
    }
  }

  ios_ble.BleConnectionConfig _iosConfig(CloudPrinterFamily family) {
    final profile = configForFamily(family);
    return profile == null
        ? const ios_ble.BleConnectionConfig(preferredMtu: 512)
        : ios_ble.BleConnectionConfig.fromProfile(profile);
  }

  ios_ble.BLEBluetooth _ensureIosBle(CloudPrinterFamily family) {
    final config = _iosConfig(family);
    final existing = _iosBle;
    if (existing != null) {
      existing.updateConfig(config);
      return existing;
    }
    return _iosBle = ios_ble.BLEBluetooth.scoped(
      config: config,
      enableStatePolling: false,
    );
  }

  Future<void> _stopDiscovery() async {
    await _ble?.stopDiscovery();
    await _iosBle?.stopDiscovery();
  }

  Future<List<DemoBleDevice>> _scanIos(
    CloudPrinterFamily family,
    Duration timeout,
  ) async {
    final ble = _ensureIosBle(family);
    if (!await ble.availableBluetooth() || !await ble.bluetoothIsEnabled()) {
      lastError = '蓝牙不可用，请开启蓝牙并检查权限';
      return const [];
    }
    if (_scanCancelled) return const [];
    await _bleSub?.cancel();
    _bleSub = ble.discovered().listen((device) {
      _onDiscovered(DemoBleDevice.ios(device));
    });
    if (_scanCancelled) return const [];
    await ble.startDiscovery(timeout: timeout);
    await _waitForScan(timeout);
    await ble.stopDiscovery();
    return _disposed ? const [] : List.unmodifiable(discoveredBleDevices);
  }

  Future<DemoBleConnection> _connectIos(
    CloudPrinterFamily family,
    DemoBleDevice device,
    Duration timeout,
  ) async {
    final nativeDevice = device.ios;
    if (nativeDevice == null) throw StateError('设备与当前蓝牙实现不匹配，请重新扫描');
    final ble = _ensureIosBle(family);
    final connection = await ble.connect(
      nativeDevice,
      timeout: timeout,
      config: _iosConfig(family),
    );
    // 保留 iOS 原有 ble_plugin 路径；其 MTU 值由现有 SDK 报告。
    final mtu = connection is ios_ble.BLEConnectedDevice
        ? connection.negotiatedMtu
        : 512;
    return DemoBleConnection(
      connection,
      inspector,
      family,
      mtu,
      inkjetHooks:
          connection is ios_ble.BLEConnectedDevice &&
              family == CloudPrinterFamily.colorInkjetPjl
          ? InkjetBleGattHooks(
              stopScan: ble.stopDiscovery,
              requestMtu: (_) async => mtu,
              // prepareConnection 已通过插件开启原生通知。
              enableNotifications: (_, _) async {},
              readCharacteristic: (service, characteristic) =>
                  connection.readCharacteristic(
                    serviceUuid: service,
                    characteristicUuid: characteristic,
                  ),
            )
          : null,
    );
  }

  Network createRealNetwork({void Function(String)? debugLogger}) =>
      Network.scoped(debugLogger: debugLogger);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopBleScan();
    await _bleSub?.cancel();
    await _stopDiscovery();
    for (final connection in _connections) {
      if (connection.connectionState() == ConnectionState.connected) {
        await connection.disconnect();
      }
    }
    _connections.clear();
    await _iosBle?.dispose();
    await _ble?.dispose();
    super.dispose();
  }
}

class DemoBleConnection extends InspectedDevice {
  DemoBleConnection(
    ConnectedDevice<dynamic> device,
    ProtocolInspectorController inspector,
    CloudPrinterFamily family,
    this.negotiatedMtu, {
    this.inkjetHooks,
  }) : super(device, inspector, family, 'BLE');

  final int negotiatedMtu;
  final InkjetBleGattHooks? inkjetHooks;
}

class DemoBleDevice {
  DemoBleDevice.windows(WindowsBluetoothDevice device)
    : windows = device,
      ios = null;
  DemoBleDevice.ios(ios_ble.BLEBluetoothDevice device)
    : ios = device,
      windows = null;
  final WindowsBluetoothDevice? windows;
  final ios_ble.BLEBluetoothDevice? ios;
  String? get name => windows?.name ?? ios?.name;
  String? get mac => windows?.mac ?? ios?.mac;
  bool get hasDisplayName => name?.trim().isNotEmpty ?? false;
}
