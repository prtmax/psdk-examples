import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:psdk_cloud_wan/psdk_cloud_wan.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_esc_wan_stub.dart';

class EscWanController extends ChangeNotifier {
  EscWanController({
    required this.inspector,
    required DemoRunMode Function() modeGetter,
  }) : _modeGetter = modeGetter,
       simDevice = SimEscConnectedDevice(inspector: inspector),
       simBackend = SimCloudWanBackend(inspector: inspector);

  final ProtocolInspectorController inspector;
  final DemoRunMode Function() _modeGetter;
  final SimEscConnectedDevice simDevice;
  final SimCloudWanBackend simBackend;

  ConnectedDevice<dynamic>? realBleDevice;
  CloudWanPrinterDriver? _driver;
  StreamSubscription<CloudStatusSnapshot>? _statusSub;
  CloudCancelToken? _jobCancelToken;

  bool busy = false;
  String statusMessage = 'Ready (Simulation Mode)';
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
  int selectedFaultCode = 0;
  SimCloudJobOutcome selectedJobOutcome = SimCloudJobOutcome.success;

  DemoRunMode get mode => _modeGetter();
  bool get isWanConnected => _driver?.isConnected ?? false;

  ConnectedDevice<dynamic> get _activeEscDevice {
    if (mode == DemoRunMode.simulation) return simDevice;
    final dev = realBleDevice;
    if (dev == null) {
      throw StateError('No Real BLE ESC device connected');
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
    await _runBusy('Provisioning ESC Wi-Fi via TLV...', () async {
      final hosts = hostsText
          .split(RegExp(r'[|\s,]+'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final provisioner = CloudWanEscProvisioner(
        device: _activeEscDevice,
        cloudHosts: hosts,
        deviceKey: key.trim().isEmpty ? null : key.trim(),
        requireCloudConnected: requireCloudConnected,
        commandTimeout: const Duration(seconds: 2),
      );
      try {
        final result = await provisioner.provision(
          ProvisionRequest(
            protocol: WifiProvisionProtocol.escBinaryTlv,
            ssid: ssid,
            password: password,
            settleDelay: mode == DemoRunMode.simulation
                ? const Duration(milliseconds: 15)
                : const Duration(seconds: 2),
            pollInterval: mode == DemoRunMode.simulation
                ? const Duration(milliseconds: 15)
                : const Duration(milliseconds: 500),
          ),
        );
        lastProvisionResult = result;
        statusMessage = result.success
            ? 'Provisioned "$ssid" (${result.finalState.name})'
            : 'Provision failed: ${result.message ?? result.errorCode.name}';
      } finally {
        await provisioner.dispose();
      }
    });
  }

  Future<void> inspectEscDevice() async {
    await _runBusy('Querying ESC device info...', () async {
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
          'ESC Info: SN=${lastSerialNumber ?? "?"}, Wi-Fi=${lastWifiName ?? "?"}, STA=${lastStaResult?.state.name ?? "?"}';
    });
  }

  Future<void> resetNetworkInfo() async {
    await _runBusy('Resetting ESC network info...', () async {
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
      statusMessage = ack.isSuccess
          ? 'Network info reset complete'
          : 'Network reset reply invalid';
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
    await _runBusy('Connecting to Cloud WAN...', () async {
      await disconnectWan();
      final CloudWanConfig config;
      if (mode == DemoRunMode.simulation) {
        config = simBackend.createConfig(
          overrideSerialNumber:
              (serialNumber != null && serialNumber.trim().isNotEmpty)
              ? serialNumber.trim()
              : (lastSerialNumber ?? simBackend.serialNumber),
        );
      } else {
        config = CloudWanConfig.custom(
          apiBaseUrl: (apiBaseUrl ?? '').trim().isNotEmpty
              ? apiBaseUrl!.trim()
              : 'https://cprint-api.iprtapp.com',
          mqttHost: (mqttHost ?? '').trim().isNotEmpty
              ? mqttHost!.trim()
              : 'mqtt.iprtapp.com',
          mqttPort: mqttPort,
          mqttUseTls: mqttUseTls,
          serialNumber: (serialNumber ?? '').trim().isNotEmpty
              ? serialNumber!.trim()
              : lastSerialNumber,
          deviceToken: (deviceToken ?? '').trim().isNotEmpty
              ? deviceToken!.trim()
              : null,
        );
      }

      final driver = CloudWanPrinterDriver(
        config: config,
        remoteJobTimeout: const Duration(seconds: 15),
      );
      _driver = driver;

      await driver.connect(
        device: mode == DemoRunMode.simulation ? simDevice : realBleDevice,
      );
      _statusSub = driver.watchStatus().listen((snap) {
        wanSnapshot = snap;
        notifyListeners();
      });
      wanSnapshot = await driver.queryStatus();
      statusMessage =
          'WAN connected (${driver.serialNumber ?? "?"}) -> ${wanSnapshot?.state.name ?? "ready"}';
    });
  }

  Future<void> queryWanStatus() async {
    final driver = _driver;
    if (driver == null || !driver.isConnected) {
      statusMessage = 'Connect Cloud WAN first';
      notifyListeners();
      return;
    }
    await _runBusy('Querying WAN printer state...', () async {
      wanSnapshot = await driver.queryStatus();
      statusMessage =
          'WAN State: ${wanSnapshot?.state.name ?? "unknown"} (${wanSnapshot?.issues.length ?? 0} issues)';
    });
  }

  Future<void> submitWanPrintJob({
    String jobName = 'cloud_demo_label.prn',
    Uint8List? rawPayload,
  }) async {
    final driver = _driver;
    if (driver == null || !driver.isConnected) {
      statusMessage = 'Connect Cloud WAN first';
      notifyListeners();
      return;
    }
    await _runBusy('Uploading & submitting Cloud WAN job...', () async {
      final cancelToken = CloudCancelToken();
      _jobCancelToken = cancelToken;
      final payload =
          rawPayload ??
          Uint8List.fromList(
            utf8.encode(
              'SIZE 58 mm,40 mm\r\nCLS\r\nTEXT 20,20,"TSS24.BF2",0,1,1,"ESC WAN Cloud Demo"\r\nPRINT 1,1\r\n',
            ),
          );
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
          notifyListeners();
        },
      );
      lastPrintResult = result;
      _jobCancelToken = null;
      statusMessage = result.success
          ? 'WAN job ${result.remoteJobId ?? result.jobId} succeeded (${result.bytesTransferred} B)'
          : result.finalStage == CloudJobStage.cancelled
          ? 'WAN job cancelled'
          : 'WAN job failed: ${result.error?.message ?? "error"}';
    });
  }

  Future<void> cancelActiveWanJob() async {
    _jobCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  void setSimulatedFaultCode(int code) {
    selectedFaultCode = code;
    if (mode == DemoRunMode.simulation) {
      simBackend.injectFaultCode(code);
    }
    notifyListeners();
  }

  void setSimulatedJobOutcome(SimCloudJobOutcome outcome) {
    selectedJobOutcome = outcome;
    if (mode == DemoRunMode.simulation) {
      simBackend.nextJobOutcome = outcome;
    }
    notifyListeners();
  }

  /// Simulates 3+ consecutive HTTP polling failures so `CloudWanStatusMonitor`
  /// emits `CloudPrinterState.offline`.
  Future<void> simulateThreePollFailures() async {
    final monitor = _driver?.statusMonitor;
    if (mode != DemoRunMode.simulation || monitor == null) {
      statusMessage = 'Connect Cloud WAN in Simulation Mode first';
      notifyListeners();
      return;
    }
    await _runBusy('Simulating >=3 HTTP poll failures...', () async {
      simBackend.simulateHttpPollFailure = true;
      try {
        for (var i = 0; i < 3; i++) {
          await monitor.pollOnce(timeout: const Duration(seconds: 2));
        }
        statusMessage =
            'Poll fallback triggered -> state=${wanSnapshot?.state.name ?? "offline"}';
      } finally {
        simBackend.simulateHttpPollFailure = false;
      }
    });
  }

  Future<void> disconnectWan() async {
    await _statusSub?.cancel();
    _statusSub = null;
    await _driver?.dispose();
    _driver = null;
    notifyListeners();
  }

  Future<Uint8List> _exchangeEsc(
    ConnectedDevice<dynamic> device,
    GenericESC command,
  ) async {
    final completer = Completer<Uint8List>();
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
    try {
      await command.write();
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      settleTimer?.cancel();
      await sub.cancel();
    }
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    busy = true;
    statusMessage = label;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      statusMessage = 'Error: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    await disconnectWan();
    simBackend.dispose();
    await simDevice.disconnect();
    super.dispose();
  }
}
