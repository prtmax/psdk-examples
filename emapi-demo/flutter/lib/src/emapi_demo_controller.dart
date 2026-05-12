import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

import 'bluetooth_printer_connector.dart';
import 'emapi_formatters.dart';

class EmapiDemoController extends ChangeNotifier {
  EmapiDemoController({BluetoothPrinterConnector? connector})
    : _connector = connector ?? BluetoothPrinterConnector();

  final BluetoothPrinterConnector _connector;
  final List<DiscoveredPrinterDevice> devices = [];
  final List<String> commandLogs = [];
  final List<String> reportLogs = [];

  StreamSubscription? _scanSubscription;
  StreamSubscription<EmapiReport>? _reportSubscription;
  ConnectedDevice? _connectedDevice;
  EmapiPrinter? _printer;
  bool _disposed = false;

  bool initialized = false;
  bool bluetoothEnabled = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  String? connectedDeviceName;
  String? pendingActionLabel;
  int? knownMtu;
  int otaSentBytes = 0;
  int otaTotalBytes = 0;
  String? latestUpgradeStatus;

  bool get busy {
    return connecting || pendingActionLabel != null;
  }

  String get otaProgress {
    return otaProgressText(
      sentBytes: otaSentBytes,
      totalBytes: otaTotalBytes,
      latestStatus: latestUpgradeStatus,
    );
  }

  Future<void> init() async {
    if (initialized) {
      return;
    }
    initialized = true;
    try {
      _scanSubscription = _connector.discoveredDevices.listen((device) {
        devices.add(device);
        _notify();
      });
      bluetoothEnabled = await _connector.bluetoothIsEnabled();
      _notify();
    } catch (error) {
      _addCommandLog('初始化失败\n${formatError(error)}');
    }
  }

  Future<void> startScan() async {
    var discoveryStarted = false;
    await _runConnectionTask(
      () async {
        devices.clear();
        scanning = true;
        _notify();
        await _connector.startScan();
        discoveryStarted = true;
        bluetoothEnabled = await _connector.bluetoothIsEnabled();
        _addCommandLog('开始扫描蓝牙设备');
      },
      onFinally: () {
        if (!discoveryStarted) {
          scanning = false;
          _notify();
        }
      },
    );
  }

  Future<void> connect(DiscoveredPrinterDevice device) async {
    await _runConnectionTask(
      () async {
        connecting = true;
        _notify();
        _connectedDevice = await _connector.connect(device);
        _printer = EmapiPrinter.connectedDevice(
          connectedDevice: _connectedDevice!,
        );
        // TODO(EMAPI SDK): reports are exposed through EmapiPrinter.reports only; no public startListeningReports/stopListeningReports API exists currently.
        await _reportSubscription?.cancel();
        _reportSubscription = _printer!.reports.listen(_handleReport);
        connected = true;
        connectedDeviceName = device.name;
        _addCommandLog('已连接：${device.name}');
      },
      onFinally: () {
        connecting = false;
        scanning = false;
        _notify();
      },
    );
  }

  Future<void> disconnect() async {
    await _reportSubscription?.cancel();
    _reportSubscription = null;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _printer = null;
    connected = false;
    connectedDeviceName = null;
    latestUpgradeStatus = null;
    _addCommandLog('已断开连接');
    _notify();
  }

  Future<void> sleepShutdown() {
    return _runPrinterAction('打印机休眠关机', () async {
      await _requirePrinter().sleepShutdown();
      return '打印机休眠关机：已发送';
    });
  }

  Future<void> queryRfidUid() {
    return _runPrinterAction('查询 RFID 卡 UID', () async {
      final uid = await _requirePrinter().queryRfidUid();
      return 'RFID 卡 UID：$uid';
    });
  }

  Future<void> queryRfidCardInfo() {
    return _runPrinterAction('查询 RFID 卡信息', () async {
      final info = await _requirePrinter().queryRfidCardInfo();
      return formatRfidCardInfo(info);
    });
  }

  Future<void> queryRfidPaperLength() {
    return _runPrinterAction('查询卡内纸张长度', () async {
      final length = await _requirePrinter().queryRfidPaperLength();
      return '卡内纸张长度：$length';
    });
  }

  Future<void> setRfidAuthFailureHandling(EmapiRfidAuthFailurePolicy policy) {
    return _runPrinterAction('设置 RFID 认证失败处理', () async {
      await _requirePrinter().setRfidAuthFailureHandling(policy);
      final policyText = policy == EmapiRfidAuthFailurePolicy.forbidPrint
          ? '禁止打印'
          : '允许打印';
      return 'RFID 认证失败处理：$policyText';
    });
  }

  Future<void> setWifiConfig({required String ssid, required String password}) {
    return _runPrinterAction('设置配网信息', () async {
      await _requirePrinter().setWifiConfig(ssid: ssid, password: password);
      return '配网信息已发送：SSID=$ssid';
    });
  }

  Future<void> queryWifiConnectionState() {
    return _runPrinterAction('查询 WIFI 模块连接状态', () async {
      final state = await _requirePrinter().queryWifiConnectionState();
      return formatWifiConnectionState(state);
    });
  }

  Future<void> queryWifiHotspotInfo() {
    return _runPrinterAction('查询 WIFI 模块热点相关信息', () async {
      final info = await _requirePrinter().queryWifiHotspotInfo();
      return formatWifiHotspotInfo(info);
    });
  }

  Future<void> queryDeviceInfo() {
    return _runPrinterAction('查询打印机基本参数', () async {
      final info = await _requirePrinter().queryDeviceInfo();
      knownMtu = info.mtu;
      return formatDeviceInfo(info);
    });
  }

  Future<void> queryPrintStatus() {
    return _runPrinterAction('查询打印状态', () async {
      final status = await _requirePrinter().queryPrintStatus();
      return formatPrintStatus(status);
    });
  }

  Future<void> performOta(String filePath) {
    return _runPrinterAction('OTA 升级', () async {
      if (filePath.trim().isEmpty) {
        throw ArgumentError('请选择或输入 OTA 文件路径');
      }
      final file = File(filePath.trim());
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw ArgumentError('OTA 文件为空');
      }
      final printer = _requirePrinter();
      final chunkSize = calculateOtaChunkSize(mtu: knownMtu);
      otaSentBytes = 0;
      otaTotalBytes = bytes.length;
      _notify();
      await printer.startMainControllerOta(totalSize: bytes.length);
      var index = 0;
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = offset + chunkSize > bytes.length
            ? bytes.length
            : offset + chunkSize;
        final chunk = Uint8List.sublistView(bytes, offset, end);
        await printer.transferMainControllerOtaChunk(index: index, data: chunk);
        index += 1;
        otaSentBytes = end;
        _notify();
      }
      await printer.finishMainControllerOta();
      await printer.upgradeMainController();
      return 'OTA 升级命令已完成\n$otaProgress';
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_scanSubscription?.cancel());
    unawaited(_reportSubscription?.cancel());
    unawaited(_connectedDevice?.disconnect());
    unawaited(_connector.dispose());
    super.dispose();
  }

  Future<void> _runPrinterAction(
    String label,
    Future<String> Function() action,
  ) async {
    if (pendingActionLabel != null) {
      return;
    }
    pendingActionLabel = label;
    _notify();
    try {
      final result = await action();
      _addCommandLog('$label\n$result');
    } catch (error) {
      _addCommandLog('$label\n${formatError(error)}');
    } finally {
      pendingActionLabel = null;
      _notify();
    }
  }

  Future<void> _runConnectionTask(
    Future<void> Function() action, {
    VoidCallback? onFinally,
  }) async {
    try {
      await action();
    } catch (error) {
      _addCommandLog(formatError(error));
    } finally {
      onFinally?.call();
    }
  }

  EmapiPrinter _requirePrinter() {
    final printer = _printer;
    if (printer == null) {
      throw StateError('打印机未连接');
    }
    return printer;
  }

  void _handleReport(EmapiReport report) {
    final formatted = formatReport(report);
    if (report is EmapiUpgradeStatusReport) {
      latestUpgradeStatus = formatted;
    }
    reportLogs.insert(0, formatted);
    _notify();
  }

  void _addCommandLog(String message) {
    commandLogs.insert(0, message);
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
