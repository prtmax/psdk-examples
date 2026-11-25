import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/protocol_inspector.dart';
import 'real_transport_helper.dart';

/// 热敏与热升华共用的连接与统一局域网发现流程；打印协议仍由各自控制器负责。
class LanSetupController extends ChangeNotifier {
  LanSetupController({
    required this.family,
    required this.inspector,
    this.feedback,
    this.bleNamePrefixFilter = '',
    VerifiedPrinterIpCache? ipCache,
    AndroidMulticastLock? multicastLock,
    AndroidLanDiscoverySession? lanDiscoverySession,
    LanPrinterDiscovery? discovery,
    this.manualHostProber,
    this.scannerFactory,
    this.useAndroidDiscoveryHooks = true,
    this.postProvisionDiscoveryDelay = const Duration(milliseconds: 2500),
    this.provisionSettleDelay = const Duration(seconds: 2),
    this.provisionPollInterval = const Duration(milliseconds: 500),
    this.scanTimeout = const Duration(seconds: 5),
    this.scanProbeInterval = const Duration(seconds: 1),
    this.discoveryAttempts = 2,
  }) : _verifiedPrinterIpCache = ipCache ?? VerifiedPrinterIpCache(),
       _multicastLock = multicastLock ?? AndroidMulticastLock(),
       _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession(),
       _discoveryOverride = discovery;

  final CloudPrinterFamily family;
  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final AndroidMulticastLock _multicastLock;
  final AndroidLanDiscoverySession _lanDiscoverySession;
  final LanPrinterDiscovery? _discoveryOverride;
  final Future<DiscoveredCloudPrinter?> Function(
    String host,
    String? networkInterface,
  )?
  manualHostProber;
  final LanPrinterScanner Function()? scannerFactory;
  final bool useAndroidDiscoveryHooks;
  final Duration postProvisionDiscoveryDelay;
  final Duration provisionSettleDelay;
  final Duration provisionPollInterval;
  final Duration scanTimeout;
  final Duration scanProbeInterval;
  final int discoveryAttempts;
  final VerifiedPrinterIpCache _verifiedPrinterIpCache;

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
  LanPrinterDiscovery? _activeDiscovery;

  ConnectedDevice<dynamic> get activeBleDevice {
    final device = realBleDevice;
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
            negotiatedMtu: RealTransportHelper.mtuOf(device),
            settleDelay: provisionSettleDelay,
            pollInterval: provisionPollInterval,
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
    if (!provisionSucceeded || !discoverAfterProvision || _disposed) {
      return;
    }
    await Future<void>.delayed(postProvisionDiscoveryDelay);
    if (_disposed) return;
    await discoverPrinters();
  }

  Future<void> discoverPrinters({
    Set<LanDiscoveryProtocol> protocols = LanPrinterDiscovery.allProtocols,
  }) => _run('正在发现局域网打印机…', () async {
    final found = <DiscoveredCloudPrinter>[];
    final previousSelected = selectedPrinter;
    discoveredPrinters = const [];
    selectedPrinter = null;
    if (!_disposed) notifyListeners();

    final attempts = discoveryAttempts.clamp(1, 5);
    final discovery =
        _discoveryOverride ??
        LanPrinterDiscovery(
          lanDiscoverySession: _lanDiscoverySession,
          multicastLock: _multicastLock,
          ipCache: _verifiedPrinterIpCache,
          scannerFactory: scannerFactory,
          useAndroidDiscoveryHooks: useAndroidDiscoveryHooks,
          debugLogger: _recordDiscoveryLog,
        );
    _activeDiscovery = discovery;

    try {
      await for (final printer in discovery.discover(
        protocols: protocols,
        timeout: scanTimeout,
        probeInterval: scanProbeInterval,
        maxAttempts: attempts,
        cancelToken: _cancelToken,
        onAttempt: (attempt, maxAttempts) {
          if (_disposed) return;
          if (attempt > 1) {
            statusMessage =
                '首次扫描未发现打印机，正在重建 Wi-Fi 绑定并重试（第 $attempt/$maxAttempts 次）…';
            notifyListeners();
          }
        },
      )) {
        if (_disposed) break;
        _mergeDiscoveredPrinter(found, printer);
        discoveredPrinters = List.unmodifiable(found);
        selectedPrinter = _pickSelectedPrinter(found, previousSelected);
        statusMessage = '已发现 ${discoveredPrinters.length} 台打印机…';
        notifyListeners();
      }
    } finally {
      if (identical(_activeDiscovery, discovery)) {
        _activeDiscovery = null;
      }
      if (!identical(discovery, _discoveryOverride)) {
        await discovery.dispose();
      }
    }

    if (_disposed) return;
    discoveredPrinters = List.unmodifiable(found);
    selectedPrinter = _pickSelectedPrinter(found, previousSelected);
    statusMessage = discoveredPrinters.isEmpty
        ? '未发现局域网打印机，请确认设备已连入同一 Wi-Fi 或尝试手动输入 IP 探测'
        : '发现 ${discoveredPrinters.length} 台打印机，请选择目标设备';
  });

  static void _mergeDiscoveredPrinter(
    List<DiscoveredCloudPrinter> list,
    DiscoveredCloudPrinter incoming,
  ) {
    final idx = list.indexWhere((p) => _isSamePrinter(p, incoming));
    if (idx >= 0) {
      list[idx] = list[idx].mergeWith(incoming);
    } else {
      list.add(incoming);
    }
  }

  static DiscoveredCloudPrinter? _pickSelectedPrinter(
    List<DiscoveredCloudPrinter> list,
    DiscoveredCloudPrinter? previous,
  ) {
    if (list.isEmpty) return null;
    if (previous != null) {
      for (final p in list) {
        if (_isSamePrinter(p, previous)) {
          return p;
        }
      }
    }
    return list.first;
  }

  static bool _isSamePrinter(
    DiscoveredCloudPrinter left,
    DiscoveredCloudPrinter right,
  ) {
    final leftHost = left.host.trim().toLowerCase();
    final rightHost = right.host.trim().toLowerCase();
    if (leftHost.isNotEmpty &&
        leftHost == rightHost &&
        left.port == right.port) {
      return true;
    }
    final leftSerial = (left.serialNumber ?? '').trim().toUpperCase();
    final rightSerial = (right.serialNumber ?? '').trim().toUpperCase();
    if (leftSerial.isNotEmpty && leftSerial == rightSerial) return true;
    final leftMac = (left.macAddress ?? '').replaceAll(':', '').toUpperCase();
    final rightMac = (right.macAddress ?? '').replaceAll(':', '').toUpperCase();
    return leftMac.isNotEmpty && leftMac == rightMac;
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
        if (useAndroidDiscoveryHooks) {
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
          wifiInterface ??= await defaultResolveWifiInterfaceName();
        }

        DiscoveredCloudPrinter? probed;
        if (manualHostProber != null) {
          probed = await manualHostProber!(host, wifiInterface);
        } else {
          final network = RealTransportHelper(inspector).createRealNetwork();
          try {
            final dev = await network.connect(
              host,
              9100,
              networkInterface: wifiInterface,
            );
            await dev.disconnect();
          } finally {
            network.dispose();
          }
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
        upsertAndSelectPrinter(probed);
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

  void upsertAndSelectPrinter(DiscoveredCloudPrinter printer) {
    final updated = List<DiscoveredCloudPrinter>.from(discoveredPrinters);
    _mergeDiscoveredPrinter(updated, printer);
    discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(updated);
    selectedPrinter = _pickSelectedPrinter(updated, printer);
    _verifiedPrinterIpCache.remember(printer.host);
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
    await _activeDiscovery?.dispose();
    await _discoveryOverride?.dispose();
    await realBleDevice?.disconnect();
    super.dispose();
  }
}
