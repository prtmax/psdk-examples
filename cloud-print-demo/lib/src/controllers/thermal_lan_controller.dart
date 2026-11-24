import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_frame_father/father/command/print/commander.dart';
import 'package:psdk_fruit_tspl/psdk_fruit_tspl.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/protocol_inspector.dart';
import '../utils/local_image_service.dart';
import 'inspected_device.dart';
import 'lan_setup_controller.dart';
import 'real_transport_helper.dart';

class ThermalLanController extends ChangeNotifier {
  ThermalLanController({
    required this.inspector,
    required this.realTransportHelper,
    this.feedback,
    LocalImagePickerService? localImagePicker,
    Network Function()? networkFactory,
    LanPrinterScanner Function()? discoveryScannerFactory,
    bool useAndroidDiscoveryHooks = true,
    Duration postProvisionDiscoveryDelay = const Duration(milliseconds: 2500),
    Duration provisionSettleDelay = const Duration(seconds: 2),
    Duration provisionPollInterval = const Duration(milliseconds: 500),
    Duration scanTimeout = const Duration(seconds: 5),
    Duration scanProbeInterval = const Duration(seconds: 1),
    int discoveryAttempts = 2,
  }) : _localImagePicker = localImagePicker ?? const LocalImagePickerService(),
       _networkFactory = networkFactory {
    setup = LanSetupController(
      family: CloudPrinterFamily.thermalLanStream,
      inspector: inspector,
      feedback: feedback,
      scannerFactory: discoveryScannerFactory,
      useAndroidDiscoveryHooks: useAndroidDiscoveryHooks,
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
  final RealTransportHelper realTransportHelper;
  final LocalImagePickerService _localImagePicker;
  final Network Function()? _networkFactory;

  PickedLocalImage? selectedLocalImage;
  late final LanSetupController setup;
  Network? _network;
  ConnectedDevice<dynamic>? _tcpDevice;
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

  List<DiscoveredCloudPrinter> get discoveredPrinters =>
      setup.discoveredPrinters;
  DiscoveredCloudPrinter? get selectedPrinter => setup.selectedPrinter;
  set selectedPrinter(DiscoveredCloudPrinter? value) =>
      setup.selectedPrinter = value;
  CloudJobProgress? printProgress;
  String? lastStreamResult;

  bool get isTcpConnected =>
      _tcpDevice != null &&
      _tcpDevice!.connectionState() == ConnectionState.connected;

  Future<void> connectTcpPrinter([DiscoveredCloudPrinter? target]) async {
    final printer = target ?? selectedPrinter;
    if (printer == null) {
      lastActionFailed = true;
      statusMessage = '请先发现并选择打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.thermalLanStream,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在连接 TCP ${printer.host}:${printer.port}...', () async {
      await disconnectTcpPrinter();
      _network ??=
          _networkFactory?.call() ?? realTransportHelper.createRealNetwork();
      final device = await _network!.connect(
        printer.host,
        printer.port,
        networkInterface: printer.networkInterface,
      );
      if (_disposed) {
        await device.disconnect();
        return;
      }
      _tcpDevice = _networkFactory != null
          ? device
          : InspectedDevice(
              device,
              inspector,
              CloudPrinterFamily.thermalLanStream,
              'TCP',
            );
      selectedPrinter = printer;
      statusMessage = 'TCP 已连接：${printer.host}:${printer.port}';
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
        family: CloudPrinterFamily.thermalLanStream,
      );
      _notifyIfAlive();
      return picked;
    } catch (e) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$e')}';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.thermalLanStream,
      );
      _notifyIfAlive();
      return null;
    }
  }

  Future<void> _streamTcpPayload({
    required ConnectedDevice<dynamic> tcp,
    required Uint8List payload,
    required int chunkSize,
    required String completeMessage,
  }) async {
    final cancelToken = CloudCancelToken();
    _printCancelToken = cancelToken;
    final session = StreamJobSession(
      device: tcp,
      chunkSize: chunkSize,
      cancelToken: cancelToken,
      onProgress: (p) {
        printProgress = p;
        _notifyIfAlive();
      },
    );
    try {
      await session.writeChunked(
        payload,
        stage: CloudJobStage.sending,
        currentPage: 1,
        totalPages: 1,
        totalJobBytes: payload.length,
        sendDoneAtEnd: true,
      );
      session.reportProgress(
        CloudJobProgress(
          stage: CloudJobStage.completed,
          currentPage: 1,
          totalPages: 1,
          bytesSent: session.bytesTransferred,
          totalBytes: payload.length,
          message: completeMessage,
        ),
      );
      lastStreamResult =
          '已发送 ${session.bytesTransferred} B to ${selectedPrinter?.host ?? "printer"}:${selectedPrinter?.port ?? 9100}';
      statusMessage = lastStreamResult!;
    } on CloudCancelledException catch (e) {
      lastStreamResult = '发送已取消：${e.reason}';
      statusMessage = lastStreamResult!;
    } finally {
      _printCancelToken = null;
      await session.dispose();
    }
  }

  Future<void> streamTsplPrintJob({
    String text = 'PSDK Thermal LAN Demo',
    int copies = 1,
  }) async {
    final tcp = _tcpDevice;
    if (tcp == null || tcp.connectionState() != ConnectionState.connected) {
      lastActionFailed = true;
      statusMessage = '请先连接 TCP 9100 打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.thermalLanStream,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在通过 TCP 9100 发送 TSPL 任务…', () async {
      final sanitizedText = text
          .replaceAll('\r', ' ')
          .replaceAll('\n', ' ')
          .replaceAll('"', "'");
      final payload = Commander.make()
          .pushArg(TPage(width: 80, height: 50))
          .pushArg(TLabel(height: 2, offset: 0))
          .pushArg(TClear())
          .pushArg(
            TText(
              x: 30,
              y: 40,
              font: TFont.tss24,
              xmulty: 1,
              ymulty: 1,
              isBold: false,
              content: sanitizedText,
            ),
          )
          .pushArg(
            TBarCode(
              x: 30,
              y: 90,
              codeType: TCodeType.code128,
              height: 60,
              showType: TShowType.showLeft,
              cellwidth: 2,
              content: 'PSDK-LAN-9100',
            ),
          )
          .pushArg(TPrint(copies: copies.clamp(1, 99)))
          .command()
          .binary();
      await _streamTcpPayload(
        tcp: tcp,
        payload: payload,
        chunkSize: 128,
        completeMessage: 'TSPL 数据发送完成',
      );
    });
  }

  Future<void> streamLocalImageTsplPrintJob({int copies = 1}) async {
    final tcp = _tcpDevice;
    if (tcp == null || tcp.connectionState() != ConnectionState.connected) {
      lastActionFailed = true;
      statusMessage = '请先连接 TCP 9100 打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.thermalLanStream,
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
        family: CloudPrinterFamily.thermalLanStream,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在编码并通过 TCP 9100 发送本地图片…', () async {
      final payload = await buildTsplBitmapPayloadInIsolate(
        rgbaBytes: img.rgbaBytes,
        width: img.width,
        height: img.height,
        copies: copies,
      );
      await _streamTcpPayload(
        tcp: tcp,
        payload: payload,
        chunkSize: 1024,
        completeMessage: 'TSPL 本地图片发送完成',
      );
    });
  }

  void cancelTsplPrintJob() {
    _printCancelToken?.cancel('Cancelled by user');
  }

  Future<void> disconnectTcpPrinter({bool notifyFeedback = false}) async {
    final wasConnected = _tcpDevice != null;
    await _tcpDevice?.disconnect();
    _tcpDevice = null;
    if (notifyFeedback && wasConnected) {
      lastActionFailed = false;
      statusMessage = '已断开 TCP 9100 连接';
      feedback?.emitInfo(
        statusMessage,
        family: CloudPrinterFamily.thermalLanStream,
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
          family: CloudPrinterFamily.thermalLanStream,
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
    await disconnectTcpPrinter();
    _network?.dispose();
    await setup.dispose();
    super.dispose();
  }
}
