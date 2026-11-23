import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import 'real_transport_helper.dart';

/// 热敏与热升华共用的连接流程；打印协议仍由各自控制器负责。
class LanSetupController extends ChangeNotifier {
  LanSetupController({
    required this.family,
    required this.inspector,
    required DemoRunMode Function() modeGetter,
    required this.simBleDevice,
    required this.simScannerFactory,
  }) : _modeGetter = modeGetter;

  final CloudPrinterFamily family;
  final ProtocolInspectorController inspector;
  final DemoRunMode Function() _modeGetter;
  final ConnectedDevice<dynamic> simBleDevice;
  final LanPrinterScanner Function() simScannerFactory;
  ConnectedDevice<dynamic>? realBleDevice;
  ProvisionResult? lastProvisionResult;
  String? lastSsid;
  List<DiscoveredCloudPrinter> discoveredPrinters = const [];
  DiscoveredCloudPrinter? selectedPrinter;
  bool busy = false;
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
  }) => _run('正在配置 Wi-Fi…', () async {
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
      statusMessage = result.success
          ? '配网成功：${result.assignedIp ?? ssid}'
          : '配网失败：${result.message ?? result.errorCode.name}';
    } finally {
      _provisioner = null;
      await provisioner.dispose();
    }
  });

  Future<void> discoverPrinters() => _run('正在发现局域网打印机（UDP 22368）…', () async {
    // 两类真机统一走 Network，保留网卡信息供后续 TCP 连接使用。
    final network = mode == DemoRunMode.realDevice
        ? Network.scoped(
            debugLogger: (message) => inspector.recordText(
              family: family,
              transport: 'Network',
              direction: WireDirection.rx,
              text: message,
              decodedSummary: message,
            ),
          )
        : null;
    final scanner = network?.createScanner() ?? simScannerFactory();
    _scanner = scanner;
    final found = <String, DiscoveredCloudPrinter>{};
    final previousHost = selectedPrinter?.host;
    discoveredPrinters = const [];
    selectedPrinter = null;
    try {
      await for (final printer in scanner.scan(
        LanScanOptions(
          protocols: const {LanDiscoveryProtocol.udp22368Text},
          timeout: mode == DemoRunMode.simulation
              ? const Duration(milliseconds: 120)
              : const Duration(seconds: 4),
          probeInterval: mode == DemoRunMode.simulation
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 1),
          cancelToken: _cancelToken,
        ),
      )) {
        final key = printer.host.isEmpty ? printer.id : printer.host;
        found[key] = found[key]?.mergeWith(printer) ?? printer;
      }
      if (_disposed) return;
      discoveredPrinters = List.unmodifiable(found.values);
      for (final printer in discoveredPrinters) {
        if (printer.host == previousHost) selectedPrinter = printer;
      }
      selectedPrinter ??= discoveredPrinters.firstOrNull;
      statusMessage = '发现 ${discoveredPrinters.length} 台打印机，请选择目标设备';
    } finally {
      _scanner = null;
      await scanner.dispose();
      network?.dispose();
    }
  });

  void selectPrinter(DiscoveredCloudPrinter printer) {
    selectedPrinter = printer;
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(String message, Future<void> Function() action) async {
    if (_disposed || busy) return;
    busy = true;
    _cancelToken = CloudCancelToken();
    statusMessage = message;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      statusMessage = '操作失败：$error';
    } finally {
      busy = false;
      _cancelToken = null;
      if (!_disposed) notifyListeners();
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
