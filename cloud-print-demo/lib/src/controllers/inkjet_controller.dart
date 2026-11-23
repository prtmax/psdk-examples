import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_labels.dart';
import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../stubs/sim_inkjet_stub.dart';
import '../utils/test_image_generator.dart';

import 'android_lan_discovery_session.dart';
import 'android_multicast_lock.dart';
import 'inspected_device.dart';
import 'real_transport_helper.dart';

enum InkjetSimFaultPreset {
  ready('Ready (0x00)', InkjetFaultCode.noError),
  yellowLow('黄色墨量低（0x39）', InkjetFaultCode.colorYInkLowLevel),
  cyanEmpty('青色墨盒已空（0x37）', InkjetFaultCode.colorCInkLifeEnd),
  frontDoorOpen('前盖打开（0x34）', InkjetFaultCode.openTheFrontDoor),
  paperJam('卡纸（0x22）', InkjetFaultCode.paperJam),
  printHeadFault('打印头故障（0x81）', InkjetFaultCode.printHeadFault);

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
    AndroidMulticastLock? multicastLock,
    AndroidLanDiscoverySession? lanDiscoverySession,
    LanPrinterScanner Function()? discoveryScannerFactory,
    this.postProvisionDiscoveryDelay = const Duration(seconds: 3),
  }) : _modeGetter = modeGetter,
       _multicastLock = multicastLock ?? AndroidMulticastLock(),
       _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession(),
       _discoveryScannerFactory = discoveryScannerFactory,
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
  final AndroidMulticastLock _multicastLock;
  final AndroidLanDiscoverySession _lanDiscoverySession;
  final LanPrinterScanner Function()? _discoveryScannerFactory;
  final Duration postProvisionDiscoveryDelay;
  final VerifiedPrinterIpCache _verifiedPrinterIpCache =
      VerifiedPrinterIpCache();

  final SimulatedInkjetBleDevice simBleDevice;
  final SimulatedInkjetTcpDevice simTcpDevice;
  final SimulatedInkjetMdnsBrowser simMdnsBrowser;
  late final SimulatedInkjetSoftApProbe simSoftApProbe;
  late final SimulatedInkjetNetworkBinder simNetworkBinder;

  ConnectedDevice<dynamic>? realBleDevice;
  InkjetPrinterDriver? _driver;
  StreamSubscription<CloudStatusSnapshot>? _pushSub;
  CloudCancelToken? _printCancelToken;
  CloudCancelToken? _provisionCancelToken;
  WifiProvisioner? _activeProvisioner;
  LanPrinterScanner? _activeScanner;
  Future<void>? _activeDiscovery;
  Future<void> _discoveryTail = Future<void>.value();
  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool busy = false;
  String statusMessage = '就绪';
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
  bool get provisioning => _activeProvisioner != null;

  void cancelProvisioning() => _provisionCancelToken?.cancel('用户取消配网');

  ConnectedDevice<dynamic> get _activeBleDevice {
    if (mode == DemoRunMode.simulation) return simBleDevice;
    final dev = realBleDevice;
    if (dev == null) {
      throw StateError('请先连接喷墨打印机蓝牙');
    }
    return dev;
  }

  Future<void> provisionBleAcl({
    required String ssid,
    required String password,
    bool rejectInSim = false,
    bool discoverAfterProvision = true,
  }) async {
    var provisionSucceeded = false;
    await _runBusy('正在通过蓝牙 ACL 配网…', () async {
      if (mode == DemoRunMode.simulation) {
        simBleDevice.rejectNextProvision = rejectInSim;
      }
      final cancelToken = CloudCancelToken();
      _provisionCancelToken = cancelToken;
      final provisioner = InkjetBleProvisioner(
        device: _activeBleDevice,
        hooks: mode == DemoRunMode.simulation
            ? simBleDevice.buildGattHooks()
            : RealTransportHelper.inkjetHooksOf(_activeBleDevice),
      );
      _activeProvisioner = provisioner;
      final stateSub = provisioner.states.listen((state) {
        final message = switch (state) {
          ProvisionState.connectingTransport => '正在准备蓝牙配网…',
          ProvisionState.sendingCredentials => '正在发送配网信息…',
          ProvisionState.waitingForLink => '配置已发送，等待打印机确认（最长 45 秒）…',
          _ => null,
        };
        if (message != null) {
          statusMessage = message;
          _notifyIfAlive();
        }
      });
      _notifyIfAlive();
      try {
        final result = await provisioner.provision(
          ProvisionRequest(
            protocol: WifiProvisionProtocol.inkjetBleAcl,
            ssid: ssid,
            password: password,
            gattProfile: BleGattProfile.inkjet,
            negotiatedMtu: mode == DemoRunMode.simulation
                ? 512
                : RealTransportHelper.mtuOf(_activeBleDevice),
            cancelToken: cancelToken,
          ),
        );
        lastProvisionResult = result;
        provisionSucceeded = result.success;
        statusMessage = result.success
            ? 'ACL 配网成功："$ssid"'
            : switch (result.errorCode) {
                ProvisionErrorCode.cancelled => '配网已取消',
                ProvisionErrorCode.timeout => '配网超时：未收到打印机确认，请检查蓝牙连接后重试',
                ProvisionErrorCode.transportUnavailable =>
                  '配网失败：蓝牙连接已断开或不可用，请重新连接',
                ProvisionErrorCode.rejectedByDevice =>
                  '配网失败：打印机拒绝了配置，请检查 Wi-Fi 名称和密码',
                _ => 'ACL 配网失败：${result.message ?? result.errorCode.name}',
              };
      } finally {
        await stateSub.cancel();
        _provisionCancelToken = null;
        _activeProvisioner = null;
        await provisioner.dispose();
      }
    });
    if (!provisionSucceeded ||
        !discoverAfterProvision ||
        mode != DemoRunMode.realDevice ||
        _disposed) {
      return;
    }
    await Future<void>.delayed(postProvisionDiscoveryDelay);
    if (_disposed) return;
    await _startDiscovery(
      label: '配网成功，等待打印机重新入网并自动发现…',
      timeout: const Duration(seconds: 10),
      skipIfFound: true,
    );
  }

  Future<void> discoverPrinters({
    Set<LanDiscoveryProtocol> protocols = const <LanDiscoveryProtocol>{
      LanDiscoveryProtocol.udp22368Text,
      LanDiscoveryProtocol.udp4201Multicast,
      LanDiscoveryProtocol.mdnsPrinterTcp,
      LanDiscoveryProtocol.softApProbe,
    },
    Duration? timeout,
  }) async {
    final effectiveTimeout =
        timeout ??
        (mode == DemoRunMode.simulation
            ? const Duration(milliseconds: 120)
            : const Duration(seconds: 10));
    await _startDiscovery(
      protocols: protocols,
      timeout: effectiveTimeout,
      label: mode == DemoRunMode.simulation
          ? '正在模拟发现喷墨打印机…'
          : '正在通过 UDP 22368 / UDP 4201 / mDNS 发现打印机'
                '（最多 2 次，每次最长 ${effectiveTimeout.inSeconds} 秒）…',
    );
  }

  Future<void> _startDiscovery({
    required String label,
    required Duration timeout,
    Set<LanDiscoveryProtocol> protocols = const <LanDiscoveryProtocol>{
      LanDiscoveryProtocol.udp22368Text,
      LanDiscoveryProtocol.udp4201Multicast,
      LanDiscoveryProtocol.mdnsPrinterTcp,
      LanDiscoveryProtocol.softApProbe,
    },
    bool skipIfFound = false,
  }) {
    final previous = _discoveryTail;
    final completion = Completer<void>();
    _discoveryTail = completion.future;
    final operation = () async {
      try {
        try {
          await previous;
        } catch (_) {}
        if (_disposed) return;
        if (skipIfFound && discoveredPrinters.isNotEmpty) return;
        await _runBusy(
          label,
          () =>
              _discoverPrintersInternal(protocols: protocols, timeout: timeout),
        );
      } finally {
        if (!completion.isCompleted) {
          completion.complete();
        }
      }
    }();
    _activeDiscovery = operation;
    return operation.whenComplete(() {
      if (identical(_activeDiscovery, operation)) {
        _activeDiscovery = null;
      }
    });
  }

  Future<void> _discoverPrintersInternal({
    Set<LanDiscoveryProtocol> protocols = const <LanDiscoveryProtocol>{
      LanDiscoveryProtocol.udp22368Text,
      LanDiscoveryProtocol.udp4201Multicast,
      LanDiscoveryProtocol.mdnsPrinterTcp,
      LanDiscoveryProtocol.softApProbe,
    },
    required Duration timeout,
  }) async {
    final previousSelectedPrinter = selectedPrinter;
    final found = <DiscoveredCloudPrinter>[];
    discoveredPrinters = const <DiscoveredCloudPrinter>[];
    selectedPrinter = null;
    _notifyIfAlive();
    final attempts = mode == DemoRunMode.realDevice ? 2 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (_disposed) return;
      if (attempt > 0) {
        statusMessage = '第一次扫描未发现打印机，正在重建 Wi-Fi 网络绑定并重试…';
        _notifyIfAlive();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (_disposed) return;
      }
      await _runDiscoveryAttempt(
        protocols: protocols,
        timeout: timeout,
        attempt: attempt,
        attempts: attempts,
        found: found,
        previousSelectedPrinter: previousSelectedPrinter,
      );
      if (found.isNotEmpty) break;
    }
    discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(found);
    selectedPrinter = _selectedAfterDiscovery(found, previousSelectedPrinter);
    statusMessage = discoveredPrinters.isEmpty
        ? mode == DemoRunMode.realDevice
              ? '两次扫描均未发现喷墨打印机。请确认打印机已重新连入同一 Wi-Fi 后再扫描'
              : '未发现喷墨打印机'
        : '发现 ${discoveredPrinters.length} 台喷墨打印机';
  }

  Future<void> _runDiscoveryAttempt({
    required Set<LanDiscoveryProtocol> protocols,
    required Duration timeout,
    required int attempt,
    required int attempts,
    required List<DiscoveredCloudPrinter> found,
    required DiscoveredCloudPrinter? previousSelectedPrinter,
  }) async {
    FlutterNsdMdnsSource? realNsd;
    Network? realNetwork;
    InspectedNetworkBinder? networkBinder;
    AndroidLanDiscoveryNetwork? androidNetwork;
    String? wifiInterface;
    LanPrinterScanner? scanner;
    var networkSessionHeld = false;
    var multicastLockHeld = false;
    try {
      if (mode == DemoRunMode.realDevice) {
        try {
          networkSessionHeld = await _lanDiscoverySession.begin();
          if (networkSessionHeld) {
            _recordDiscoveryInfo('Android 已临时绑定当前 Wi-Fi 网络');
            try {
              androidNetwork = await _lanDiscoverySession.currentNetwork();
              wifiInterface = androidNetwork?.interfaceName;
            } catch (error) {
              _recordDiscoveryWarning('Android Wi-Fi 网络信息读取失败：$error');
            }
          }
        } catch (error) {
          _recordDiscoveryWarning('Android Wi-Fi 网络绑定失败：$error');
        }
        try {
          multicastLockHeld = await _multicastLock.acquire();
        } catch (error) {
          _recordDiscoveryWarning('Android 多播锁开启失败：$error');
        }
      }

      final injectedScannerFactory = _discoveryScannerFactory;
      if (injectedScannerFactory != null) {
        scanner = injectedScannerFactory();
      } else if (mode == DemoRunMode.simulation) {
        scanner = registry.requireScanner(LanDiscoveryProtocol.mdnsPrinterTcp);
      } else {
        networkBinder = InspectedNetworkBinder(
          inspector,
          CloudPrinterFamily.colorInkjetPjl,
        );
        try {
          wifiInterface ??= await networkBinder.resolveWifiInterfaceName();
          if (wifiInterface != null) {
            _recordDiscoveryInfo('UDP 发现使用 Wi-Fi 网卡：$wifiInterface');
          }
        } catch (error) {
          _recordDiscoveryWarning('Wi-Fi 网卡解析失败：$error');
        }
        final activeAndroidNetwork = androidNetwork;
        LocalIpv4InterfacesProvider localIpv4Provider =
            defaultLocalIpv4InterfacesProvider;
        if (activeAndroidNetwork != null) {
          localIpv4Provider = () async => <LocalIpv4Interface>[
            LocalIpv4Interface(
              name:
                  activeAndroidNetwork.interfaceName ??
                  wifiInterface ??
                  'wlan0',
              address: activeAndroidNetwork.address,
              prefixLength: activeAndroidNetwork.prefixLength,
            ),
          ];
          _recordDiscoveryInfo(
            'Wi-Fi 地址 ${activeAndroidNetwork.address}/'
            '${activeAndroidNetwork.prefixLength}',
          );
        }
        realNetwork = Network.scoped(
          localIpv4Provider: localIpv4Provider,
          verifiedIpCache: _verifiedPrinterIpCache,
          debugLogger: (message) => inspector.recordText(
            family: CloudPrinterFamily.colorInkjetPjl,
            transport: 'Network',
            direction: WireDirection.rx,
            text: message,
            decodedSummary: message,
          ),
        );
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
                    hostAddresses: rec.hostAddresses,
                    hostname: rec.hostname,
                    port: rec.port ?? 9100,
                    txtRecords: rec.txt,
                    networkInterface: networkInterface,
                  ),
                );
          },
          networkBinder: networkBinder,
          enrichMdnsWithXslQuery: true,
          udp22368ScannerFactory: () => realNetwork!.createScanner(
            networkInterface: wifiInterface,
            enableSubnetHostEnumerationFallback: true,
          ),
          udp4201ScannerFactory: () => realNetwork!.createScanner(
            networkInterface: wifiInterface,
            enableSubnetHostEnumerationFallback: true,
          ),
        );
      }
      final activeScanner = scanner;
      _activeScanner = activeScanner;
      statusMessage =
          '正在发现喷墨打印机（第 ${attempt + 1}/$attempts 次，'
          '每次最长 ${timeout.inSeconds} 秒）…';
      _notifyIfAlive();
      await for (final p in activeScanner.scan(
        LanScanOptions(
          protocols: protocols,
          timeout: timeout,
          cachedIps: _verifiedPrinterIpCache.ips,
          probeInterval: mode == DemoRunMode.simulation
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 1),
          defaultPort: inkjetTcpPort,
        ),
      )) {
        final candidate = canonicalizeInkjetPrinter(p);
        final idx = found.indexWhere(
          (existing) => isSameInkjetPrinter(existing, candidate),
        );
        if (idx >= 0) {
          found[idx] = found[idx].mergeWith(candidate);
        } else {
          found.add(candidate);
        }
        _verifiedPrinterIpCache.remember(candidate.host);
        discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(found);
        selectedPrinter = _selectedAfterDiscovery(
          found,
          previousSelectedPrinter,
        );
        statusMessage =
            '已发现 ${discoveredPrinters.length} 台喷墨打印机'
            '（第 ${attempt + 1}/$attempts 次）…';
        _notifyIfAlive();
      }
    } finally {
      if (identical(_activeScanner, scanner)) {
        _activeScanner = null;
      }
      try {
        await scanner?.dispose();
      } catch (error) {
        _recordDiscoveryWarning('LAN 扫描器释放失败：$error');
      }
      try {
        await realNsd?.dispose();
      } catch (error) {
        _recordDiscoveryWarning('mDNS 扫描器释放失败：$error');
      }
      try {
        realNetwork?.dispose();
      } catch (error) {
        _recordDiscoveryWarning('LAN 网络资源释放失败：$error');
      }
      if (multicastLockHeld) {
        try {
          await _multicastLock.release();
        } catch (error) {
          _recordDiscoveryWarning('Android 多播锁释放失败：$error');
        }
      }
      if (networkSessionHeld) {
        try {
          await _lanDiscoverySession.end();
        } catch (error) {
          _recordDiscoveryWarning('Android Wi-Fi 网络恢复失败：$error');
        }
      }
    }
  }

  DiscoveredCloudPrinter? _selectedAfterDiscovery(
    List<DiscoveredCloudPrinter> found,
    DiscoveredCloudPrinter? previousSelectedPrinter,
  ) {
    if (found.isEmpty) return null;
    if (previousSelectedPrinter != null) {
      for (final printer in found) {
        if (isSameInkjetPrinter(printer, previousSelectedPrinter)) {
          return printer;
        }
      }
    }
    return found.first;
  }

  void _recordDiscoveryInfo(String message) {
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'Discovery',
      direction: WireDirection.rx,
      text: message,
      decodedSummary: message,
    );
  }

  void _recordDiscoveryWarning(String message) {
    inspector.recordText(
      family: CloudPrinterFamily.colorInkjetPjl,
      transport: 'Discovery',
      direction: WireDirection.rx,
      text: message,
      decodedSummary: message,
    );
  }

  void selectPrinter(DiscoveredCloudPrinter printer) {
    final candidate = canonicalizeInkjetPrinter(printer);
    final index = discoveredPrinters.indexWhere(
      (existing) => isSameInkjetPrinter(existing, candidate),
    );
    selectedPrinter =
        index >= 0 ? discoveredPrinters[index] : candidate;
    statusMessage =
        '已选择 ${selectedPrinter!.displayName}'
        '（${selectedPrinter!.host}:${selectedPrinter!.port}）';
    _notifyIfAlive();
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    if (mode == DemoRunMode.realDevice &&
        target == null &&
        selectedPrinter == null) {
      statusMessage = '请先发现并选择打印机';
      _notifyIfAlive();
      return;
    }
    final printer = canonicalizeInkjetPrinter(
        target ??
            selectedPrinter ??
            DiscoveredCloudPrinter(
              id: 'sim-inkjet',
              displayName: 'SimColorJet-Pro',
              family: CloudPrinterFamily.colorInkjetPjl,
              host: '192.168.1.92',
              port: 9100,
            ),
      );
    _verifiedPrinterIpCache.remember(printer.host);
    await _runBusy('正在连接喷墨打印机…', () async {
      await disconnectDriver();
      final driver = InkjetPrinterDriver(
        colorCore: colorCore,
        networkBinder: mode == DemoRunMode.simulation
            ? simNetworkBinder
            : InspectedNetworkBinder(
                inspector,
                CloudPrinterFamily.colorInkjetPjl,
              ),
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
      await _refreshStatusInternal();
      statusMessage =
          '已连接 ${lastQueryResult?.productModel ?? printer.displayName}';
    });
  }

  Future<void> queryFullStatus() async {
    if (!isConnected) {
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在查询 XSL 状态与墨量…', _refreshStatusInternal);
  }

  Future<void> _refreshStatusInternal() async {
    final result = await _driver!.queryFullStatus();
    lastQueryResult = result;
    lastSnapshot = result.toCloudStatusSnapshot();
    statusMessage =
        'XSL: ${result.deviceStatus?.wireToken ?? "?"}, Fault=${result.faultCode?.descriptionZh ?? "无"}';
  }

  Future<void> toggleActivePush(bool enable) async {
    if (!isConnected) return;
    await _runBusy(enable ? '正在开启 XSL 主动推送…' : '正在关闭 XSL 主动推送…', () async {
      if (enable) {
        await _pushSub?.cancel();
        _pushSub = _driver!.watchStatus().listen((snap) {
          lastSnapshot = snap;
          _notifyIfAlive();
        });
        activePushEnabled = true;
      } else {
        await _driver!.stopWatchingStatus();
        await _pushSub?.cancel();
        _pushSub = null;
        activePushEnabled = false;
      }
      statusMessage = '主动推送：${enable ? "ON" : "OFF"}';
    });
  }

  Future<void> executeMaintenance(InkjetMaintenanceAction action) async {
    if (!isConnected) return;
    await _runBusy('正在执行维护：${action.name}...', () async {
      await _driver!.executeMaintenance(action);
      await _refreshStatusInternal();
      statusMessage = '维护指令 ${action.pjlCommand} completed';
    });
  }

  Future<void> scheduleNozzleWet(InkjetWetScheduleHours hours) async {
    if (!isConnected) return;
    await _runBusy('正在设置喷头保湿：${hours.hours}h...', () async {
      await _driver!.scheduleNozzleWet(hours);
      statusMessage = '喷头保湿定时：${hours.hours}h';
    });
  }

  Future<void> printBuiltInPage(InkjetBuiltInPage page) async {
    if (!isConnected) return;
    await _runBusy('正在打印内置页：${page.name}...', () async {
      await _driver!.printBuiltInPage(page);
      await _refreshStatusInternal();
      statusMessage = '内置页指令 ${page.pjlCommand} sent';
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
        _notifyIfAlive();
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
        _notifyIfAlive();
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
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      _notifyIfAlive();
      return null;
    }
    late InkjetPreflightResult result;
    await _runBusy('正在进行打印预检…', () async {
      result = await _driver!.runPreflightCheck(buildCurrentSettings());
      lastPreflightResult = result;
      statusMessage =
          '预检结果：${demoLabel(result.outcome)} (effective=${demoLabel(result.effectiveColorMode)})';
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
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      _notifyIfAlive();
      return null;
    }
    CloudPrintResult? result;
    await _runBusy('正在发送 XPL JBIG-1 页面…', () async {
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
          _notifyIfAlive();
        },
      );
      lastPrintResult = result;
      _printCancelToken = null;
      if (result!.success) {
        statusMessage =
            'XPL 数据发送完成：${result!.pagesPrinted} sheet(s) (${result!.bytesTransferred} B)';
      } else if (result!.finalStage == CloudJobStage.cancelled) {
        statusMessage = 'XPL 任务已取消（${result!.bytesTransferred} B sent)';
      } else {
        statusMessage = 'XPL 任务被阻止或失败：${result!.error?.message ?? "error"}';
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
    _notifyIfAlive();
  }

  Future<void> _runBusy(String label, Future<void> Function() action) async {
    if (_disposed) return;
    busy = true;
    statusMessage = label;
    _notifyIfAlive();
    try {
      await action();
    } catch (e) {
      statusMessage = '操作失败：$e';
    } finally {
      busy = false;
      _notifyIfAlive();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _provisionCancelToken?.cancel('Disposed');
    _printCancelToken?.cancel('Disposed');
    await _activeProvisioner?.dispose();
    await _activeScanner?.dispose();
    await disconnectDriver();
    await simBleDevice.disconnect();
    await simTcpDevice.disconnect();
    await realBleDevice?.disconnect();
    super.dispose();
  }
}
