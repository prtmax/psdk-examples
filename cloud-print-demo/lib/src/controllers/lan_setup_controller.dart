import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import 'android_lan_discovery_session.dart';
import 'android_multicast_lock.dart';
import 'inspected_device.dart';
import 'real_transport_helper.dart';

/// 热敏与热升华共用的连接流程；打印协议仍由各自控制器负责。
class LanSetupController extends ChangeNotifier {
  LanSetupController({
    required this.family,
    required this.inspector,
    required DemoRunMode Function() modeGetter,
    required this.simBleDevice,
    required this.simScannerFactory,
    this.feedback,
    this.bleNamePrefixFilter = '',
    AndroidMulticastLock? multicastLock,
    AndroidLanDiscoverySession? lanDiscoverySession,
    this.manualHostProber,
    this.postProvisionDiscoveryDelay = const Duration(milliseconds: 2500),
  }) : _modeGetter = modeGetter,
       _multicastLock = multicastLock ?? AndroidMulticastLock(),
       _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession();

  final CloudPrinterFamily family;
  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final DemoRunMode Function() _modeGetter;
  final ConnectedDevice<dynamic> simBleDevice;
  final LanPrinterScanner Function() simScannerFactory;
  final AndroidMulticastLock _multicastLock;
  final AndroidLanDiscoverySession _lanDiscoverySession;
  final Future<DiscoveredCloudPrinter?> Function(
    String host,
    String? networkInterface,
  )?
  manualHostProber;
  final Duration postProvisionDiscoveryDelay;
  final VerifiedPrinterIpCache _verifiedPrinterIpCache =
      VerifiedPrinterIpCache();
  String bleNamePrefixFilter;
  ConnectedDevice<dynamic>? realBleDevice;
  ProvisionResult? lastProvisionResult;
  String? lastSsid;
  List<DiscoveredCloudPrinter> discoveredPrinters = const [];
  DiscoveredCloudPrinter? selectedPrinter;
  bool busy = false;
  bool lastActionFailed = false;
  String statusMessage = '请先配网，或直接发现同一局域网内的打印机';
  bool _disposed = false;
  CloudCancelToken? _cancelToken;
  WifiProvisioner? _provisioner;
  LanPrinterScanner? _scanner;

  DemoRunMode get mode => _modeGetter();
  ConnectedDevice<dynamic> get activeBleDevice {
    final device = mode == DemoRunMode.simulation
        ? simBleDevice
        : realBleDevice;
    if (device == null ||
        device.connectionState() != ConnectionState.connected) {
      throw StateError('请先连接打印机蓝牙');
    }
    return device;
  }

  Future<void> provisionWifi({
    required String ssid,
    required String password,
    bool discoverAfterProvision = true,
  }) async {
    var provisionSucceeded = false;
    await _run('正在配置 Wi-Fi…', () async {
      lastProvisionResult = null;
      final device = activeBleDevice;
      // SDK 中这组 BLUETOOTH SETSSID / GETLINKSTATE 命令的协议名为 bluetoothAtText。
      final provisioner = SublimationAtProvisioner(device: device);
      _provisioner = provisioner;
      try {
        final result = await provisioner.provision(
          ProvisionRequest(
            protocol: WifiProvisionProtocol.bluetoothAtText,
            ssid: ssid,
            password: password,
            targetMode: WifiTargetMode.station,
            negotiatedMtu: mode == DemoRunMode.simulation
                ? 512
                : RealTransportHelper.mtuOf(device),
            settleDelay: mode == DemoRunMode.simulation
                ? const Duration(milliseconds: 15)
                : const Duration(seconds: 2),
            pollInterval: mode == DemoRunMode.simulation
                ? const Duration(milliseconds: 15)
                : const Duration(milliseconds: 500),
            cancelToken: _cancelToken,
          ),
        );
        if (_disposed) return;
        lastProvisionResult = result;
        lastSsid = ssid;
        provisionSucceeded = result.success;
        statusMessage = result.success
            ? '配网成功：${result.assignedIp ?? ssid}'
            : '配网失败：${result.message ?? result.errorCode.name}';
      } finally {
        _provisioner = null;
        await provisioner.dispose();
      }
    });
    if (!provisionSucceeded ||
        !discoverAfterProvision ||
        mode != DemoRunMode.realDevice ||
        _disposed) {
      return;
    }
    await Future<void>.delayed(postProvisionDiscoveryDelay);
    if (_disposed) return;
    await discoverPrinters();
  }

  Future<void> discoverPrinters() => _run('正在发现局域网打印机（UDP 22368）…', () async {
    final found = <String, DiscoveredCloudPrinter>{};
    final previousHost = selectedPrinter?.host;
    discoveredPrinters = const [];
    selectedPrinter = null;
    if (!_disposed) notifyListeners();

    final attempts = mode == DemoRunMode.realDevice ? 2 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (_disposed) return;
      if (attempt > 0) {
        statusMessage = '首次扫描未发现打印机，正在重建 Wi-Fi 绑定并重试（第 2/2 次）…';
        if (!_disposed) notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (_disposed) return;
      }
      await _runDiscoveryAttempt(found: found);
      if (found.isNotEmpty) break;
    }

    if (_disposed) return;
    discoveredPrinters = List.unmodifiable(found.values);
    for (final printer in discoveredPrinters) {
      if (printer.host == previousHost) selectedPrinter = printer;
    }
    selectedPrinter ??= discoveredPrinters.firstOrNull;
    statusMessage = discoveredPrinters.isEmpty
        ? '未发现局域网打印机，请确认设备已连入同一 Wi-Fi 或尝试手动输入 IP 探测'
        : '发现 ${discoveredPrinters.length} 台打印机，请选择目标设备';
  });

  Future<void> _runDiscoveryAttempt({
    required Map<String, DiscoveredCloudPrinter> found,
  }) async {
    Network? network;
    LanPrinterScanner? scanner;
    AndroidLanDiscoveryNetwork? androidNetwork;
    String? wifiInterface;
    var networkSessionHeld = false;
    var multicastLockHeld = false;
    try {
      if (mode == DemoRunMode.realDevice) {
        try {
          networkSessionHeld = await _lanDiscoverySession.begin();
          if (networkSessionHeld) {
            _recordDiscoveryLog('Android 已临时绑定当前 Wi-Fi 网络');
            try {
              androidNetwork = await _lanDiscoverySession.currentNetwork();
              wifiInterface = androidNetwork?.interfaceName;
            } catch (error) {
              _recordDiscoveryLog('Android Wi-Fi 网络信息读取失败：$error');
            }
          }
        } catch (error) {
          _recordDiscoveryLog('Android Wi-Fi 网络绑定失败：$error');
        }
        try {
          multicastLockHeld = await _multicastLock.acquire();
        } catch (error) {
          _recordDiscoveryLog('Android 多播锁开启失败：$error');
        }

        try {
          wifiInterface ??= await DefaultInkjetNetworkBinder()
              .resolveWifiInterfaceName();
        } catch (_) {}

        final activeAndroidNetwork = androidNetwork;
        LocalIpv4InterfacesProvider localIpv4Provider =
            defaultLocalIpv4InterfacesProvider;
        if (activeAndroidNetwork != null) {
          localIpv4Provider = () async => <LocalIpv4Interface>[
            LocalIpv4Interface(
              name:
                  activeAndroidNetwork.interfaceName ??
                  wifiInterface ??
                  'wlan0',
              address: activeAndroidNetwork.address,
              prefixLength: activeAndroidNetwork.prefixLength,
            ),
          ];
          _recordDiscoveryLog(
            'Wi-Fi 地址 ${activeAndroidNetwork.address}/${activeAndroidNetwork.prefixLength}',
          );
        }
        network = Network.scoped(
          localIpv4Provider: localIpv4Provider,
          verifiedIpCache: _verifiedPrinterIpCache,
          debugLogger: (message) => _recordDiscoveryLog(message),
        );
        scanner = network.createScanner(
          networkInterface: wifiInterface,
          enableSubnetHostEnumerationFallback: true,
        );
      } else {
        scanner = simScannerFactory();
      }
      _scanner = scanner;

      await for (final printer in scanner.scan(
        LanScanOptions(
          protocols: const {LanDiscoveryProtocol.udp22368Text},
          timeout: mode == DemoRunMode.simulation
              ? const Duration(milliseconds: 120)
              : const Duration(seconds: 5),
          probeInterval: mode == DemoRunMode.simulation
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 1),
          cancelToken: _cancelToken,
        ),
      )) {
        final key = printer.host.isEmpty ? printer.id : printer.host;
        final enriched =
            (printer.networkInterface == null && wifiInterface != null)
            ? DiscoveredCloudPrinter(
                id: printer.id,
                displayName: printer.displayName,
                family: printer.family,
                discoveredVia: printer.discoveredVia,
                host: printer.host,
                port: printer.port,
                model: printer.model,
                serialNumber: printer.serialNumber,
                firmwareVersion: printer.firmwareVersion,
                macAddress: printer.macAddress,
                wlanMacAddress: printer.wlanMacAddress,
                wifiSsid: printer.wifiSsid,
                networkInterface: wifiInterface,
                metadata: printer.metadata,
                lastSeen: printer.lastSeen,
              )
            : printer;
        found[key] = found[key]?.mergeWith(enriched) ?? enriched;
        if (enriched.host.isNotEmpty) {
          _verifiedPrinterIpCache.remember(enriched.host);
        }
      }
    } finally {
      _scanner = null;
      await scanner?.dispose();
      network?.dispose();
      if (multicastLockHeld) {
        try {
          await _multicastLock.release();
        } catch (_) {}
      }
      if (networkSessionHeld) {
        try {
          await _lanDiscoverySession.end();
        } catch (_) {}
      }
    }
  }

  Future<void> probeManualHost(String rawHost) async {
    final host = rawHost.trim();
    if (host.isEmpty ||
        SubnetCalculator.ipv4ToInt(host) == null ||
        !SubnetCalculator.isUsablePrinterHost(host)) {
      lastActionFailed = true;
      statusMessage = '请输入有效的 IPv4 地址（例如 192.168.200.161）';
      feedback?.emitError(statusMessage, family: family);
      if (!_disposed) notifyListeners();
      return;
    }

    await _run('正在探测 $host:9100…', () async {
      var networkSessionHeld = false;
      String? wifiInterface;
      try {
        if (mode == DemoRunMode.realDevice) {
          try {
            networkSessionHeld = await _lanDiscoverySession.begin();
            if (networkSessionHeld) {
              try {
                final androidNetwork = await _lanDiscoverySession
                    .currentNetwork();
                wifiInterface = androidNetwork?.interfaceName;
              } catch (_) {}
            }
          } catch (error) {
            _recordDiscoveryLog('Android Wi-Fi 网络绑定失败：$error');
          }
          wifiInterface ??= await DefaultInkjetNetworkBinder()
              .resolveWifiInterfaceName();
        }

        DiscoveredCloudPrinter? probed;
        if (manualHostProber != null) {
          probed = await manualHostProber!(host, wifiInterface);
        } else if (mode == DemoRunMode.realDevice) {
          final binder = InspectedNetworkBinder(inspector, family);
          final dev = await binder.connectDevice(
            host,
            9100,
            timeout: const Duration(seconds: 4),
            networkInterface: wifiInterface,
          );
          await dev.disconnect();
          probed = DiscoveredCloudPrinter(
            id: host,
            displayName: host,
            family: family,
            host: host,
            port: 9100,
            networkInterface: wifiInterface,
          );
        }

        if (probed == null) {
          statusMessage = '未在 $host:9100 检测到兼容打印机';
          return;
        }
        final updated = List<DiscoveredCloudPrinter>.from(discoveredPrinters);
        final idx = updated.indexWhere((p) => p.host == probed!.host);
        if (idx >= 0) {
          updated[idx] = updated[idx].mergeWith(probed);
        } else {
          updated.add(probed);
        }
        discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(updated);
        selectedPrinter = idx >= 0 ? discoveredPrinters[idx] : probed;
        _verifiedPrinterIpCache.remember(probed.host);
        statusMessage =
            '已通过直连发现：${selectedPrinter!.displayName} (${selectedPrinter!.host}:${selectedPrinter!.port})';
      } finally {
        if (networkSessionHeld) {
          try {
            await _lanDiscoverySession.end();
          } catch (_) {}
        }
      }
    });
  }

  void _recordDiscoveryLog(String message) {
    inspector.recordText(
      family: family,
      transport: 'Discovery',
      direction: WireDirection.rx,
      text: message,
      decodedSummary: message,
    );
  }

  void selectPrinter(DiscoveredCloudPrinter printer) {
    selectedPrinter = printer;
    lastActionFailed = false;
    statusMessage =
        '已选择 ${printer.displayName} (${printer.host}:${printer.port})';
    feedback?.emitInfo(statusMessage, family: family);
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(String message, Future<void> Function() action) async {
    if (_disposed || busy) return;
    busy = true;
    lastActionFailed = false;
    _cancelToken = CloudCancelToken();
    statusMessage = message;
    notifyListeners();
    try {
      await action();
      lastActionFailed = DemoFeedbackCenter.isErrorMessage(statusMessage);
    } catch (error) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$error')}';
    } finally {
      busy = false;
      _cancelToken = null;
      if (!_disposed) {
        feedback?.emitOutcome(
          statusMessage,
          forceError: lastActionFailed,
          family: family,
        );
        notifyListeners();
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelToken?.cancel('连接流程已关闭');
    await _provisioner?.dispose();
    await _scanner?.dispose();
    await realBleDevice?.disconnect();
    await simBleDevice.disconnect();
    super.dispose();
  }
}
