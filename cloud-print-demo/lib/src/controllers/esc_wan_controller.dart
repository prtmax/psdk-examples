import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_cloud_wan/psdk_cloud_wan.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_frame_father/father/command/print/commander.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_fruit_tspl/psdk_fruit_tspl.dart';

import '../models/demo_feedback.dart';
import '../models/demo_labels.dart';
import '../models/protocol_inspector.dart';
import '../utils/local_image_service.dart';
import 'inspected_wan.dart';

typedef CloudWanConfigFactory =
    CloudWanConfig Function({
      String? apiBaseUrl,
      String? mqttHost,
      int mqttPort,
      bool mqttUseTls,
      String? serialNumber,
      String? deviceToken,
    });

class EscWanController extends ChangeNotifier {
  EscWanController({
    required this.inspector,
    this.feedback,
    LocalImagePickerService? localImagePicker,
    CloudWanConfigFactory? wanConfigFactory,
    this.provisionSettleDelay = const Duration(seconds: 2),
    this.provisionPollInterval = const Duration(milliseconds: 500),
  }) : _localImagePicker = localImagePicker ?? const LocalImagePickerService(),
       _wanConfigFactory = wanConfigFactory;

  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final LocalImagePickerService _localImagePicker;
  final CloudWanConfigFactory? _wanConfigFactory;
  final Duration provisionSettleDelay;
  final Duration provisionPollInterval;

  PickedLocalImage? selectedLocalImage;
  ConnectedDevice<dynamic>? realBleDevice;
  CloudWanPrinterDriver? _driver;
  StreamSubscription<CloudStatusSnapshot>? _statusSub;
  CloudCancelToken? _jobCancelToken;
  CloudCancelToken? _provisionCancelToken;
  CloudWanEscProvisioner? _activeProvisioner;
  final CloudCancelToken _disposeToken = CloudCancelToken();
  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool busy = false;
  bool lastActionFailed = false;
  String statusMessage = '就绪';
  ProvisionResult? lastProvisionResult;
  EscWifiStaResult? lastStaResult;
  String? lastWifiName;
  String? lastDeviceKey;
  String? lastSerialNumber;
  String? lastMac;
  String? lastFirmwareVersion;
  bool? lastResetOk;

  CloudStatusSnapshot? wanSnapshot;
  CloudJobProgress? jobProgress;
  CloudPrintResult? lastPrintResult;

  bool get isWanConnected => _driver?.isConnected ?? false;

  @visibleForTesting
  CloudWanStatusMonitor? get debugStatusMonitor => _driver?.statusMonitor;

  ConnectedDevice<dynamic> get _activeEscDevice {
    final dev = realBleDevice;
    if (dev == null || dev.connectionState() != ConnectionState.connected) {
      throw StateError('请先连接 ESC 打印机蓝牙');
    }
    return dev;
  }

  Future<void> provisionBleWifi({
    required String ssid,
    required String password,
    String hostsText = 'cprint-api.iprtapp.com:30501',
    String key = 'demo-device-key',
    bool requireCloudConnected = true,
  }) async {
    await _runBusy('正在通过 TLV 配置 ESC Wi-Fi…', () async {
      final hosts = hostsText
          .split(RegExp(r'[|\s,]+'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final cancelToken = CloudCancelToken();
      _provisionCancelToken = cancelToken;
      final provisioner = CloudWanEscProvisioner(
        device: _activeEscDevice,
        cloudHosts: hosts,
        deviceKey: key.trim().isEmpty ? null : key.trim(),
        requireCloudConnected: requireCloudConnected,
        commandTimeout: const Duration(seconds: 2),
      );
      _activeProvisioner = provisioner;
      try {
        final result = await provisioner.provision(
          ProvisionRequest(
            protocol: WifiProvisionProtocol.escBinaryTlv,
            ssid: ssid,
            password: password,
            settleDelay: provisionSettleDelay,
            pollInterval: provisionPollInterval,
            cancelToken: cancelToken,
          ),
        );
        lastProvisionResult = result;
        statusMessage = result.success
            ? '配网成功："$ssid" (${demoLabel(result.finalState)})'
            : '配网失败：${result.message ?? result.errorCode.name}';
      } finally {
        _provisionCancelToken = null;
        _activeProvisioner = null;
        await provisioner.dispose();
      }
    });
  }

  Future<void> inspectEscDevice() async {
    await _runBusy('正在查询 ESC 设备信息…', () async {
      final dev = _activeEscDevice;
      final snBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).sn(),
      );
      final snRes = EscWifiResponseParser.parseSerialNumber(snBytes);
      if (snRes.hasSerialNumber) {
        lastSerialNumber = snRes.serialNumber;
      }

      final macBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).mac(),
      );
      final macRes = EscWifiResponseParser.parseMac(macBytes);
      lastMac = macRes.macAddress;

      final verBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).printerVersion(),
      );
      final verRes = EscWifiResponseParser.parsePrinterVersion(verBytes);
      lastFirmwareVersion = verRes.version;

      final nameBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).getWifiName(),
      );
      final nameRes = EscWifiResponseParser.parseWifiName(nameBytes);
      lastWifiName = nameRes.ssid;

      final keyBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).getKey(),
      );
      final keyRes = EscWifiResponseParser.parseKey(keyBytes);
      lastDeviceKey = keyRes.key;

      final staBytes = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).getWifiSta(),
      );
      lastStaResult = EscWifiResponseParser.parseWifiSta(staBytes);

      statusMessage =
          'ESC 信息：SN=${lastSerialNumber ?? "?"}, Wi-Fi=${lastWifiName ?? "?"}, STA=${demoLabel(lastStaResult?.state)}';
    });
  }

  Future<void> resetNetworkInfo() async {
    await _runBusy('正在重置 ESC 网络信息…', () async {
      final dev = _activeEscDevice;
      final reply = await _exchangeEsc(
        dev,
        ESC.genericWithConnectedDevice(dev).resetNetworkInfo(),
      );
      final ack = EscWifiResponseParser.parseResetNetworkInfo(reply);
      lastResetOk = ack.isSuccess;
      lastWifiName = '';
      lastStaResult = EscWifiStaResult(
        rawBytes: reply,
        validity: EscReplyValidity.valid,
        state: EscWifiLinkState.disconnected,
      );
      statusMessage = ack.isSuccess ? '网络信息已重置' : '网络重置回复无效';
    });
  }

  Future<void> connectWan({
    String? apiBaseUrl,
    String? mqttHost,
    int mqttPort = 30501,
    bool mqttUseTls = true,
    String? serialNumber,
    String? deviceToken,
  }) async {
    await _runBusy('正在连接云端…', () async {
      await disconnectWan();
      final effectiveSerial = (serialNumber ?? '').trim().isNotEmpty
          ? serialNumber!.trim()
          : lastSerialNumber;
      final effectiveToken = (deviceToken ?? '').trim().isNotEmpty
          ? deviceToken!.trim()
          : null;
      final CloudWanConfig config;
      if (_wanConfigFactory != null) {
        config = _wanConfigFactory(
          apiBaseUrl: apiBaseUrl,
          mqttHost: mqttHost,
          mqttPort: mqttPort,
          mqttUseTls: mqttUseTls,
          serialNumber: effectiveSerial,
          deviceToken: effectiveToken,
        );
      } else {
        final wan = InspectedWan(inspector);
        config = CloudWanConfig.custom(
          httpClientFactory: wan.createHttpClient,
          mqttSocketConnector: wan.connectMqtt,
          apiBaseUrl: (apiBaseUrl ?? '').trim().isNotEmpty
              ? apiBaseUrl!.trim()
              : 'https://cprint-api.iprtapp.com',
          mqttHost: (mqttHost ?? '').trim().isNotEmpty
              ? mqttHost!.trim()
              : 'mqtt.iprtapp.com',
          mqttPort: mqttPort,
          mqttUseTls: mqttUseTls,
          serialNumber: effectiveSerial,
          deviceToken: effectiveToken,
        );
      }

      final driver = CloudWanPrinterDriver(
        config: config,
        remoteJobTimeout: const Duration(seconds: 15),
      );
      _driver = driver;

      await driver.connect(device: realBleDevice);
      if (_disposed) {
        await driver.dispose();
        _driver = null;
        return;
      }
      _statusSub = driver.watchStatus().listen((snap) {
        wanSnapshot = snap;
        _notifyIfAlive();
      });
      wanSnapshot = await driver.queryStatus();
      statusMessage =
          '云端已连接（${driver.serialNumber ?? "?"}) -> ${demoLabel(wanSnapshot?.state)}';
    });
  }

  Future<void> queryWanStatus() async {
    final driver = _driver;
    if (driver == null || !driver.isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接云端';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.escWanCloud,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在查询云端设备状态…', () async {
      wanSnapshot = await driver.queryStatus();
      statusMessage =
          '云端状态：${demoLabel(wanSnapshot?.state)} (${wanSnapshot?.issues.length ?? 0} issues)';
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
      feedback?.emitInfo(statusMessage, family: CloudPrinterFamily.escWanCloud);
      _notifyIfAlive();
      return picked;
    } catch (e) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$e')}';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.escWanCloud,
      );
      _notifyIfAlive();
      return null;
    }
  }

  static String _sanitizeJobName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_').trim();
    if (cleaned.isEmpty) return 'local_image';
    return cleaned.length > 48 ? cleaned.substring(0, 48) : cleaned;
  }

  Future<void> _submitWanRawJob({
    required CloudWanPrinterDriver driver,
    required String jobName,
    required Uint8List payload,
  }) async {
    final cancelToken = CloudCancelToken();
    _jobCancelToken = cancelToken;
    try {
      final req = CloudPrintJobRequest(
        jobId: 'wan_${DateTime.now().millisecondsSinceEpoch}',
        jobName: jobName,
        rawPayload: payload,
        cancelToken: cancelToken,
      );
      final result = await driver.printJob(
        req,
        cancelToken: cancelToken,
        onProgress: (p) {
          jobProgress = p;
          _notifyIfAlive();
        },
      );
      lastPrintResult = result;
      statusMessage = result.success
          ? '云端任务 ${result.remoteJobId ?? result.jobId} succeeded (${result.bytesTransferred} B)'
          : result.finalStage == CloudJobStage.cancelled
          ? '云端任务 cancelled'
          : '云端任务 failed: ${result.error?.message ?? "error"}';
    } finally {
      _jobCancelToken = null;
    }
  }

  Future<void> submitWanPrintJob({
    String jobName = 'cloud_demo_label.prn',
    Uint8List? rawPayload,
  }) async {
    final driver = _driver;
    if (driver == null || !driver.isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接云端';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.escWanCloud,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在上传并提交云打印任务…', () async {
      final payload =
          rawPayload ??
          Commander.make()
              .pushArg(TPage(width: 58, height: 40))
              .pushArg(TClear())
              .pushArg(
                TText(
                  x: 20,
                  y: 20,
                  font: TFont.tss24,
                  xmulty: 1,
                  ymulty: 1,
                  isBold: false,
                  content: 'ESC WAN Cloud Demo',
                ),
              )
              .pushArg(TPrint(copies: 1))
              .command()
              .binary();
      await _submitWanRawJob(
        driver: driver,
        jobName: jobName,
        payload: payload,
      );
    });
  }

  Future<void> submitLocalImageWanPrintJob() async {
    final driver = _driver;
    if (driver == null || !driver.isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接云端';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.escWanCloud,
      );
      _notifyIfAlive();
      return;
    }
    final img = selectedLocalImage;
    if (img == null) {
      lastActionFailed = true;
      statusMessage = '请先选择本地图片';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.escWanCloud,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在编码并上传本地图片云打印任务…', () async {
      final payload = await buildEscImagePayloadInIsolate(
        rgbaBytes: img.rgbaBytes,
        width: img.width,
        height: img.height,
      );
      await _submitWanRawJob(
        driver: driver,
        jobName: '${_sanitizeJobName(img.name)}.prn',
        payload: payload,
      );
    });
  }

  Future<void> cancelActiveWanJob() async {
    _jobCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectWan({bool notifyFeedback = false}) async {
    final wasConnected = _driver != null;
    await _statusSub?.cancel();
    _statusSub = null;
    await _driver?.dispose();
    _driver = null;
    if (notifyFeedback && wasConnected) {
      lastActionFailed = false;
      statusMessage = '已断开云端连接';
      feedback?.emitInfo(statusMessage, family: CloudPrinterFamily.escWanCloud);
    }
    _notifyIfAlive();
  }

  Future<Uint8List> _exchangeEsc(
    ConnectedDevice<dynamic> device,
    GenericESC command,
  ) async {
    _disposeToken.throwIfCancelled();
    final completer = Completer<Uint8List>();
    completer.future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    final buffer = <int>[];
    Timer? settleTimer;
    late StreamSubscription<Uint8List> sub;
    sub = device.read(ReadOptions(timeout: 2)).listen((chunk) {
      if (chunk.isEmpty) return;
      buffer.addAll(chunk);
      settleTimer?.cancel();
      settleTimer = Timer(const Duration(milliseconds: 20), () {
        if (!completer.isCompleted) {
          completer.complete(Uint8List.fromList(buffer));
        }
      });
    });
    final removeCancel = _disposeToken.addListener((reason) {
      if (!completer.isCompleted) {
        completer.completeError(CloudCancelledException(reason));
      }
    });
    try {
      await command.write();
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      settleTimer?.cancel();
      removeCancel();
      await sub.cancel();
    }
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    if (_disposed) return;
    busy = true;
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
      busy = false;
      if (!_disposed) {
        feedback?.emitOutcome(
          statusMessage,
          forceError: lastActionFailed,
          family: CloudPrinterFamily.escWanCloud,
        );
      }
      _notifyIfAlive();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _disposeToken.cancel('Disposed');
    _provisionCancelToken?.cancel('Disposed');
    _jobCancelToken?.cancel('Disposed');
    await _activeProvisioner?.dispose();
    await disconnectWan();
    await realBleDevice?.disconnect();
    super.dispose();
  }
}
