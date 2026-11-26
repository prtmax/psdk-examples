import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/demo_labels.dart';
import '../models/protocol_inspector.dart';
import '../utils/icc_profile_loader.dart';
import '../utils/local_image_service.dart';
import '../utils/test_image_generator.dart';
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
    this.feedback,
    AndroidLanDiscoverySession? lanDiscoverySession,
    VerifiedPrinterIpCache? ipCache,
    PrinterWifiSession? printerWifiSession,
    LocalImagePickerService? localImagePicker,
    LanPrinterScanner Function()? discoveryScannerFactory,
    Future<DiscoveredCloudPrinter?> Function(
      String host,
      String? wifiInterface,
    )?
    manualHostProberOverride,
    ConnectedDevice<dynamic>? Function()? directDeviceOverride,
    bool useAndroidDiscoveryHooks = true,
    this.allowLoopbackForTesting = false,
    this.statusPollInterval = const Duration(milliseconds: 500),
    Duration postProvisionDiscoveryDelay = const Duration(milliseconds: 2500),
    Duration provisionSettleDelay = const Duration(seconds: 2),
    Duration provisionPollInterval = const Duration(milliseconds: 500),
    Duration scanTimeout = const Duration(seconds: 5),
    Duration scanProbeInterval = const Duration(seconds: 1),
    int discoveryAttempts = 2,
    this.cardWidth = SublimationCardCanvas.standardWidth,
    this.cardHeight = SublimationCardCanvas.standardHeight,
    this.printQuality = CloudPrintQuality.standard,
    this.clearCacheAwaitAck = false,
  }) : _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession(),
       _printerWifiSession = printerWifiSession ?? PrinterWifiSession(),
       _localImagePicker = localImagePicker ?? const LocalImagePickerService(),
       _discoveryScannerFactory = discoveryScannerFactory,
       _manualHostProberOverride = manualHostProberOverride,
       _directDeviceOverride = directDeviceOverride,
       _useAndroidDiscoveryHooks = useAndroidDiscoveryHooks {
    setup = LanSetupController(
      family: CloudPrinterFamily.sublimationRpc,
      inspector: inspector,
      feedback: feedback,
      bleNamePrefixFilter: 'z11',
      ipCache: ipCache,
      lanDiscoverySession: _lanDiscoverySession,
      scannerFactory: _discoveryScannerFactory,
      useAndroidDiscoveryHooks: _useAndroidDiscoveryHooks,
      manualHostProber: _manualHostProberOverride ?? _probeSublimationHost,
      postProvisionDiscoveryDelay: postProvisionDiscoveryDelay,
      provisionSettleDelay: provisionSettleDelay,
      provisionPollInterval: provisionPollInterval,
      scanTimeout: scanTimeout,
      scanProbeInterval: scanProbeInterval,
      discoveryAttempts: discoveryAttempts,
    )..addListener(_notifyIfAlive);
  }

  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final AndroidLanDiscoverySession _lanDiscoverySession;
  final PrinterWifiSession _printerWifiSession;
  final LocalImagePickerService _localImagePicker;
  final LanPrinterScanner Function()? _discoveryScannerFactory;
  final Future<DiscoveredCloudPrinter?> Function(
    String host,
    String? wifiInterface,
  )?
  _manualHostProberOverride;
  final ConnectedDevice<dynamic>? Function()? _directDeviceOverride;
  final bool _useAndroidDiscoveryHooks;
  final bool allowLoopbackForTesting;
  final Duration statusPollInterval;
  final int cardWidth;
  final int cardHeight;
  final CloudPrintQuality printQuality;
  final bool clearCacheAwaitAck;

  PickedLocalImage? selectedLocalImage;
  late final LanSetupController setup;
  SublimationPrinterDriver? _driver;
  CloudCancelToken? _printCancelToken;
  bool _disposed = false;

  String directWifiSsid = '';
  String directWifiPassword = '';
  String directWifiHostOverride = '';
  int directWifiFormRevision = 0;
  PrinterWifiConnectionInfo? directWifiInfo;

  bool get isDirectWifiConnected => directWifiInfo != null;

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
  bool iccEnabled = false;

  CloudJobProgress? jobProgress;
  final List<CloudJobStage> observedJobStages = <CloudJobStage>[];
  CloudPrintResult? lastPrintResult;

  bool get isConnected => _driver?.isConnected ?? false;

  SublimationTransportConnector _buildInspectedTransportConnector() {
    final binder = InspectedNetworkBinder(
      inspector,
      CloudPrinterFamily.sublimationRpc,
    );
    return (target, timeout) => binder.connectDevice(
      target.host,
      target.port,
      timeout: timeout,
      networkInterface: target.networkInterface,
    );
  }

  Future<DiscoveredCloudPrinter?> _probeSublimationHost(
    String host,
    String? wifiInterface,
  ) async {
    final probeOverride = _manualHostProberOverride;
    if (probeOverride != null) {
      return probeOverride(host, wifiInterface);
    }
    final scanner = SublimationLanScanner();
    try {
      return await scanner.probeHost(
        host,
        timeout: const Duration(seconds: 4),
        networkInterface: wifiInterface,
        transportConnector: _buildInspectedTransportConnector(),
        allowLoopbackForTesting: allowLoopbackForTesting,
      );
    } finally {
      await scanner.dispose();
    }
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    final printer = target ?? selectedPrinter;
    if (printer == null) {
      lastActionFailed = true;
      statusMessage = '请先发现并选择打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在连接热升华打印机…', () async {
      await _connectDriverInternal(printer);
    });
  }

  Future<void> _connectDriverInternal(DiscoveredCloudPrinter printer) async {
    await disconnectDriver();
    final driver = SublimationPrinterDriver(
      colorCore: colorCore,
      transportConnector: (target, timeout) async {
        var networkSessionHeld = false;
        try {
          String? wifiInterface =
              target.networkInterface ?? directWifiInfo?.interfaceName;
          if (_useAndroidDiscoveryHooks) {
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
      statusPollInterval: statusPollInterval,
    );
    _driver = driver;
    try {
      final overrideDev = _directDeviceOverride?.call();
      await driver.connect(
        device: overrideDev,
        printer: overrideDev != null ? null : printer,
      );
      if (_disposed) {
        await driver.dispose();
        _driver = null;
        return;
      }
      setup.upsertAndSelectPrinter(printer);
      await _refreshDashboardInternal();
      statusMessage =
          '已连接 ${printerInfo?.model ?? printer.displayName} (${demoLabel(rawStatus?.mainStatus)})';
    } catch (e) {
      await disconnectDriver();
      rethrow;
    }
  }

  Future<SublimationApCredentials?> queryApWifiViaBle() async {
    SublimationApCredentials? result;
    await _runBusy('正在通过蓝牙读取设备热点凭据…', () async {
      result = await _queryApWifiViaBleInternal();
    });
    return result;
  }

  Future<SublimationApCredentials> _queryApWifiViaBleInternal() async {
    final bleDevice = setup.activeBleDevice;
    final creds = await SublimationBleApQuerier(device: bleDevice).query();
    directWifiSsid = creds.ssid;
    directWifiPassword = creds.password;
    if (creds.ip != null && creds.ip!.isNotEmpty) {
      directWifiHostOverride = creds.ip!;
    }
    directWifiFormRevision++;
    statusMessage = '已通过蓝牙读取打印机热点：${creds.ssid}（${creds.protocolUsed.name}）';
    return creds;
  }

  Future<void> connectDirectApWifi({
    required String ssid,
    required String password,
    String? hostOverride,
    bool autoConnectRpc = true,
  }) async {
    final trimmedSsid = ssid.trim();
    final trimmedHost = (hostOverride ?? '').trim();
    if (trimmedSsid.isEmpty) {
      lastActionFailed = true;
      statusMessage = '请输入打印机热点 Wi-Fi 名称（SSID）';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    if (trimmedHost.isNotEmpty &&
        (SubnetCalculator.ipv4ToInt(trimmedHost) == null ||
            !SubnetCalculator.isUsablePrinterHost(trimmedHost))) {
      lastActionFailed = true;
      statusMessage = '热点打印机 IP 格式无效（例如 192.168.4.1）';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在直连打印机热点 "$trimmedSsid"…', () async {
      await _connectDirectApWifiInternal(
        ssid: trimmedSsid,
        password: password,
        hostOverride: trimmedHost,
        autoConnectRpc: autoConnectRpc,
      );
    });
  }

  Future<void> queryBleAndConnectDirectAp({String? hostOverride}) async {
    final trimmedHost = (hostOverride ?? '').trim();
    if (trimmedHost.isNotEmpty &&
        (SubnetCalculator.ipv4ToInt(trimmedHost) == null ||
            !SubnetCalculator.isUsablePrinterHost(trimmedHost))) {
      lastActionFailed = true;
      statusMessage = '热点打印机 IP 格式无效（例如 192.168.4.1）';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在通过蓝牙获取热点并直连…', () async {
      final creds = await _queryApWifiViaBleInternal();
      final effectiveHost = trimmedHost.isNotEmpty
          ? trimmedHost
          : (creds.ip ?? '');
      await _connectDirectApWifiInternal(
        ssid: creds.ssid,
        password: creds.password,
        hostOverride: effectiveHost,
        autoConnectRpc: true,
      );
    });
  }

  Future<void> _connectDirectApWifiInternal({
    required String ssid,
    required String password,
    required String hostOverride,
    required bool autoConnectRpc,
  }) async {
    directWifiSsid = ssid;
    directWifiPassword = password;
    directWifiHostOverride = hostOverride;
    directWifiFormRevision++;

    await disconnectDriver();
    final info = await _printerWifiSession.connectToPrinterWifi(
      ssid: ssid,
      password: password,
    );
    directWifiInfo = info;

    DiscoveredCloudPrinter? foundPrinter;
    final probeOverride = _manualHostProberOverride;
    if (probeOverride == null) {
      final customScanner = _discoveryScannerFactory?.call();
      final scanner = customScanner is SublimationLanScanner
          ? customScanner
          : SublimationLanScanner();
      try {
        foundPrinter = await scanner.discoverDirectAp(
          hostOverride: hostOverride,
          gateway: info.gateway,
          networkInterface: info.interfaceName,
          probeTimeout: const Duration(seconds: 4),
          udpFallbackTimeout: const Duration(seconds: 3),
          transportConnector: _buildInspectedTransportConnector(),
          allowLoopbackForTesting: allowLoopbackForTesting,
        );
        if (foundPrinter == null &&
            customScanner != null &&
            customScanner is! SublimationLanScanner &&
            hostOverride.isEmpty) {
          final candidates = SubnetCalculator.softApCandidateHosts(
            gateway: info.gateway,
            allowLoopback: allowLoopbackForTesting,
          );
          final discovered = await customScanner
              .scan(
                LanScanOptions(
                  protocols: const <LanDiscoveryProtocol>{
                    LanDiscoveryProtocol.udp22368Text,
                    LanDiscoveryProtocol.udp1901Binary,
                  },
                  timeout: const Duration(seconds: 3),
                  cachedIps: candidates,
                ),
              )
              .toList();
          if (discovered.isNotEmpty) {
            foundPrinter = discovered.first;
          }
        }
      } finally {
        if (customScanner != null && customScanner is! SublimationLanScanner) {
          await customScanner.dispose();
        }
        await scanner.dispose();
      }
    } else {
      final candidates = SubnetCalculator.softApCandidateHosts(
        hostOverride: hostOverride,
        gateway: info.gateway,
        allowLoopback: allowLoopbackForTesting,
      );
      for (final candidateIp in candidates) {
        try {
          foundPrinter = await probeOverride(candidateIp, info.interfaceName);
          if (foundPrinter != null) break;
        } catch (_) {}
      }

      if (foundPrinter == null && hostOverride.isEmpty) {
        final scanner =
            _discoveryScannerFactory?.call() ?? SublimationLanScanner();
        try {
          final discovered = await scanner
              .scan(
                LanScanOptions(
                  protocols: const <LanDiscoveryProtocol>{
                    LanDiscoveryProtocol.udp22368Text,
                    LanDiscoveryProtocol.udp1901Binary,
                  },
                  timeout: const Duration(seconds: 3),
                  cachedIps: candidates,
                ),
              )
              .toList();
          if (discovered.isNotEmpty) {
            foundPrinter = discovered.first;
          }
        } finally {
          await scanner.dispose();
        }
      }
    }

    if (foundPrinter == null) {
      statusMessage = '已连接打印机热点 ${info.ssid}，但未探测到热升华服务，请确认热点打印机 IP 后重试';
      lastActionFailed = true;
      return;
    }

    final apPrinter = DiscoveredCloudPrinter(
      id: foundPrinter.id,
      displayName: foundPrinter.displayName,
      family: foundPrinter.family,
      host: foundPrinter.host,
      port: foundPrinter.port,
      model: foundPrinter.model,
      serialNumber: foundPrinter.serialNumber,
      firmwareVersion: foundPrinter.firmwareVersion,
      macAddress: foundPrinter.macAddress,
      networkInterface: foundPrinter.networkInterface ?? info.interfaceName,
    );
    setup.upsertAndSelectPrinter(apPrinter);
    if (autoConnectRpc) {
      await _connectDriverInternal(apPrinter);
      statusMessage =
          '已直连热点 ${info.ssid} 并连接 ${printerInfo?.model ?? apPrinter.displayName}';
    } else {
      statusMessage =
          '已直连热点 ${info.ssid} 并发现 ${apPrinter.displayName} (${apPrinter.host}:9100)';
    }
  }

  Future<void> disconnectDirectApWifi() async {
    await _runBusy('正在断开打印机热点并恢复默认网络…', () async {
      await disconnectDriver();
      await _printerWifiSession.disconnectPrinterWifi();
      directWifiInfo = null;
      statusMessage = '已断开打印机热点并恢复默认网络';
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
      if (clearCacheAwaitAck) {
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

  void setLocalImage(PickedLocalImage? image) {
    selectedLocalImage = image;
    _notifyIfAlive();
  }

  void clearLocalImage() {
    if (selectedLocalImage == null) return;
    selectedLocalImage = null;
    statusMessage = '已清除已选本地图片';
    _notifyIfAlive();
  }

  Future<PickedLocalImage?> pickLocalImage() async {
    try {
      final picked = await _localImagePicker.pickImage();
      if (picked == null || _disposed) return null;
      selectedLocalImage = picked;
      lastActionFailed = false;
      statusMessage =
          '已选择本地图片：${picked.name} (${picked.width}×${picked.height})';
      feedback?.emitInfo(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return picked;
    } catch (e) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$e')}';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return null;
    }
  }

  bool _validateBeforeCardPrint() {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接热升华打印机 RPC';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return false;
    }
    if (isZ11PhotoPrinter && selectedColorMode != CloudColorMode.colorCmyk) {
      lastActionFailed = true;
      statusMessage = 'Z11 仅支持彩色相片打印（Y/M/C/O），不支持黑白仅 K 模式';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return false;
    }
    if (isZ11PhotoPrinter && dualSided) {
      lastActionFailed = true;
      statusMessage = 'Z11 不支持双面翻卡打印';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return false;
    }
    return true;
  }

  Future<void> _submitCardPrintJob({
    required String jobName,
    required int width,
    required int height,
    required Uint8List frontRgba,
    Uint8List? frontKRgba,
    CloudPageRaster? backRaster,
  }) async {
    final cancelToken = CloudCancelToken();
    _printCancelToken = cancelToken;
    observedJobStages.clear();
    try {
      final settings = CloudPrintSettings(
        paperSize: CloudPaperSize.card,
        paperType: CloudPaperType.pvcCard,
        colorMode: selectedColorMode,
        quality: printQuality,
        copies: 1,
      );
      final iccProfileBytes = iccEnabled && settings.colorMode.usesColor
          ? await IccProfileLoader.load(IccProfileLoader.z11D380)
          : null;
      final req = CloudPrintJobRequest(
        jobId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        jobName: jobName,
        settings: settings,
        pages: <CloudPageRaster>[
          CloudPageRaster(width: width, height: height, rgbaBytes: frontRgba),
          ?backRaster,
        ],
        iccProfileBytes: iccProfileBytes,
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
  }

  Future<void> printTestCardJob() async {
    if (!_validateBeforeCardPrint()) return;
    await _runBusy('正在编码并打印卡片…', () async {
      final width = cardWidth;
      final height = cardHeight;
      final frontRgba = width >= 512
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
          (!isZ11PhotoPrinter && selectedColorMode == CloudColorMode.colorCmyk)
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
          : CloudPageRaster(width: width, height: height, rgbaBytes: backRgba);
      await _submitCardPrintJob(
        jobName: 'SublimationDemoCard',
        width: width,
        height: height,
        frontRgba: frontRgba,
        frontKRgba: frontKRgba,
        backRaster: backRaster,
      );
    });
  }

  Future<void> printLocalImageJob() async {
    if (!_validateBeforeCardPrint()) return;
    final img = selectedLocalImage;
    if (img == null) {
      lastActionFailed = true;
      statusMessage = '请先选择本地图片';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.sublimationRpc,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在缩放编码并打印本地图片…', () async {
      final width = cardWidth;
      final height = cardHeight;
      final frontRgba = await fitSublimationRgbaInIsolate(
        srcRgba: img.rgbaBytes,
        srcWidth: img.width,
        srcHeight: img.height,
        targetWidth: width,
        targetHeight: height,
      );
      await _submitCardPrintJob(
        jobName: img.name,
        width: width,
        height: height,
        frontRgba: frontRgba,
      );
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
    if (directWifiInfo != null) {
      await _printerWifiSession.disconnectPrinterWifi().catchError((_) {});
      directWifiInfo = null;
    }
    super.dispose();
  }
}
