import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/demo_feedback.dart';
import '../models/demo_labels.dart';
import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_lan_ble_device.dart';
import '../stubs/sim_sublimation_stub.dart';
import '../utils/test_image_generator.dart';
import 'android_lan_discovery_session.dart';
import 'inspected_device.dart';
import 'lan_setup_controller.dart';

Future<Uint8List> _generateSublimationPhotoInIsolate({
  required int width,
  required int height,
  int variant = 0,
}) => Isolate.run(
  () => TestImageGenerator.generateSublimationPhotoRgba(
    width: width,
    height: height,
    variant: variant,
  ),
);

class SublimationController extends ChangeNotifier {
  SublimationController({
    required this.inspector,
    required this.registry,
    required this.colorCore,
    required DemoRunMode Function() modeGetter,
    this.feedback,
    AndroidLanDiscoverySession? lanDiscoverySession,
    SimulatedSublimationTcpDevice? simTcpDevice,
  }) : _modeGetter = modeGetter,
       _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession(),
       simBleDevice = SimulatedLanBleDevice(inspector: inspector),
       simUdpTransport = SimulatedSublimationUdpTransport(inspector: inspector),
       simTcpDevice =
           simTcpDevice ?? SimulatedSublimationTcpDevice(inspector: inspector) {
    setup = LanSetupController(
      family: CloudPrinterFamily.sublimationRpc,
      inspector: inspector,
      feedback: feedback,
      modeGetter: modeGetter,
      simBleDevice: simBleDevice,
      simScannerFactory: () =>
          SublimationLanScanner(transport: simUdpTransport),
      bleNamePrefixFilter: 'z11',
      lanDiscoverySession: _lanDiscoverySession,
      manualHostProber: _probeSublimationHost,
    )..addListener(_notifyIfAlive);
  }

  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final DemoRunMode Function() _modeGetter;
  final AndroidLanDiscoverySession _lanDiscoverySession;

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
  bool lastActionFailed = false;
  String statusMessage = '就绪';

  @visibleForTesting
  static Future<Uint8List> generateRealPhotoRgba({
    required int width,
    required int height,
    int variant = 0,
  }) => _generateSublimationPhotoInIsolate(
    width: width,
    height: height,
    variant: variant,
  );

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
  SublimationAddonInfo? addonInfo;

  bool get isZ11PhotoPrinter =>
      (printerInfo?.model ?? selectedPrinter?.model ?? '')
          .toUpperCase()
          .startsWith('Z11');

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

  Future<DiscoveredCloudPrinter?> _probeSublimationHost(
    String host,
    String? wifiInterface,
  ) async {
    final binder = InspectedNetworkBinder(
      inspector,
      CloudPrinterFamily.sublimationRpc,
    );
    final dev = await binder.connectDevice(
      host,
      9100,
      timeout: const Duration(seconds: 4),
      networkInterface: wifiInterface,
    );
    final rpc = SublimationRpcClient(
      device: dev,
      defaultTimeout: const Duration(seconds: 4),
    );
    try {
      final dataOps = SublimationDataOperations(rpc);
      await dataOps.readPrinterStatus();
      final info = await _tryQuery(() => dataOps.readPrinterInfo());
      final model = info?.model;
      final label = (model != null && model.isNotEmpty) ? model : host;
      return DiscoveredCloudPrinter(
        id: host,
        displayName: label,
        family: CloudPrinterFamily.sublimationRpc,
        host: host,
        port: 9100,
        model: model,
        serialNumber: info?.serialNumber,
        firmwareVersion: info?.firmwareVersion,
        networkInterface: wifiInterface,
      );
    } finally {
      await rpc.close();
      await dev.disconnect();
    }
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    if (mode == DemoRunMode.realDevice &&
        target == null &&
        selectedPrinter == null) {
      lastActionFailed = true;
      statusMessage = '请先发现并选择打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
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
        transportConnector: (target, timeout) async {
          var networkSessionHeld = false;
          try {
            String? wifiInterface = target.networkInterface;
            if (mode == DemoRunMode.realDevice) {
              try {
                networkSessionHeld = await _lanDiscoverySession.begin();
                if (networkSessionHeld && wifiInterface == null) {
                  wifiInterface = (await _lanDiscoverySession.currentNetwork())
                      ?.interfaceName;
                }
              } catch (_) {}
              wifiInterface ??= await DefaultInkjetNetworkBinder()
                  .resolveWifiInterfaceName();
            }
            return await InspectedNetworkBinder(
              inspector,
              CloudPrinterFamily.sublimationRpc,
            ).connectDevice(
              target.host,
              target.port,
              timeout: timeout,
              networkInterface: wifiInterface,
            );
          } finally {
            if (networkSessionHeld) {
              try {
                await _lanDiscoverySession.end();
              } catch (_) {}
            }
          }
        },
        statusPollInterval: mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 20)
            : const Duration(milliseconds: 500),
      );
      _driver = driver;
      try {
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
      } catch (e) {
        await disconnectDriver();
        rethrow;
      }
    });
  }

  Future<void> queryDashboard() async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在查询热升华设备状态…', _refreshDashboardInternal);
  }

  Future<T?> _tryQuery<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshDashboardInternal() async {
    final driver = _driver!;
    final ops = driver.dataOps;
    final status = await ops.readPrinterStatus();
    rawStatus = status;
    consumables = await _tryQuery(() => ops.readConsumablesInfo());
    printerInfo = await _tryQuery(() => ops.readPrinterInfo());
    versionInfo = await _tryQuery(() => ops.readVersionInfo());
    cardCount = await _tryQuery(() => ops.readPrintCardCount());
    cardPosition = await _tryQuery(() => ops.readCardPosition());
    printerSetting = await _tryQuery(() => ops.readPrinterSetting());
    addonInfo = await _tryQuery(() => ops.readAddonInfo());
    dashboardSnapshot = status.toCloudStatusSnapshot(
      model: printerInfo?.model,
      serialNumber: printerInfo?.serialNumber,
      firmwareVersion: printerInfo?.firmwareVersion,
      ribbonType: consumables?.ribbonType,
      ribbonRemainingPercent: consumables?.ribbonRemainingPercent,
    );
    if (consumables != null &&
        consumables!.ribbonType != SublimationRibbonType.unknown) {
      selectedRibbonType = consumables!.ribbonType;
    }
    if (isZ11PhotoPrinter) {
      dualSided = false;
      selectedColorMode = CloudColorMode.colorCmyk;
    }
    statusMessage =
        '设备状态：${demoLabel(rawStatus?.mainStatus)}, 色带 ${consumables?.ribbonRemainingPercent ?? "-"}%, 位置: ${demoLabel(cardPosition?.position)}';
  }

  Future<void> updateAutoShutDownMinutes(int minutes) async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
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
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在执行：$label…', () async {
      await fn(_driver!);
      await _refreshDashboardInternal();
      statusMessage = '$label 已完成（${demoLabel(cardPosition?.position)})';
    });
  }

  Future<void> clearPrinterCache() async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在发送清空缓存指令…', () async {
      if (mode == DemoRunMode.simulation) {
        await _driver!.printerOps.clearPrinterCache(awaitAck: true);
        await _refreshDashboardInternal();
        statusMessage = '清空缓存 已完成（${demoLabel(cardPosition?.position)})';
        return;
      }
      await _driver!.printerOps.clearPrinterCache();
      await disconnectDriver();
      statusMessage = '已发送清空缓存（设备将重启约 5～8 秒，重启后请重新连接 RPC）';
    });
  }

  Future<void> printTestCardJob() async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    if (isZ11PhotoPrinter && selectedColorMode != CloudColorMode.colorCmyk) {
      lastActionFailed = true;
      statusMessage = 'Z11 仅支持彩色相片打印（Y/M/C/O），不支持黑白仅 K 模式';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    if (isZ11PhotoPrinter && dualSided) {
      lastActionFailed = true;
      statusMessage = 'Z11 不支持双面翻卡打印';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在编码并打印卡片…', () async {
      final cancelToken = CloudCancelToken();
      _printCancelToken = cancelToken;
      observedJobStages.clear();
      try {
        final isReal = mode == DemoRunMode.realDevice;
        final width = isReal ? SublimationCardCanvas.standardWidth : 96;
        final height = isReal ? SublimationCardCanvas.standardHeight : 64;
        final frontRgba = isReal
            ? await generateRealPhotoRgba(
                width: width,
                height: height,
                variant: 0,
              )
            : TestImageGenerator.generateSublimationCardRgba(
                width: width,
                height: height,
                variant: 0,
              );
        final frontKRgba =
            (!isZ11PhotoPrinter &&
                selectedColorMode == CloudColorMode.colorCmyk)
            ? TestImageGenerator.generateSublimationOverlayMaskRgba(
                width: width,
                height: height,
              )
            : null;
        final backRgba = (!isZ11PhotoPrinter && dualSided)
            ? TestImageGenerator.generateSublimationCardRgba(
                width: width,
                height: height,
                variant: 1,
              )
            : null;

        final backRaster = backRgba == null
            ? null
            : CloudPageRaster(
                width: width,
                height: height,
                rgbaBytes: backRgba,
              );
        final req = CloudPrintJobRequest(
          jobId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          jobName: 'SublimationDemoCard',
          settings: CloudPrintSettings(
            paperSize: CloudPaperSize.card,
            paperType: CloudPaperType.pvcCard,
            colorMode: selectedColorMode,
            quality: isReal
                ? CloudPrintQuality.standard
                : CloudPrintQuality.fine,
            copies: 1,
          ),
          pages: <CloudPageRaster>[
            CloudPageRaster(width: width, height: height, rgbaBytes: frontRgba),
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
            if (observedJobStages.isEmpty ||
                observedJobStages.last != p.stage) {
              observedJobStages.add(p.stage);
            }
            _notifyIfAlive();
          },
        );
        lastPrintResult = result;
        if (result.success) {
          await _refreshDashboardInternal();
          statusMessage =
              '任务完成：${result.pagesPrinted} side(s) (${result.bytesTransferred} B)';
        } else if (result.finalStage == CloudJobStage.cancelled) {
          statusMessage = '热升华任务已取消';
        } else {
          statusMessage = '打印失败：${result.error?.message ?? "unknown error"}';
        }
      } finally {
        _printCancelToken = null;
      }
    });
  }

  Future<void> cancelActivePrint() async {
    _printCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectDriver({bool notifyFeedback = false}) async {
    final wasConnected = _driver != null;
    await _driver?.dispose();
    _driver = null;
    if (notifyFeedback && wasConnected) {
      lastActionFailed = false;
      statusMessage = '已断开热升华 RPC 连接';
      feedback?.emitInfo(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
    }
    _notifyIfAlive();
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    if (_disposed) return;
    _busy = true;
    lastActionFailed = false;
    statusMessage = label;
    _notifyIfAlive();
    try {
      await action();
      lastActionFailed = DemoFeedbackCenter.isErrorMessage(statusMessage);
    } catch (e) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$e')}';
    } finally {
      _busy = false;
      if (!_disposed) {
        feedback?.emitOutcome(
          statusMessage,
          forceError: lastActionFailed,
          family: CloudPrinterFamily.sublimationRpc,
        );
      }
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
