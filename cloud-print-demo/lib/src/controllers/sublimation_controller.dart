import '../models/demo_labels.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_sublimation_stub.dart';
import '../stubs/sim_lan_ble_device.dart';
import '../utils/test_image_generator.dart';

import 'inspected_device.dart';
import 'lan_setup_controller.dart';

class SublimationController extends ChangeNotifier {
  SublimationController({
    required this.inspector,
    required this.registry,
    required this.colorCore,
    required DemoRunMode Function() modeGetter,
  }) : _modeGetter = modeGetter,
       simBleDevice = SimulatedLanBleDevice(inspector: inspector),
       simUdpTransport = SimulatedSublimationUdpTransport(inspector: inspector),
       simTcpDevice = SimulatedSublimationTcpDevice(inspector: inspector) {
    setup = LanSetupController(
      family: CloudPrinterFamily.sublimationRpc,
      inspector: inspector,
      modeGetter: modeGetter,
      simBleDevice: simBleDevice,
      simScannerFactory: () =>
          SublimationLanScanner(transport: simUdpTransport),
      bleNamePrefixFilter: 'z11',
    )..addListener(_notifyIfAlive);
  }

  final ProtocolInspectorController inspector;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final DemoRunMode Function() _modeGetter;

  final SimulatedLanBleDevice simBleDevice;
  final SimulatedSublimationUdpTransport simUdpTransport;
  final SimulatedSublimationTcpDevice simTcpDevice;

  late final LanSetupController setup;
  SublimationPrinterDriver? _driver;
  CloudCancelToken? _printCancelToken;
  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _busy = false;
  bool get busy => _busy || setup.busy;
  String statusMessage = '就绪';

  DiscoveredCloudPrinter? get selectedPrinter => setup.selectedPrinter;
  set selectedPrinter(DiscoveredCloudPrinter? value) =>
      setup.selectedPrinter = value;

  CloudStatusSnapshot? dashboardSnapshot;
  SublimationPrinterStatus? rawStatus;
  SublimationConsumablesInfo? consumables;
  SublimationPrinterInfo? printerInfo;
  SublimationVersionInfo? versionInfo;
  SublimationPrintCardCount? cardCount;
  SublimationCardPositionInfo? cardPosition;
  SublimationPrinterSetting? printerSetting;

  // Print options
  CloudColorMode selectedColorMode = CloudColorMode.colorCmyk;
  SublimationRibbonType selectedRibbonType = SublimationRibbonType.ymcko;
  SublimationDitherMode selectedDitherMode =
      SublimationDitherMode.floydSteinberg;
  bool fontBeautify = true;
  bool includeOvercoat = true;
  bool dualSided = false;

  CloudJobProgress? jobProgress;
  final List<CloudJobStage> observedJobStages = <CloudJobStage>[];
  CloudPrintResult? lastPrintResult;

  DemoRunMode get mode => _modeGetter();
  bool get isConnected => _driver?.isConnected ?? false;

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    if (mode == DemoRunMode.realDevice &&
        target == null &&
        selectedPrinter == null) {
      statusMessage = '请先发现并选择打印机';
      _notifyIfAlive();
      return;
    }
    final printer =
        target ??
        selectedPrinter ??
        DiscoveredCloudPrinter(
          id: 'sim-sub-d300',
          displayName: 'SubSim-D300Kp',
          family: CloudPrinterFamily.sublimationRpc,
          host: '192.168.1.88',
          port: 9100,
          macAddress: '11:22:33:44:55:66',
        );
    await _runBusy('正在连接热升华打印机…', () async {
      await disconnectDriver();
      final driver = SublimationPrinterDriver(
        colorCore: colorCore,
        transportConnector: (target, timeout) =>
            InspectedNetworkBinder(
              inspector,
              CloudPrinterFamily.sublimationRpc,
            ).connectDevice(
              target.host,
              target.port,
              timeout: timeout,
              networkInterface: target.networkInterface,
            ),
        statusPollInterval: mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 20)
            : const Duration(milliseconds: 500),
      );
      _driver = driver;
      await driver.connect(
        device: mode == DemoRunMode.simulation ? simTcpDevice : null,
        printer: mode == DemoRunMode.simulation ? null : printer,
      );
      if (_disposed) {
        await driver.dispose();
        _driver = null;
        return;
      }
      selectedPrinter = printer;
      await _refreshDashboardInternal();
      statusMessage =
          '已连接 ${printerInfo?.model ?? printer.displayName} (${demoLabel(rawStatus?.mainStatus)})';
    });
  }

  Future<void> queryDashboard() async {
    if (!isConnected) {
      statusMessage = '请先连接热升华打印机 RPC';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在查询热升华设备状态…', _refreshDashboardInternal);
  }

  Future<void> _refreshDashboardInternal() async {
    final driver = _driver!;
    dashboardSnapshot = await driver.queryStatus();
    rawStatus = await driver.dataOps.readPrinterStatus();
    consumables = await driver.dataOps.readConsumablesInfo();
    printerInfo = await driver.dataOps.readPrinterInfo();
    versionInfo = await driver.dataOps.readVersionInfo();
    cardCount = await driver.dataOps.readPrintCardCount();
    cardPosition = await driver.dataOps.readCardPosition();
    printerSetting = await driver.dataOps.readPrinterSetting();
    statusMessage =
        '设备状态：${demoLabel(rawStatus?.mainStatus)}, Ribbon ${consumables?.ribbonRemainingPercent ?? 0}%, Pos: ${demoLabel(cardPosition?.position)}';
  }

  Future<void> updateAutoShutDownMinutes(int minutes) async {
    if (!isConnected) return;
    await _runBusy('正在设置自动关机分钟数：$minutes...', () async {
      final current =
          printerSetting ?? await _driver!.dataOps.readPrinterSetting();
      final updated = current.copyWith(autoShutDownMinutes: minutes);
      await _driver!.dataOps.writePrinterSetting(updated);
      printerSetting = await _driver!.dataOps.readPrinterSetting();
      statusMessage = '自动关机分钟数已更新：${printerSetting?.autoShutDownMinutes} min';
    });
  }

  Future<void> runMechanicalAction(
    String label,
    Future<void> Function(SublimationPrinterDriver driver) fn,
  ) async {
    if (!isConnected) {
      statusMessage = '请先连接热升华打印机 RPC';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在执行：$label…', () async {
      await fn(_driver!);
      await _refreshDashboardInternal();
      statusMessage = '$label 已完成（${demoLabel(cardPosition?.position)})';
    });
  }

  Future<void> printTestCardJob() async {
    if (!isConnected) {
      statusMessage = '请先连接热升华打印机 RPC';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在编码并打印卡片…', () async {
      final cancelToken = CloudCancelToken();
      _printCancelToken = cancelToken;
      observedJobStages.clear();

      final frontRgba = TestImageGenerator.generateSublimationCardRgba(
        width: 96,
        height: 64,
        variant: 0,
      );
      final frontKRgba = selectedColorMode == CloudColorMode.colorCmyk
          ? TestImageGenerator.generateSublimationOverlayMaskRgba(
              width: 96,
              height: 64,
            )
          : null;
      final backRgba = dualSided
          ? TestImageGenerator.generateSublimationCardRgba(
              width: 96,
              height: 64,
              variant: 1,
            )
          : null;

      final backRaster = backRgba == null
          ? null
          : CloudPageRaster(width: 96, height: 64, rgbaBytes: backRgba);
      final req = CloudPrintJobRequest(
        jobId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        jobName: 'SublimationDemoCard',
        settings: CloudPrintSettings(
          paperSize: CloudPaperSize.card,
          paperType: CloudPaperType.pvcCard,
          colorMode: selectedColorMode,
          quality: CloudPrintQuality.fine,
          copies: 1,
        ),
        pages: <CloudPageRaster>[
          CloudPageRaster(width: 96, height: 64, rgbaBytes: frontRgba),
          ?backRaster,
        ],
        metadata: <String, Object?>{
          'fontBeautify': fontBeautify,
          'includeOvercoat': includeOvercoat,
          'ribbonType': selectedRibbonType,
          'ditherMode': selectedDitherMode,
          'frontKRgba': ?frontKRgba,
        },
        cancelToken: cancelToken,
      );

      final result = await _driver!.printJob(
        req,
        cancelToken: cancelToken,
        onProgress: (p) {
          jobProgress = p;
          if (observedJobStages.isEmpty || observedJobStages.last != p.stage) {
            observedJobStages.add(p.stage);
          }
          _notifyIfAlive();
        },
      );
      lastPrintResult = result;
      _printCancelToken = null;
      if (result.success) {
        await _refreshDashboardInternal();
        statusMessage =
            '任务完成：${result.pagesPrinted} side(s) (${result.bytesTransferred} B)';
      } else if (result.finalStage == CloudJobStage.cancelled) {
        statusMessage = '热升华任务已取消';
      } else {
        statusMessage = '打印失败：${result.error?.message ?? "unknown error"}';
      }
    });
  }

  Future<void> cancelActivePrint() async {
    _printCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectDriver() async {
    await _driver?.dispose();
    _driver = null;
    _notifyIfAlive();
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    if (_disposed) return;
    _busy = true;
    statusMessage = label;
    _notifyIfAlive();
    try {
      await action();
    } catch (e) {
      statusMessage = '操作失败：$e';
    } finally {
      _busy = false;
      _notifyIfAlive();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _printCancelToken?.cancel('Disposed');
    await setup.dispose();
    await disconnectDriver();
    await simTcpDevice.disconnect();
    super.dispose();
  }
}
