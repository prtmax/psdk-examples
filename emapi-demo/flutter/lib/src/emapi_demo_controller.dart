import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

import 'bluetooth_printer_connector.dart';
import 'entities/emapi_demo_log_entry.dart';
import 'emapi_formatters.dart';

class EmapiDemoController extends ChangeNotifier {
  EmapiDemoController({BluetoothPrinterConnector? connector})
    : _connector = connector ?? BluetoothPrinterConnector();

  final BluetoothPrinterConnector _connector;
  final List<DiscoveredPrinterDevice> devices = [];
  final List<EmapiDemoLogEntry> requestLogs = [];
  final List<EmapiDemoLogEntry> commandLogs = [];
  final List<EmapiDemoLogEntry> reportLogs = [];

  StreamSubscription? _scanSubscription;
  StreamSubscription<EmapiReport>? _reportSubscription;
  ConnectedDevice? _connectedDevice;
  _TracingEmapiConnection? _tracingConnection;
  EmapiPrinter? _printer;
  bool _disposed = false;

  bool initialized = false;
  bool bluetoothEnabled = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool simulationMode = false;
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
    if (simulationMode) {
      devices
        ..clear()
        ..add(_simulatedDevice());
      scanning = false;
      bluetoothEnabled = true;
      _addCommandLog('模拟模式：已生成 1 台模拟蓝牙设备');
      _notify();
      return;
    }
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

  Future<void> stopScan() async {
    await _runConnectionTask(() async {
      await _connector.stopScan();
      scanning = false;
      _addCommandLog(simulationMode ? '模拟模式：扫描已停止' : '已停止扫描');
      _notify();
    });
  }

  Future<void> connect(DiscoveredPrinterDevice device) async {
    await _runConnectionTask(
      () async {
        connecting = true;
        _notify();
        if (simulationMode || device.simulated) {
          _connectedDevice = null;
          _printer = null;
          await _reportSubscription?.cancel();
          _emitSimulatedReport(
            EmapiBluetoothConnectionReport(
              _simulatedBluetoothReportCommand,
              state: 1,
            ),
          );
        } else {
          _connectedDevice = await _connector.connect(device);
          _tracingConnection = _TracingEmapiConnection(
            ConnectedDeviceEmapiConnection(_connectedDevice!),
          );
          _printer = EmapiPrinter(connection: _tracingConnection!);
          // TODO(EMAPI SDK): reports are exposed through EmapiPrinter.reports only; no public startListeningReports/stopListeningReports API exists currently.
          await _reportSubscription?.cancel();
          _reportSubscription = _printer!.reports.listen(_handleReport);
        }
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
    _tracingConnection = null;
    _printer = null;
    connected = false;
    connectedDeviceName = null;
    latestUpgradeStatus = null;
    _addCommandLog('已断开连接');
    _notify();
  }

  Future<void> sleepShutdown() {
    return _runPrinterAction(
      '打印机休眠关机',
      _sleepShutdownCommand,
      () async {
        if (simulationMode) {
          _emitSimulatedReport(
            EmapiFlowControlReport(
              _simulatedFlowControlReportCommand,
              state: 0,
            ),
          );
          return '模拟模式：休眠关机指令已接收';
        }
        await _requirePrinter().sleepShutdown();
        return '打印机休眠关机：已发送';
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentSystem,
          child: EmapiConstants.childSleepShutdown,
        );
      },
    );
  }

  Future<void> queryRfidUid() {
    return _runPrinterAction(
      '查询 RFID 卡 UID',
      _queryRfidUidCommand,
      () async {
        if (simulationMode) {
          return 'RFID 卡 UID：04AABBCCDDEE';
        }
        final uid = await _requirePrinter().queryRfidUid();
        return 'RFID 卡 UID：$uid';
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentRfid,
          child: EmapiConstants.childRfidUid,
          payload: '04AABBCCDDEE'.codeUnits,
        );
      },
    );
  }

  Future<void> queryRfidCardInfo() {
    return _runPrinterAction(
      '查询 RFID 卡信息',
      _queryRfidCardInfoCommand,
      () async {
        if (simulationMode) {
          return formatRfidCardInfo(
            const EmapiRfidCardInfo(
              paperModel: 'SIM-L801',
              paperLength: '40m',
              paperWidth: '80mm',
              paperColor: 'white',
              paperMaterialNumber: 'SIM-PAPER-01',
            ),
          );
        }
        final info = await _requirePrinter().queryRfidCardInfo();
        return formatRfidCardInfo(info);
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentRfid,
          child: EmapiConstants.childRfidCardInfo,
          payload: Tlv.encode([
            TlvEntry.string(0x01, 'SIM-L801'),
            TlvEntry.string(0x02, '40m'),
            TlvEntry.string(0x03, '80mm'),
            TlvEntry.string(0x04, 'white'),
            TlvEntry.string(0x05, 'SIM-PAPER-01'),
          ]),
        );
      },
    );
  }

  Future<void> queryRfidPaperLength() {
    return _runPrinterAction(
      '查询卡内纸张长度',
      _queryRfidPaperLengthCommand,
      () async {
        if (simulationMode) {
          return '卡内纸张长度：123456';
        }
        final length = await _requirePrinter().queryRfidPaperLength();
        return '卡内纸张长度：$length';
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentRfid,
          child: EmapiConstants.childRfidPaperLength,
          payload: EmapiPayload.uint32(123456),
        );
      },
    );
  }

  Future<void> setRfidAuthFailureHandling(EmapiRfidAuthFailurePolicy policy) {
    return _runPrinterAction(
      '设置 RFID 认证失败处理',
      _setRfidAuthFailureHandlingCommand(policy),
      () async {
        if (simulationMode) {
          final policyText = policy == EmapiRfidAuthFailurePolicy.forbidPrint
              ? '禁止打印'
              : '允许打印';
          return '模拟模式：RFID 认证失败处理已设置为 $policyText';
        }
        await _requirePrinter().setRfidAuthFailureHandling(policy);
        final policyText = policy == EmapiRfidAuthFailurePolicy.forbidPrint
            ? '禁止打印'
            : '允许打印';
        return 'RFID 认证失败处理：$policyText';
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentRfid,
          child: EmapiConstants.childRfidAuthFailureHandling,
        );
      },
    );
  }

  Future<void> setWifiConfig({required String ssid, required String password}) {
    return _runPrinterAction(
      '设置配网信息',
      _setWifiConfigCommand(ssid, password),
      () async {
        if (simulationMode) {
          _emitSimulatedReport(
            EmapiWifiConfigStatusReport(
              _simulatedWifiReportCommand,
              ssid: ssid.isEmpty ? 'SIM_WIFI' : ssid,
              state: 1,
            ),
          );
          return '模拟模式：配网信息已发送：SSID=${ssid.isEmpty ? 'SIM_WIFI' : ssid}';
        }
        await _requirePrinter().setWifiConfig(ssid: ssid, password: password);
        return '配网信息已发送：SSID=$ssid';
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typePassthroughResponse,
          parent: EmapiConstants.parentWifi,
          child: EmapiConstants.childWifiConfig,
        );
      },
    );
  }

  Future<void> queryWifiConnectionState() {
    return _runPrinterAction(
      '查询 WIFI 模块连接状态',
      _queryWifiConnectionStateCommand,
      () async {
        if (simulationMode) {
          return formatWifiConnectionState(
            EmapiWifiConnectionState.iotConnected,
          );
        }
        final state = await _requirePrinter().queryWifiConnectionState();
        return formatWifiConnectionState(state);
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typePassthroughResponse,
          parent: EmapiConstants.parentWifi,
          child: EmapiConstants.childWifiConnectionState,
          payload: const [0x02],
        );
      },
    );
  }

  Future<void> queryWifiHotspotInfo() {
    return _runPrinterAction(
      '查询 WIFI 模块热点相关信息',
      _queryWifiHotspotInfoCommand,
      () async {
        if (simulationMode) {
          return formatWifiHotspotInfo(
            const EmapiWifiHotspotInfo(
              ssid: 'SIM_AP',
              rssi: -42,
              ip: '192.168.4.1',
              port: '9100',
            ),
          );
        }
        final info = await _requirePrinter().queryWifiHotspotInfo();
        return formatWifiHotspotInfo(info);
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typePassthroughResponse,
          parent: EmapiConstants.parentWifi,
          child: EmapiConstants.childWifiHotspotInfo,
          payload: Tlv.encode([
            TlvEntry.string(0x01, 'SIM_AP'),
            TlvEntry.uint16(0x02, -42 & 0xFFFF),
            TlvEntry.string(0x03, '192.168.4.1'),
            TlvEntry.string(0x04, '9100'),
          ]),
        );
      },
    );
  }

  Future<void> queryDeviceInfo() {
    return _runPrinterAction(
      '查询打印机基本参数',
      _queryDeviceInfoCommand,
      () async {
        if (simulationMode) {
          final info = EmapiPrinterInfo(
            deviceType: 'simulator',
            deviceModel: 'EMAPI-SIM-01',
            brand: 'PSDK',
            serialNumber: 'SIM0000001',
            hardwareVersion: 'HW-SIM',
            softwareVersion: 'SW-SIM',
            bootVersion: 'BOOT-SIM',
            mtu: 512,
          );
          knownMtu = info.mtu;
          return formatDeviceInfo(info);
        }
        final info = await _requirePrinter().queryDeviceInfo();
        knownMtu = info.mtu;
        return formatDeviceInfo(info);
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentSystem,
          child: EmapiConstants.childDeviceInfo,
          payload: Tlv.encode([
            TlvEntry.string(0x01, 'simulator'),
            TlvEntry.string(0x02, 'EMAPI-SIM-01'),
            TlvEntry.string(0x03, 'PSDK'),
            TlvEntry.string(0x04, 'SIM0000001'),
            TlvEntry.string(0x05, 'HW-SIM'),
            TlvEntry.string(0x06, 'SW-SIM'),
            TlvEntry.string(0x07, 'BOOT-SIM'),
            TlvEntry.uint16(EmapiConstants.tagMtu, 512),
          ]),
        );
      },
    );
  }

  Future<void> queryPrintStatus() {
    return _runPrinterAction(
      '查询打印状态',
      _queryPrintStatusCommand,
      () async {
        if (simulationMode) {
          return formatPrintStatus(
            const EmapiPrintStatus(
              paperStatus: 1,
              coverStatus: 0,
              lowBattery: 0,
              overheat: 0,
              batteryPercent: 86,
              batteryVoltage: 7400,
              tphTemperature: 28,
            ),
          );
        }
        final status = await _requirePrinter().queryPrintStatus();
        return formatPrintStatus(status);
      },
      simulatedResponseBytes: () {
        return _responseBytes(
          type: EmapiConstants.typeResponse,
          parent: EmapiConstants.parentPrinter,
          child: EmapiConstants.childPrintStatus,
          payload: Tlv.encode([
            TlvEntry.uint8(0x01, 1),
            TlvEntry.uint8(0x02, 0),
            TlvEntry.uint8(0x03, 0),
            TlvEntry.uint8(0x04, 0),
            TlvEntry.uint8(0x05, 86),
            TlvEntry.uint16(0x06, 7400),
            TlvEntry.uint8(0x07, 28),
          ]),
        );
      },
    );
  }

  Future<void> performOta(String filePath) {
    Uint8List? otaBytes;
    return _runPrinterAction('OTA 升级', null, () async {
      final bytes = simulationMode
          ? Uint8List.fromList(
              List<int>.generate(2048, (index) => index & 0xFF),
            )
          : await _readOtaBytes(filePath);
      if (bytes.isEmpty) {
        throw ArgumentError('OTA 文件为空');
      }
      otaBytes = bytes;
      final chunkSize = calculateOtaChunkSize(mtu: knownMtu);
      otaSentBytes = 0;
      otaTotalBytes = bytes.length;
      _addRequestLog(
        EmapiDemoLogEntry(
          title: 'OTA 升级文件',
          message: '准备发送 ${bytes.length} bytes，chunkSize=$chunkSize',
          bytes: bytes,
        ),
      );
      _notify();
      if (!simulationMode) {
        final printer = _requirePrinter();
        await printer.startMainControllerOta(totalSize: bytes.length);
        await _transferOtaBytes(
          printer: printer,
          bytes: bytes,
          chunkSize: chunkSize,
        );
        await printer.finishMainControllerOta();
        await printer.upgradeMainController();
      } else {
        await _simulateOtaTransfer(bytes: bytes, chunkSize: chunkSize);
      }
      return '${simulationMode ? '模拟模式：' : ''}OTA 升级命令已完成\n$otaProgress';
    }, simulatedResponseBytes: () => otaBytes);
  }

  Future<void> setSimulationMode(bool enabled) async {
    if (simulationMode == enabled) {
      return;
    }
    if (connected) {
      await disconnect();
    }
    simulationMode = enabled;
    devices.clear();
    scanning = false;
    if (enabled) {
      bluetoothEnabled = true;
    } else {
      try {
        bluetoothEnabled = await _connector.bluetoothIsEnabled();
      } catch (error) {
        bluetoothEnabled = false;
        _addCommandLog('蓝牙状态检查失败\n${formatError(error)}');
      }
    }
    _addCommandLog(enabled ? '已开启模拟模式' : '已关闭模拟模式');
    _notify();
  }

  Future<Uint8List> _readOtaBytes(String filePath) async {
    if (filePath.trim().isEmpty) {
      throw ArgumentError('请选择或输入 OTA 文件路径');
    }
    final file = File(filePath.trim());
    return file.readAsBytes();
  }

  Future<void> _transferOtaBytes({
    required EmapiPrinter printer,
    required Uint8List bytes,
    required int chunkSize,
  }) async {
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
  }

  Future<void> _simulateOtaTransfer({
    required Uint8List bytes,
    required int chunkSize,
  }) async {
    _emitSimulatedReport(
      EmapiUpgradeStatusReport(_simulatedUpgradeReportCommand, status: 1),
    );
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      final end = offset + chunkSize > bytes.length
          ? bytes.length
          : offset + chunkSize;
      otaSentBytes = end;
      _notify();
    }
    _emitSimulatedReport(
      EmapiUpgradeStatusReport(_simulatedUpgradeReportCommand, status: 0),
    );
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
    EmapiCommand? requestCommand,
    Future<String> Function() action, {
    Uint8List? Function()? simulatedResponseBytes,
  }) async {
    if (pendingActionLabel != null) {
      return;
    }
    pendingActionLabel = label;
    final traceStart = _tracingConnection?.frames.length ?? 0;
    if (requestCommand != null &&
        (simulationMode || _tracingConnection == null)) {
      _addRequestLog(
        EmapiDemoLogEntry(
          title: label,
          message: requestCommand.toString(),
          bytes: Uint8List.fromList(FrameCodec.encode(requestCommand)),
        ),
      );
    }
    _notify();
    try {
      final result = await action();
      final traceBytes = _traceBytesSince(traceStart, _TraceDirection.inbound);
      _addActualOutboundLog(label, traceStart);
      _addCommandEntry(
        EmapiDemoLogEntry(
          title: label,
          message: result,
          bytes: traceBytes ?? simulatedResponseBytes?.call(),
        ),
      );
    } catch (error) {
      final traceBytes = _traceBytesSince(traceStart, _TraceDirection.inbound);
      _addActualOutboundLog(label, traceStart);
      _addCommandEntry(
        EmapiDemoLogEntry(
          title: label,
          message: formatError(error),
          bytes: traceBytes ?? simulatedResponseBytes?.call(),
        ),
      );
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
    reportLogs.insert(
      0,
      EmapiDemoLogEntry(
        title: '上报解析',
        message: formatted,
        bytes: Uint8List.fromList(FrameCodec.encode(report.command)),
      ),
    );
    _notify();
  }

  void _addCommandLog(String message) {
    _addCommandEntry(EmapiDemoLogEntry(title: '系统消息', message: message));
  }

  void _addCommandEntry(EmapiDemoLogEntry entry) {
    commandLogs.insert(0, entry);
    _notify();
  }

  void _addRequestLog(EmapiDemoLogEntry entry) {
    requestLogs.insert(0, entry);
    _notify();
  }

  void _addActualOutboundLog(String label, int traceStart) {
    final outboundBytes = _traceBytesSince(
      traceStart,
      _TraceDirection.outbound,
    );
    if (outboundBytes == null) {
      return;
    }
    _addRequestLog(
      EmapiDemoLogEntry(
        title: '$label 实际发送',
        message: '真实连接写出的帧数据',
        bytes: outboundBytes,
      ),
    );
  }

  void _emitSimulatedReport(EmapiReport report) {
    _handleReport(report);
  }

  DiscoveredPrinterDevice _simulatedDevice() {
    return DiscoveredPrinterDevice(
      name: 'EMAPI 模拟打印机',
      mac: 'SIM-00-00-EMAPI',
      rssi: -38,
      protocol: BluetoothProtocol.classic,
      simulated: true,
    );
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Uint8List? _traceBytesSince(int start, _TraceDirection direction) {
    final frames = _tracingConnection?.frames;
    if (frames == null || start >= frames.length) {
      return null;
    }
    final selected = frames
        .skip(start)
        .where((frame) => frame.direction == direction);
    final bytes = <int>[];
    for (final frame in selected) {
      if (bytes.isNotEmpty) {
        bytes.addAll([0x0D, 0x0A]);
      }
      bytes.addAll(frame.bytes);
    }
    return bytes.isEmpty ? null : Uint8List.fromList(bytes);
  }
}

Uint8List _responseBytes({
  required int type,
  required int parent,
  required int child,
  List<int> payload = const [],
}) {
  return Uint8List.fromList(
    FrameCodec.encode(
      EmapiCommand(type: type, parent: parent, child: child, payload: payload),
    ),
  );
}

enum _TraceDirection { outbound, inbound }

class _TraceFrame {
  const _TraceFrame({required this.direction, required this.bytes});

  final _TraceDirection direction;
  final Uint8List bytes;
}

class _TracingEmapiConnection implements EmapiConnection {
  _TracingEmapiConnection(this._inner);

  final EmapiConnection _inner;
  final List<_TraceFrame> frames = [];

  @override
  Future<void> write(List<int> data) async {
    frames.add(
      _TraceFrame(
        direction: _TraceDirection.outbound,
        bytes: Uint8List.fromList(data),
      ),
    );
    await _inner.write(data);
  }

  @override
  Future<List<int>> read({required Duration timeout}) async {
    final data = await _inner.read(timeout: timeout);
    frames.add(
      _TraceFrame(
        direction: _TraceDirection.inbound,
        bytes: Uint8List.fromList(data),
      ),
    );
    return data;
  }
}

final _simulatedBluetoothReportCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentReport,
  child: EmapiConstants.childReportBluetoothConnection,
);

final _simulatedFlowControlReportCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentReport,
  child: EmapiConstants.childReportFlowControl,
);

final _simulatedUpgradeReportCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentReport,
  child: EmapiConstants.childReportUpgradeStatus,
);

final _simulatedWifiReportCommand = EmapiCommand(
  type: EmapiConstants.typePassthroughRequest,
  parent: EmapiConstants.parentWifi,
  child: EmapiConstants.childWifiConfigStatus,
);

final _sleepShutdownCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentSystem,
  child: EmapiConstants.childSleepShutdown,
);

final _queryRfidUidCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentRfid,
  child: EmapiConstants.childRfidUid,
);

final _queryRfidCardInfoCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentRfid,
  child: EmapiConstants.childRfidCardInfo,
);

final _queryRfidPaperLengthCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentRfid,
  child: EmapiConstants.childRfidPaperLength,
);

EmapiCommand _setRfidAuthFailureHandlingCommand(
  EmapiRfidAuthFailurePolicy policy,
) {
  return EmapiCommand(
    type: EmapiConstants.typeRequest,
    parent: EmapiConstants.parentRfid,
    child: EmapiConstants.childRfidAuthFailureHandling,
    payload: EmapiPayload.uint8(
      policy == EmapiRfidAuthFailurePolicy.forbidPrint ? 0x01 : 0x00,
    ),
  );
}

EmapiCommand _setWifiConfigCommand(String ssid, String password) {
  return EmapiCommand(
    type: EmapiConstants.typePassthroughRequest,
    parent: EmapiConstants.parentWifi,
    child: EmapiConstants.childWifiConfig,
    payload: Tlv.encode([
      TlvEntry.string(0x01, ssid),
      TlvEntry.string(0x02, password),
    ]),
  );
}

final _queryWifiConnectionStateCommand = EmapiCommand(
  type: EmapiConstants.typePassthroughRequest,
  parent: EmapiConstants.parentWifi,
  child: EmapiConstants.childWifiConnectionState,
);

final _queryWifiHotspotInfoCommand = EmapiCommand(
  type: EmapiConstants.typePassthroughRequest,
  parent: EmapiConstants.parentWifi,
  child: EmapiConstants.childWifiHotspotInfo,
);

final _queryDeviceInfoCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentSystem,
  child: EmapiConstants.childDeviceInfo,
);

final _queryPrintStatusCommand = EmapiCommand(
  type: EmapiConstants.typeRequest,
  parent: EmapiConstants.parentPrinter,
  child: EmapiConstants.childPrintStatus,
);
