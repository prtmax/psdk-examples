import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_inkjet_stub.dart';
import '../utils/test_image_generator.dart';

enum InkjetSimFaultPreset {
  ready('Ready (0x00)', InkjetFaultCode.noError),
  yellowLow('Yellow Low (0x39)', InkjetFaultCode.colorYInkLowLevel),
  cyanEmpty('Cyan Empty (0x37)', InkjetFaultCode.colorCInkLifeEnd),
  frontDoorOpen('Front Door Open (0x34)', InkjetFaultCode.openTheFrontDoor),
  paperJam('Paper Jam (0x22)', InkjetFaultCode.paperJam),
  printHeadFault('Head Fault (0x81)', InkjetFaultCode.printHeadFault);

  const InkjetSimFaultPreset(this.label, this.faultCode);
  final String label;
  final InkjetFaultCode faultCode;
}

class InkjetController extends ChangeNotifier {
  InkjetController({
    required this.inspector,
    required this.registry,
    required this.colorCore,
    required DemoRunMode Function() modeGetter,
  }) : _modeGetter = modeGetter,
       simBleDevice = SimulatedInkjetBleDevice(inspector: inspector),
       simTcpDevice = SimulatedInkjetTcpDevice(inspector: inspector),
       simMdnsBrowser = SimulatedInkjetMdnsBrowser(inspector: inspector) {
    simSoftApProbe = SimulatedInkjetSoftApProbe(
      inspector: inspector,
      tcpDevice: simTcpDevice,
    );
    simNetworkBinder = SimulatedInkjetNetworkBinder(simTcpDevice);
  }

  final ProtocolInspectorController inspector;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final DemoRunMode Function() _modeGetter;

  final SimulatedInkjetBleDevice simBleDevice;
  final SimulatedInkjetTcpDevice simTcpDevice;
  final SimulatedInkjetMdnsBrowser simMdnsBrowser;
  late final SimulatedInkjetSoftApProbe simSoftApProbe;
  late final SimulatedInkjetNetworkBinder simNetworkBinder;

  ConnectedDevice<dynamic>? realBleDevice;
  InkjetPrinterDriver? _driver;
  StreamSubscription<CloudStatusSnapshot>? _pushSub;
  CloudCancelToken? _printCancelToken;

  bool busy = false;
  String statusMessage = 'Ready (Simulation Mode)';
  ProvisionResult? lastProvisionResult;
  List<DiscoveredCloudPrinter> discoveredPrinters = <DiscoveredCloudPrinter>[];
  DiscoveredCloudPrinter? selectedPrinter;

  InkjetXslQueryResult? lastQueryResult;
  CloudStatusSnapshot? lastSnapshot;
  bool activePushEnabled = false;
  InkjetSimFaultPreset selectedFaultPreset = InkjetSimFaultPreset.ready;
  InkjetFaultCode selectedCustomFault = InkjetFaultCode.noError;

  // Print options
  CloudPrintQuality selectedQuality = CloudPrintQuality.standard;
  InkjetResolution selectedResolution = InkjetResolution.dpi300x300;
  CloudColorMode selectedColorMode = CloudColorMode.colorCmyk;
  CloudPaperSize selectedPaperSize = CloudPaperSize.a4;
  CloudPaperType selectedPaperType = CloudPaperType.normal;
  double customWidthMm = 140.0;
  double customHeightMm = 200.0;
  bool borderless = false;
  int copies = 1;
  CloudNupLayout nupLayout = CloudNupLayout.oneUp;
  int pageCount = 2;
  bool continueOnLowSupply = false;
  bool fallbackToMonoWhenColorEmpty = false;

  InkjetPreflightResult? lastPreflightResult;
  CloudJobProgress? jobProgress;
  CloudPrintResult? lastPrintResult;

  DemoRunMode get mode => _modeGetter();
  bool get isConnected => _driver?.isConnected ?? false;

  ConnectedDevice<dynamic> get _activeBleDevice {
    if (mode == DemoRunMode.simulation) return simBleDevice;
    final dev = realBleDevice;
    if (dev == null) {
      throw StateError('No Real BLE Inkjet device connected');
    }
    return dev;
  }

  Future<void> provisionBleAcl({
    required String ssid,
    required String password,
    bool rejectInSim = false,
  }) async {
    await _runBusy('Provisioning inkjet Wi-Fi via BLE ACL cmd=24...', () async {
      if (mode == DemoRunMode.simulation) {
        simBleDevice.rejectNextProvision = rejectInSim;
      }
      final provisioner = InkjetBleProvisioner(
        device: _activeBleDevice,
        hooks: mode == DemoRunMode.simulation
            ? simBleDevice.buildGattHooks()
            : null,
      );
      try {
        final result = await provisioner.provision(
          ProvisionRequest(
            protocol: WifiProvisionProtocol.inkjetBleAcl,
            ssid: ssid,
            password: password,
            gattProfile: BleGattProfile.inkjet,
            negotiatedMtu: 512,
          ),
        );
        lastProvisionResult = result;
        statusMessage = result.success
            ? 'ACL cmd=24 provisioned "$ssid"'
            : 'ACL provision rejected: ${result.message ?? result.errorCode.name}';
      } finally {
        await provisioner.dispose();
      }
    });
  }

  Future<void> discoverPrinters({
    Set<LanDiscoveryProtocol> protocols = const <LanDiscoveryProtocol>{
      LanDiscoveryProtocol.mdnsPrinterTcp,
      LanDiscoveryProtocol.softApProbe,
    },
  }) async {
    await _runBusy('Scanning mDNS _printer._tcp & SoftAP...', () async {
      FlutterNsdMdnsSource? realNsd;
      final LanPrinterScanner scanner;
      if (mode == DemoRunMode.simulation) {
        scanner = registry.requireScanner(LanDiscoveryProtocol.mdnsPrinterTcp);
      } else {
        realNsd = FlutterNsdMdnsSource();
        scanner = InkjetDiscoveryAdapter(
          mdnsBrowser: (serviceType, {networkInterface}) {
            return realNsd!
                .discover(serviceType)
                .map(
                  (rec) => InkjetMdnsEndpoint(
                    serviceName: rec.name ?? 'inkjet._printer._tcp',
                    host: rec.hostAddresses.isNotEmpty
                        ? rec.hostAddresses.first
                        : (rec.hostname ?? ''),
                    port: rec.port ?? 9100,
                    txtRecords: rec.txt,
                    networkInterface: networkInterface,
                  ),
                );
          },
          networkBinder: DefaultInkjetNetworkBinder(),
          enrichMdnsWithXslQuery: true,
        );
      }

      final found = <DiscoveredCloudPrinter>[];
      try {
        await for (final p in scanner.scan(
          LanScanOptions(
            protocols: protocols,
            timeout: mode == DemoRunMode.simulation
                ? const Duration(milliseconds: 120)
                : const Duration(seconds: 4),
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
        await realNsd?.dispose();
      }
      discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(found);
      if (discoveredPrinters.isNotEmpty) {
        selectedPrinter = discoveredPrinters.first;
      }
      statusMessage =
          'Discovered ${discoveredPrinters.length} inkjet printer(s)';
    });
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    final printer =
        target ??
        selectedPrinter ??
        DiscoveredCloudPrinter(
          id: 'sim-inkjet',
          displayName: 'SimColorJet-Pro',
          family: CloudPrinterFamily.colorInkjetPjl,
          host: '192.168.1.92',
          port: 9100,
        );
    await _runBusy('Connecting Inkjet XSL/XPL...', () async {
      await disconnectDriver();
      final driver = InkjetPrinterDriver(
        colorCore: colorCore,
        networkBinder: mode == DemoRunMode.simulation
            ? simNetworkBinder
            : DefaultInkjetNetworkBinder(),
      );
      _driver = driver;
      await driver.connect(
        device: mode == DemoRunMode.simulation ? simTcpDevice : null,
        printer: mode == DemoRunMode.simulation ? null : printer,
      );
      selectedPrinter = printer;
      await _refreshStatusInternal();
      statusMessage =
          'Connected ${lastQueryResult?.productModel ?? printer.displayName}';
    });
  }

  Future<void> queryFullStatus() async {
    if (!isConnected) {
      statusMessage = 'Connect Inkjet XSL/XPL first';
      notifyListeners();
      return;
    }
    await _runBusy('Querying XSL status & inkbox...', _refreshStatusInternal);
  }

  Future<void> _refreshStatusInternal() async {
    final result = await _driver!.queryFullStatus();
    lastQueryResult = result;
    lastSnapshot = result.toCloudStatusSnapshot();
    statusMessage =
        'XSL: ${result.deviceStatus?.wireToken ?? "?"}, Fault=${result.faultCode?.name ?? "none"}';
  }

  Future<void> toggleActivePush(bool enable) async {
    if (!isConnected) return;
    await _runBusy(
      enable ? 'Enabling XSL active push...' : 'Disabling XSL active push...',
      () async {
        if (enable) {
          await _pushSub?.cancel();
          _pushSub = _driver!.watchStatus().listen((snap) {
            lastSnapshot = snap;
            notifyListeners();
          });
          activePushEnabled = true;
        } else {
          await _driver!.stopWatchingStatus();
          await _pushSub?.cancel();
          _pushSub = null;
          activePushEnabled = false;
        }
        statusMessage = 'Active push ${enable ? "ON" : "OFF"}';
      },
    );
  }

  Future<void> executeMaintenance(InkjetMaintenanceAction action) async {
    if (!isConnected) return;
    await _runBusy('Executing ${action.name}...', () async {
      await _driver!.executeMaintenance(action);
      await _refreshStatusInternal();
      statusMessage = 'Maintenance ${action.pjlCommand} completed';
    });
  }

  Future<void> scheduleNozzleWet(InkjetWetScheduleHours hours) async {
    if (!isConnected) return;
    await _runBusy('Scheduling nozzle wet ${hours.hours}h...', () async {
      await _driver!.scheduleNozzleWet(hours);
      statusMessage = 'Nozzle wet scheduled: ${hours.hours}h';
    });
  }

  Future<void> printBuiltInPage(InkjetBuiltInPage page) async {
    if (!isConnected) return;
    await _runBusy('Printing built-in ${page.name}...', () async {
      await _driver!.printBuiltInPage(page);
      await _refreshStatusInternal();
      statusMessage = 'Built-in page ${page.pjlCommand} sent';
    });
  }

  Future<void> applyFaultPreset(InkjetSimFaultPreset preset) async {
    selectedFaultPreset = preset;
    selectedCustomFault = preset.faultCode;
    if (mode == DemoRunMode.simulation) {
      switch (preset) {
        case InkjetSimFaultPreset.ready:
          simTcpDevice.applyInkPreset(
            fault: InkjetFaultCode.noError,
            status: InkjetDeviceRunStatus.ready,
            c: 85,
            cState: InkjetInkState.normal,
            m: 80,
            mState: InkjetInkState.normal,
            y: 75,
            yState: InkjetInkState.normal,
            k: 90,
            kState: InkjetInkState.normal,
          );
          break;
        case InkjetSimFaultPreset.yellowLow:
          simTcpDevice.applyInkPreset(
            fault: InkjetFaultCode.colorYInkLowLevel,
            status: InkjetDeviceRunStatus.ready,
            c: 85,
            cState: InkjetInkState.normal,
            m: 80,
            mState: InkjetInkState.normal,
            y: 12,
            yState: InkjetInkState.low,
            k: 90,
            kState: InkjetInkState.normal,
          );
          break;
        case InkjetSimFaultPreset.cyanEmpty:
          simTcpDevice.applyInkPreset(
            fault: InkjetFaultCode.colorCInkLifeEnd,
            status: InkjetDeviceRunStatus.error,
            c: 0,
            cState: InkjetInkState.zero,
            m: 70,
            mState: InkjetInkState.normal,
            y: 75,
            yState: InkjetInkState.normal,
            k: 88,
            kState: InkjetInkState.normal,
          );
          break;
        case InkjetSimFaultPreset.frontDoorOpen:
        case InkjetSimFaultPreset.paperJam:
        case InkjetSimFaultPreset.printHeadFault:
          simTcpDevice.applyInkPreset(
            fault: preset.faultCode,
            status: InkjetDeviceRunStatus.error,
            c: 85,
            cState: InkjetInkState.normal,
            m: 80,
            mState: InkjetInkState.normal,
            y: 75,
            yState: InkjetInkState.normal,
            k: 90,
            kState: InkjetInkState.normal,
          );
          break;
      }
      if (isConnected) {
        await queryFullStatus();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> applyCustomFaultCode(InkjetFaultCode code) async {
    selectedCustomFault = code;
    if (mode == DemoRunMode.simulation) {
      simTcpDevice.applyInkPreset(
        fault: code,
        status: code == InkjetFaultCode.noError
            ? InkjetDeviceRunStatus.ready
            : InkjetDeviceRunStatus.error,
        c: code == InkjetFaultCode.colorCInkLifeEnd ? 0 : 80,
        cState: code == InkjetFaultCode.colorCInkLifeEnd
            ? InkjetInkState.zero
            : code == InkjetFaultCode.colorCInkLowLevel
            ? InkjetInkState.low
            : InkjetInkState.normal,
        m: code == InkjetFaultCode.colorMInkLifeEnd ? 0 : 80,
        mState: code == InkjetFaultCode.colorMInkLifeEnd
            ? InkjetInkState.zero
            : code == InkjetFaultCode.colorMInkLowLevel
            ? InkjetInkState.low
            : InkjetInkState.normal,
        y: code == InkjetFaultCode.colorYInkLifeEnd ? 0 : 80,
        yState: code == InkjetFaultCode.colorYInkLifeEnd
            ? InkjetInkState.zero
            : code == InkjetFaultCode.colorYInkLowLevel
            ? InkjetInkState.low
            : InkjetInkState.normal,
        k: code == InkjetFaultCode.blackInkLifeEnd ? 0 : 85,
        kState: code == InkjetFaultCode.blackInkLifeEnd
            ? InkjetInkState.zero
            : code == InkjetFaultCode.blackInkLowLevel
            ? InkjetInkState.low
            : InkjetInkState.normal,
      );
      if (isConnected) {
        await queryFullStatus();
      } else {
        notifyListeners();
      }
    }
  }

  CloudPrintSettings buildCurrentSettings({
    bool? continueOnLowOverride,
    bool? fallbackToMonoOverride,
  }) {
    return CloudPrintSettings(
      paperSize: selectedPaperSize,
      paperType: selectedPaperType,
      customWidthMm: selectedPaperSize == CloudPaperSize.custom
          ? customWidthMm
          : null,
      customHeightMm: selectedPaperSize == CloudPaperSize.custom
          ? customHeightMm
          : null,
      borderless: borderless,
      quality: selectedQuality,
      colorMode: selectedColorMode,
      copies: copies,
      nup: nupLayout,
      continueOnLowSupply: continueOnLowOverride ?? continueOnLowSupply,
      fallbackToMonochromeWhenColorEmpty:
          fallbackToMonoOverride ?? fallbackToMonoWhenColorEmpty,
    );
  }

  Future<InkjetPreflightResult?> runPreflightCheck() async {
    if (!isConnected) {
      statusMessage = 'Connect Inkjet XSL/XPL first';
      notifyListeners();
      return null;
    }
    late InkjetPreflightResult result;
    await _runBusy('Running preflight check...', () async {
      result = await const InkjetPreflightChecker().check(
        _driver!.statusMonitor,
        buildCurrentSettings(),
      );
      lastPreflightResult = result;
      statusMessage =
          'Preflight: ${result.outcome.name} (effective=${result.effectiveColorMode.name})';
    });
    return result;
  }

  Future<CloudPrintResult?> printXplDocument({
    CloudPrintSettings? settingsOverride,
    int? pageCountOverride,
    int rasterWidth = 128,
    int rasterHeight = 160,
  }) async {
    if (!isConnected) {
      statusMessage = 'Connect Inkjet XSL/XPL first';
      notifyListeners();
      return null;
    }
    CloudPrintResult? result;
    await _runBusy('Streaming XPL JBIG-1 pages...', () async {
      final cancelToken = CloudCancelToken();
      _printCancelToken = cancelToken;
      final effectiveCount = (pageCountOverride ?? pageCount).clamp(1, 6);
      final pages = List<CloudPageRaster>.generate(
        effectiveCount,
        (i) => CloudPageRaster(
          width: rasterWidth,
          height: rasterHeight,
          rgbaBytes: TestImageGenerator.generateInkjetPageRgba(
            width: rasterWidth,
            height: rasterHeight,
            pageNumber: i + 1,
          ),
        ),
      );
      final req = CloudPrintJobRequest(
        jobId: '${DateTime.now().millisecondsSinceEpoch % 100000}',
        jobName: 'demo_xpl_doc.pdf',
        settings: settingsOverride ?? buildCurrentSettings(),
        pages: pages,
        metadata: <String, Object?>{'inkjetResolution': selectedResolution},
        cancelToken: cancelToken,
      );
      result = await _driver!.printJob(
        req,
        cancelToken: cancelToken,
        onProgress: (p) {
          jobProgress = p;
          notifyListeners();
        },
      );
      lastPrintResult = result;
      _printCancelToken = null;
      if (result!.success) {
        statusMessage =
            'XPL printed ${result!.pagesPrinted} sheet(s) (${result!.bytesTransferred} B)';
      } else if (result!.finalStage == CloudJobStage.cancelled) {
        statusMessage =
            'XPL job cancelled (${result!.bytesTransferred} B sent)';
      } else {
        statusMessage =
            'XPL blocked/failed: ${result!.error?.message ?? "error"}';
      }
    });
    return result;
  }

  Future<void> cancelActivePrint() async {
    _printCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectDriver() async {
    await _pushSub?.cancel();
    _pushSub = null;
    activePushEnabled = false;
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
