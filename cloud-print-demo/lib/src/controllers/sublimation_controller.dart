import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_sublimation_stub.dart';
import '../utils/test_image_generator.dart';

class SublimationController extends ChangeNotifier {
  SublimationController({
    required this.inspector,
    required this.registry,
    required this.colorCore,
    required DemoRunMode Function() modeGetter,
  }) : _modeGetter = modeGetter,
       simBleDevice = SimulatedSublimationBleDevice(inspector: inspector),
       simUdpTransport = SimulatedSublimationUdpTransport(inspector: inspector),
       simTcpDevice = SimulatedSublimationTcpDevice(inspector: inspector);

  final ProtocolInspectorController inspector;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final DemoRunMode Function() _modeGetter;

  final SimulatedSublimationBleDevice simBleDevice;
  final SimulatedSublimationUdpTransport simUdpTransport;
  final SimulatedSublimationTcpDevice simTcpDevice;

  ConnectedDevice<dynamic>? realBleDevice;
  SublimationPrinterDriver? _driver;
  CloudCancelToken? _printCancelToken;

  bool busy = false;
  String statusMessage = 'Ready (Simulation Mode)';

  WifiProvisionProtocol selectedProvisionProtocol =
      WifiProvisionProtocol.sublimationBleBinaryMesh;
  WifiTargetMode selectedTargetMode = WifiTargetMode.station;
  ProvisionResult? lastProvisionResult;

  List<DiscoveredCloudPrinter> discoveredPrinters = <DiscoveredCloudPrinter>[];
  DiscoveredCloudPrinter? selectedPrinter;
  int? lastUdp1901Status;

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
  bool useCustomIccBytes = false;

  CloudJobProgress? jobProgress;
  final List<CloudJobStage> observedJobStages = <CloudJobStage>[];
  CloudPrintResult? lastPrintResult;

  DemoRunMode get mode => _modeGetter();
  bool get isConnected => _driver?.isConnected ?? false;

  ConnectedDevice<dynamic> get _activeBleDevice {
    if (mode == DemoRunMode.simulation) return simBleDevice;
    final dev = realBleDevice;
    if (dev == null) {
      throw StateError('No Real BLE Sublimation device connected');
    }
    return dev;
  }

  Future<void> provisionWifi({
    required String ssid,
    required String password,
    WifiProvisionProtocol? protocol,
    WifiTargetMode? targetMode,
  }) async {
    final proto = protocol ?? selectedProvisionProtocol;
    final target = targetMode ?? selectedTargetMode;
    selectedProvisionProtocol = proto;
    selectedTargetMode = target;

    await _runBusy(
      'Provisioning sublimation Wi-Fi (${proto.name})...',
      () async {
        final provisioner = registry.requireProvisioner(
          proto,
          device: _activeBleDevice,
        );
        try {
          final result = await provisioner.provision(
            ProvisionRequest(
              protocol: proto,
              ssid: ssid,
              password: password,
              targetMode: target,
              gattProfile: BleGattProfile.sublimation,
              negotiatedMtu: 512,
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
              ? 'Provisioned ${proto.name} (${result.assignedIp ?? ssid})'
              : 'Provision failed: ${result.message ?? result.errorCode.name}';
        } finally {
          await provisioner.dispose();
        }
      },
    );
  }

  Future<void> discoverPrinters({
    Set<LanDiscoveryProtocol> protocols = const <LanDiscoveryProtocol>{
      LanDiscoveryProtocol.udp22368Text,
      LanDiscoveryProtocol.udp1901Binary,
    },
  }) async {
    await _runBusy(
      'Discovering sublimation printers (UDP 22368/1901)...',
      () async {
        final scanner = SublimationLanScanner(
          transport: mode == DemoRunMode.simulation
              ? simUdpTransport
              : const RawDatagramUdpTransport(),
        );
        final found = <DiscoveredCloudPrinter>[];
        try {
          await for (final p in scanner.scan(
            LanScanOptions(
              protocols: protocols,
              timeout: mode == DemoRunMode.simulation
                  ? const Duration(milliseconds: 120)
                  : const Duration(seconds: 4),
              probeInterval: mode == DemoRunMode.simulation
                  ? const Duration(milliseconds: 50)
                  : const Duration(seconds: 1),
            ),
          )) {
            final idx = found.indexWhere((e) => e.id == p.id);
            if (idx >= 0) {
              found[idx] = found[idx].mergeWith(p);
            } else {
              found.add(p);
            }
          }
        } finally {
          await scanner.dispose();
        }
        discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(found);
        if (discoveredPrinters.isNotEmpty) {
          selectedPrinter = discoveredPrinters.first;
        }
        statusMessage =
            'Discovered ${discoveredPrinters.length} sublimation printer(s)';
      },
    );
  }

  Future<void> queryUdp1901Status() async {
    final target = selectedPrinter;
    final host = target?.host ?? '192.168.1.88';
    final mac = target?.macAddress ?? '11:22:33:44:55:66';
    await _runBusy('Querying UDP 1901 status...', () async {
      final client = SublimationUdp1901CommandClient(
        transport: mode == DemoRunMode.simulation
            ? simUdpTransport
            : const RawDatagramUdpTransport(),
        targetHost: host,
        targetPort: 1901,
        bindPort: 0,
        timeout: const Duration(seconds: 2),
      );
      final reply = await client.getStatus(
        macBytes: _parseMacBytes(mac),
        credentials12Bytes: Uint8List(12),
        subCommand: Uint8List.fromList(const <int>[0x01]),
      );
      lastUdp1901Status = reply.statusCode;
      statusMessage = 'UDP 1901 status = ${reply.statusCode}';
    });
  }

  Future<void> setUdp1901Status(int statusByte) async {
    final target = selectedPrinter;
    final host = target?.host ?? '192.168.1.88';
    final mac = target?.macAddress ?? '11:22:33:44:55:66';
    await _runBusy('Setting UDP 1901 status=$statusByte...', () async {
      final client = SublimationUdp1901CommandClient(
        transport: mode == DemoRunMode.simulation
            ? simUdpTransport
            : const RawDatagramUdpTransport(),
        targetHost: host,
        targetPort: 1901,
        bindPort: 0,
        timeout: const Duration(seconds: 2),
      );
      final reply = await client.setStatus(
        macBytes: _parseMacBytes(mac),
        credentials12Bytes: Uint8List(12),
        subCommand: Uint8List.fromList(const <int>[0x01]),
        statusByte: statusByte,
      );
      lastUdp1901Status = reply.statusCode;
      statusMessage = 'UDP 1901 updated status = ${reply.statusCode}';
    });
  }

  Uint8List _parseMacBytes(String mac) {
    final parts = mac.split(':');
    if (parts.length != 6) {
      return Uint8List.fromList(const <int>[
        0x11,
        0x22,
        0x33,
        0x44,
        0x55,
        0x66,
      ]);
    }
    return Uint8List.fromList(
      parts.map((p) => int.tryParse(p, radix: 16) ?? 0).toList(),
    );
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
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
    await _runBusy('Connecting Sublimation RPC...', () async {
      await disconnectDriver();
      final driver = SublimationPrinterDriver(
        colorCore: colorCore,
        statusPollInterval: mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 20)
            : const Duration(milliseconds: 500),
      );
      _driver = driver;
      await driver.connect(
        device: mode == DemoRunMode.simulation ? simTcpDevice : null,
        printer: mode == DemoRunMode.simulation ? null : printer,
      );
      selectedPrinter = printer;
      await _refreshDashboardInternal();
      statusMessage =
          'Connected ${printerInfo?.model ?? printer.displayName} (${rawStatus?.mainStatus.label ?? "Ready"})';
    });
  }

  Future<void> queryDashboard() async {
    if (!isConnected) {
      statusMessage = 'Connect Sublimation RPC first';
      notifyListeners();
      return;
    }
    await _runBusy(
      'Querying sublimation dashboard...',
      _refreshDashboardInternal,
    );
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
        'Dashboard: ${rawStatus?.mainStatus.label}, Ribbon ${consumables?.ribbonRemainingPercent ?? 0}%, Pos: ${cardPosition?.position.label}';
  }

  Future<void> updateAutoShutDownMinutes(int minutes) async {
    if (!isConnected) return;
    await _runBusy('Setting autoShutDownMinutes=$minutes...', () async {
      final current =
          printerSetting ?? await _driver!.dataOps.readPrinterSetting();
      final updated = current.copyWith(autoShutDownMinutes: minutes);
      await _driver!.dataOps.writePrinterSetting(updated);
      printerSetting = await _driver!.dataOps.readPrinterSetting();
      statusMessage =
          'Auto shutdown updated to ${printerSetting?.autoShutDownMinutes} min';
    });
  }

  Future<void> runMechanicalAction(
    String label,
    Future<void> Function(SublimationPrinterDriver driver) fn,
  ) async {
    if (!isConnected) {
      statusMessage = 'Connect Sublimation RPC first';
      notifyListeners();
      return;
    }
    await _runBusy('Running $label...', () async {
      await fn(_driver!);
      await _refreshDashboardInternal();
      statusMessage =
          '$label complete (${cardPosition?.position.label ?? "OK"})';
    });
  }

  Future<void> printTestCardJob() async {
    if (!isConnected) {
      statusMessage = 'Connect Sublimation RPC first';
      notifyListeners();
      return;
    }
    await _runBusy('Encoding & printing sublimation card...', () async {
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
        iccProfileBytes: useCustomIccBytes
            ? _minimalSrgbLikeStubOrNull()
            : null,
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
          notifyListeners();
        },
      );
      lastPrintResult = result;
      _printCancelToken = null;
      if (result.success) {
        await _refreshDashboardInternal();
        statusMessage =
            'Printed ${result.pagesPrinted} side(s) (${result.bytesTransferred} B)';
      } else if (result.finalStage == CloudJobStage.cancelled) {
        statusMessage = 'Sublimation job cancelled';
      } else {
        statusMessage =
            'Print failed: ${result.error?.message ?? "unknown error"}';
      }
    });
  }

  Uint8List? _minimalSrgbLikeStubOrNull() => null;

  Future<void> cancelActivePrint() async {
    _printCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectDriver() async {
    await _driver?.dispose();
    _driver = null;
    notifyListeners();
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
    await disconnectDriver();
    await simBleDevice.disconnect();
    await simTcpDevice.disconnect();
    super.dispose();
  }
}
