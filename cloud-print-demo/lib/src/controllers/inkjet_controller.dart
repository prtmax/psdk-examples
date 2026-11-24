import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/demo_labels.dart';
import '../models/protocol_inspector.dart';
import '../utils/local_image_service.dart';
import '../utils/test_image_generator.dart';

import 'inspected_device.dart';
import 'real_transport_helper.dart';

class InkjetController extends ChangeNotifier {
  InkjetController({
    required this.inspector,
    required this.registry,
    required this.colorCore,
    this.feedback,
    AndroidMulticastLock? multicastLock,
    AndroidLanDiscoverySession? lanDiscoverySession,
    PrinterWifiSession? printerWifiSession,
    LocalImagePickerService? localImagePicker,
    LanPrinterScanner Function()? discoveryScannerFactory,
    InkjetNetworkBinder? networkBinderOverride,
    InkjetMdnsBrowser? mdnsBrowserOverride,
    InkjetSoftApProbeTransport? softApProbeOverride,
    InkjetBleGattHooks? bleGattHooksOverride,
    ConnectedDevice<dynamic>? Function()? directDeviceOverride,
    this.allowLoopbackForTesting = false,
    this.useAndroidDiscoveryHooks = true,
    this.postProvisionDiscoveryDelay = const Duration(seconds: 3),
    this.provisionSettleDelay = const Duration(seconds: 2),
    this.provisionPollInterval = const Duration(milliseconds: 500),
    this.discoveryTimeout = const Duration(seconds: 10),
    this.discoveryProbeInterval = const Duration(seconds: 1),
    this.discoveryAttempts = 2,
    this.localImageMaxWidth = 1200,
    this.localImageMaxHeight = 1600,
    this.bleNamePrefixFilter = 'h100',
  }) : _multicastLock = multicastLock ?? AndroidMulticastLock(),
       _lanDiscoverySession =
           lanDiscoverySession ?? AndroidLanDiscoverySession(),
       _printerWifiSession = printerWifiSession ?? PrinterWifiSession(),
       _localImagePicker = localImagePicker ?? const LocalImagePickerService(),
       _discoveryScannerFactory = discoveryScannerFactory,
       _networkBinderOverride = networkBinderOverride,
       _mdnsBrowserOverride = mdnsBrowserOverride,
       _softApProbeOverride = softApProbeOverride,
       _bleGattHooksOverride = bleGattHooksOverride,
       _directDeviceOverride = directDeviceOverride;

  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter? feedback;
  final CloudPrinterRegistry registry;
  final ColorCoreEngine colorCore;
  final AndroidMulticastLock _multicastLock;
  final AndroidLanDiscoverySession _lanDiscoverySession;
  final PrinterWifiSession _printerWifiSession;
  final LocalImagePickerService _localImagePicker;
  final LanPrinterScanner Function()? _discoveryScannerFactory;
  final InkjetNetworkBinder? _networkBinderOverride;
  final InkjetMdnsBrowser? _mdnsBrowserOverride;
  final InkjetSoftApProbeTransport? _softApProbeOverride;
  final InkjetBleGattHooks? _bleGattHooksOverride;
  final ConnectedDevice<dynamic>? Function()? _directDeviceOverride;
  final bool allowLoopbackForTesting;
  final bool useAndroidDiscoveryHooks;
  final Duration postProvisionDiscoveryDelay;
  final Duration provisionSettleDelay;
  final Duration provisionPollInterval;
  final Duration discoveryTimeout;
  final Duration discoveryProbeInterval;
  final int discoveryAttempts;
  final int localImageMaxWidth;
  final int localImageMaxHeight;
  final VerifiedPrinterIpCache _verifiedPrinterIpCache =
      VerifiedPrinterIpCache();

  PickedLocalImage? selectedLocalImage;
  String bleNamePrefixFilter;
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
  bool lastActionFailed = false;
  String statusMessage = '就绪';
  ProvisionResult? lastProvisionResult;
  List<DiscoveredCloudPrinter> discoveredPrinters = <DiscoveredCloudPrinter>[];
  DiscoveredCloudPrinter? selectedPrinter;

  String directWifiSsid = '';
  String directWifiPassword = '';
  String directWifiHostOverride = '';
  int directWifiFormRevision = 0;
  PrinterWifiConnectionInfo? directWifiInfo;

  bool get isDirectWifiConnected => directWifiInfo != null;

  InkjetXslQueryResult? lastQueryResult;
  CloudStatusSnapshot? lastSnapshot;
  DateTime? lastPushAt;
  InkjetWifiStaConfig? lastWifiSta;
  InkjetPowerConfig? lastPowerConfig;
  InkjetLanguageCode? lastLanguage;
  bool activePushEnabled = false;

  // Print options
  CloudPrintQuality selectedQuality = CloudPrintQuality.standard;
  InkjetResolution selectedResolution = InkjetResolution.dpi600x600;
  CloudColorMode selectedColorMode = CloudColorMode.colorCmyk;
  CloudPaperSize selectedPaperSize = CloudPaperSize.a4;
  CloudPaperType selectedPaperType = CloudPaperType.normal;
  double customWidthMm = 140.0;
  double customHeightMm = 200.0;
  bool borderless = false;
  int copies = 1;
  CloudNupLayout nupLayout = CloudNupLayout.oneUp;
  int pageCount = 1;
  bool continueOnLowSupply = false;
  bool fallbackToMonoWhenColorEmpty = false;

  InkjetPreflightResult? lastPreflightResult;
  CloudJobProgress? jobProgress;
  CloudPrintResult? lastPrintResult;

  bool get isConnected => _driver?.isConnected ?? false;
  bool get provisioning => _activeProvisioner != null;

  void cancelProvisioning() => _provisionCancelToken?.cancel('用户取消配网');

  ConnectedDevice<dynamic> get _activeBleDevice {
    final dev = realBleDevice;
    if (dev == null || dev.connectionState() != ConnectionState.connected) {
      throw StateError('请先连接喷墨打印机蓝牙');
    }
    return dev;
  }

  Future<void> provisionBleAcl({
    required String ssid,
    required String password,
    bool discoverAfterProvision = true,
  }) async {
    var provisionSucceeded = false;
    await _runBusy('正在通过蓝牙 ACL 配网…', () async {
      final cancelToken = CloudCancelToken();
      _provisionCancelToken = cancelToken;
      final dev = _activeBleDevice;
      final provisioner = InkjetBleProvisioner(
        device: dev,
        hooks: _bleGattHooksOverride ?? RealTransportHelper.inkjetHooksOf(dev),
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
            negotiatedMtu: RealTransportHelper.mtuOf(dev),
            settleDelay: provisionSettleDelay,
            pollInterval: provisionPollInterval,
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
    if (!provisionSucceeded || !discoverAfterProvision || _disposed) {
      return;
    }
    await Future<void>.delayed(postProvisionDiscoveryDelay);
    if (_disposed) return;
    await _startDiscovery(
      label: '配网成功，等待打印机重新入网并自动发现…',
      timeout: discoveryTimeout,
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
    final effectiveTimeout = timeout ?? discoveryTimeout;
    await _startDiscovery(
      protocols: protocols,
      timeout: effectiveTimeout,
      label:
          '正在通过 UDP 22368 / UDP 4201 / mDNS 发现打印机'
          '（最多 ${discoveryAttempts.clamp(1, 5)} 次，每次最长 ${effectiveTimeout.inSeconds} 秒）…',
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
    final attempts = discoveryAttempts.clamp(1, 5);
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
        ? '未发现喷墨打印机，请确认打印机已重新连入同一 Wi-Fi 后再扫描'
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
    InkjetNetworkBinder? networkBinder;
    AndroidLanDiscoveryNetwork? androidNetwork;
    String? wifiInterface;
    LanPrinterScanner? scanner;
    var networkSessionHeld = false;
    var multicastLockHeld = false;
    try {
      if (useAndroidDiscoveryHooks) {
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
      } else {
        networkBinder =
            _networkBinderOverride ??
            InspectedNetworkBinder(
              inspector,
              CloudPrinterFamily.colorInkjetPjl,
            );
        if (useAndroidDiscoveryHooks) {
          try {
            wifiInterface ??= await networkBinder.resolveWifiInterfaceName();
            if (wifiInterface != null) {
              _recordDiscoveryInfo('UDP 发现使用 Wi-Fi 网卡：$wifiInterface');
            }
          } catch (error) {
            _recordDiscoveryWarning('Wi-Fi 网卡解析失败：$error');
          }
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
        final mdnsBrowser =
            _mdnsBrowserOverride ??
            (() {
              realNsd = FlutterNsdMdnsSource();
              return (String serviceType, {String? networkInterface}) {
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
              };
            })();
        scanner = InkjetDiscoveryAdapter(
          mdnsBrowser: mdnsBrowser,
          networkBinder: networkBinder,
          softApProbeTransport: _softApProbeOverride,
          allowLoopbackForTesting: allowLoopbackForTesting,
          enrichMdnsWithXslQuery: true,
          subnetHostsProvider: () async {
            final interfaces = await localIpv4Provider();
            final primaryHosts = <String>[];
            final overflowHosts = <String>[];
            final seen = <String>{};
            for (final iface in interfaces) {
              final dotPrefix = _ipv4Slash24Prefix(iface.address);
              final enumerated = SubnetCalculator.enumerateSubnetHosts(
                iface.address,
                prefixLength: iface.prefixLength,
                minPrefixLength: 23,
              );
              for (final ip in enumerated) {
                if (!seen.add(ip)) continue;
                if (dotPrefix != null && ip.startsWith(dotPrefix)) {
                  primaryHosts.add(ip);
                } else {
                  overflowHosts.add(ip);
                }
              }
            }
            return <String>[...primaryHosts, ...overflowHosts];
          },
          subnetFallbackDelay: const Duration(seconds: 2),
          subnetConnectTimeout: const Duration(milliseconds: 350),
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
          probeInterval: discoveryProbeInterval,
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

  static String? _ipv4Slash24Prefix(String ip) {
    final lastDot = ip.lastIndexOf('.');
    return lastDot > 0 ? ip.substring(0, lastDot + 1) : null;
  }

  Future<void> probeManualHost(String rawHost) async {
    final host = rawHost.trim();
    if (host.isEmpty ||
        SubnetCalculator.ipv4ToInt(host) == null ||
        !SubnetCalculator.isUsablePrinterHost(host)) {
      lastActionFailed = true;
      statusMessage = '请输入有效的 IPv4 地址（例如 192.168.200.214）';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return;
    }

    await _runBusy('正在探测 $host:$inkjetTcpPort…', () async {
      var networkSessionHeld = false;
      String? wifiInterface;
      InkjetDiscoveryAdapter? adapter;
      try {
        final networkBinder =
            _networkBinderOverride ??
            InspectedNetworkBinder(
              inspector,
              CloudPrinterFamily.colorInkjetPjl,
            );
        if (useAndroidDiscoveryHooks) {
          try {
            networkSessionHeld = await _lanDiscoverySession.begin();
            if (networkSessionHeld) {
              try {
                final androidNetwork = await _lanDiscoverySession
                    .currentNetwork();
                wifiInterface = androidNetwork?.interfaceName;
              } catch (_) {}
            }
          } catch (error) {
            _recordDiscoveryWarning('Android Wi-Fi 网络绑定失败：$error');
          }
          wifiInterface ??= await networkBinder.resolveWifiInterfaceName();
        }
        adapter = InkjetDiscoveryAdapter(
          networkBinder: networkBinder,
          softApProbeTransport: _softApProbeOverride,
          allowLoopbackForTesting: allowLoopbackForTesting,
        );

        final probed = await adapter.probeHost(
          host,
          timeout: const Duration(seconds: 4),
          networkInterface: wifiInterface,
        );
        if (probed == null) {
          statusMessage = '未在 $host:$inkjetTcpPort 检测到支持 XSL 的喷墨打印机';
          return;
        }
        _upsertAndSelectPrinter(probed);
        statusMessage =
            '已通过直连发现：${selectedPrinter!.displayName} '
            '(${selectedPrinter!.host}:${selectedPrinter!.port})';
      } finally {
        await adapter?.dispose();
        if (networkSessionHeld) {
          try {
            await _lanDiscoverySession.end();
          } catch (_) {}
        }
      }
    });
  }

  void _upsertAndSelectPrinter(DiscoveredCloudPrinter printer) {
    final candidate = canonicalizeInkjetPrinter(printer);
    final updated = List<DiscoveredCloudPrinter>.from(discoveredPrinters);
    final index = updated.indexWhere(
      (existing) => isSameInkjetPrinter(existing, candidate),
    );
    if (index >= 0) {
      updated[index] = updated[index].mergeWith(candidate);
    } else {
      updated.add(candidate);
    }
    discoveredPrinters = List<DiscoveredCloudPrinter>.unmodifiable(updated);
    selectedPrinter = index >= 0 ? discoveredPrinters[index] : candidate;
    _verifiedPrinterIpCache.remember(candidate.host);
  }

  void selectPrinter(DiscoveredCloudPrinter printer) {
    final candidate = canonicalizeInkjetPrinter(printer);
    final index = discoveredPrinters.indexWhere(
      (existing) => isSameInkjetPrinter(existing, candidate),
    );
    selectedPrinter = index >= 0 ? discoveredPrinters[index] : candidate;
    lastActionFailed = false;
    statusMessage =
        '已选择 ${selectedPrinter!.displayName}'
        '（${selectedPrinter!.host}:${selectedPrinter!.port}）';
    feedback?.emitInfo(
      statusMessage,
      family: CloudPrinterFamily.colorInkjetPjl,
    );
    _notifyIfAlive();
  }

  Future<void> connectDriver([DiscoveredCloudPrinter? target]) async {
    final rawPrinter = target ?? selectedPrinter;
    if (rawPrinter == null) {
      lastActionFailed = true;
      statusMessage = '请先发现并选择打印机';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return;
    }
    final printer = _withActiveHotspotInterface(rawPrinter);
    await _runBusy('正在连接喷墨打印机…', () async {
      await _connectDriverInternal(printer);
    });
  }

  DiscoveredCloudPrinter _withActiveHotspotInterface(
    DiscoveredCloudPrinter printer,
  ) {
    final canonical = canonicalizeInkjetPrinter(printer);
    final iface = directWifiInfo?.interfaceName;
    if (canonical.networkInterface != null || iface == null || iface.isEmpty) {
      return canonical;
    }
    return DiscoveredCloudPrinter(
      id: canonical.id,
      displayName: canonical.displayName,
      family: canonical.family,
      host: canonical.host,
      port: canonical.port,
      model: canonical.model,
      serialNumber: canonical.serialNumber,
      firmwareVersion: canonical.firmwareVersion,
      macAddress: canonical.macAddress,
      networkInterface: iface,
      discoveredVia: canonical.discoveredVia,
      metadata: canonical.metadata,
    );
  }

  Future<void> _connectDriverInternal(DiscoveredCloudPrinter printer) async {
    final canonical = _withActiveHotspotInterface(printer);
    _verifiedPrinterIpCache.remember(canonical.host);
    await disconnectDriver();
    final driver = InkjetPrinterDriver(
      colorCore: colorCore,
      networkBinder:
          _networkBinderOverride ??
          InspectedNetworkBinder(inspector, CloudPrinterFamily.colorInkjetPjl),
    );
    _driver = driver;
    final overrideDev = _directDeviceOverride?.call();
    await driver.connect(
      device: overrideDev,
      printer: overrideDev != null ? null : canonical,
    );
    if (_disposed) {
      await driver.dispose();
      _driver = null;
      return;
    }
    _upsertAndSelectPrinter(canonical);
    await _refreshStatusInternal();
    statusMessage =
        '已连接 ${lastQueryResult?.productModel ?? canonical.displayName}';
  }

  Future<InkjetWifiSapConfig?> queryApWifiViaBle() async {
    InkjetWifiSapConfig? result;
    await _runBusy('正在通过蓝牙读取喷墨热点凭据…', () async {
      result = await _queryApWifiViaBleInternal();
    });
    return result;
  }

  Future<InkjetWifiSapConfig> _queryApWifiViaBleInternal() async {
    final bleDevice = _activeBleDevice;
    if (bleDevice.connectionState() != ConnectionState.connected) {
      throw StateError('请先连接喷墨打印机蓝牙');
    }
    final querier = InkjetBleSoftApQuerier(
      device: bleDevice,
      hooks:
          _bleGattHooksOverride ?? RealTransportHelper.inkjetHooksOf(bleDevice),
      gattProfile: BleGattProfile.inkjet,
    );
    final sap = await querier.query(
      negotiatedMtu: RealTransportHelper.mtuOf(bleDevice),
    );
    final ssid = (sap.ssid ?? '').trim();
    if (ssid.isEmpty) {
      throw StateError('设备未返回有效的热点 SSID');
    }
    directWifiSsid = ssid;
    directWifiPassword = sap.password ?? '';
    if (sap.ipv4 != null && sap.ipv4!.isNotEmpty) {
      directWifiHostOverride = sap.ipv4!;
    }
    directWifiFormRevision++;
    statusMessage = '已通过蓝牙读取打印机热点：$ssid';
    return sap;
  }

  Future<void> connectDirectApWifi({
    required String ssid,
    required String password,
    String? hostOverride,
    bool autoConnectDriver = true,
  }) async {
    final trimmedSsid = ssid.trim();
    final trimmedHost = (hostOverride ?? '').trim();
    if (trimmedSsid.isEmpty) {
      lastActionFailed = true;
      statusMessage = '请输入打印机热点 Wi-Fi 名称（SSID）';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
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
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在直连打印机热点 "$trimmedSsid"…', () async {
      await _connectDirectApWifiInternal(
        ssid: trimmedSsid,
        password: password,
        hostOverride: trimmedHost,
        autoConnectDriver: autoConnectDriver,
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
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在通过蓝牙获取热点并直连…', () async {
      final sap = await _queryApWifiViaBleInternal();
      final effectiveHost = trimmedHost.isNotEmpty
          ? trimmedHost
          : (sap.ipv4 ?? '');
      await _connectDirectApWifiInternal(
        ssid: sap.ssid!.trim(),
        password: sap.password ?? '',
        hostOverride: effectiveHost,
        autoConnectDriver: true,
      );
    });
  }

  Future<void> _connectDirectApWifiInternal({
    required String ssid,
    required String password,
    required String hostOverride,
    required bool autoConnectDriver,
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

    final networkBinder =
        _networkBinderOverride ??
        InspectedNetworkBinder(inspector, CloudPrinterFamily.colorInkjetPjl);
    final adapter = InkjetDiscoveryAdapter(
      networkBinder: networkBinder,
      softApProbeTransport: _softApProbeOverride,
      allowLoopbackForTesting: allowLoopbackForTesting,
    );
    DiscoveredCloudPrinter? foundPrinter;
    try {
      foundPrinter = await adapter.discoverDirectAp(
        hostOverride: hostOverride,
        gateway: info.gateway,
        networkInterface: info.interfaceName,
        probeTimeout: const Duration(seconds: 2),
        scanFallbackTimeout: const Duration(seconds: 3),
      );
    } finally {
      await adapter.dispose();
    }

    if (foundPrinter == null) {
      statusMessage = '已连接打印机热点 ${info.ssid}，但未探测到 XSL 服务，请确认热点打印机 IP 后重试';
      lastActionFailed = true;
      return;
    }

    final apPrinter = _withActiveHotspotInterface(foundPrinter);
    _upsertAndSelectPrinter(apPrinter);
    if (autoConnectDriver) {
      await _connectDriverInternal(apPrinter);
      statusMessage =
          '已直连热点 ${info.ssid} 并连接 ${lastQueryResult?.productModel ?? apPrinter.displayName}';
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

  void setQuality(CloudPrintQuality quality) {
    selectedQuality = quality;
    selectedResolution = InkjetQualityPreset.fromCloudQuality(
      quality,
    ).defaultResolution;
    _notifyIfAlive();
  }

  Future<void> queryFullStatus() async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
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

  Future<void> queryDeviceConfig() async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return;
    }
    await _runBusy('正在查询网络、电源与语言配置…', _refreshConfigInternal);
  }

  Future<void> _refreshConfigInternal() async {
    final monitor = _driver!.statusMonitor;
    final wifi = await monitor.executeQuery(XslCodec.buildWifiStaQuery());
    final power = await monitor.executeQuery(XslCodec.buildPowerQuery());
    final lang = await monitor.executeQuery(XslCodec.buildLanguageQuery());
    lastWifiSta = wifi.wifiSta;
    lastPowerConfig = power.powerConfig;
    lastLanguage = lang.language;
    statusMessage =
        '配置已更新：STA=${lastWifiSta?.ipv4 ?? "-"}, '
        '休眠=${lastPowerConfig?.sleepMinutes ?? "-"}min, '
        '语言=${demoLabel(lastLanguage?.wireToken)}';
  }

  Future<void> configurePower({
    required bool savePower,
    required int sleepMinutes,
  }) async {
    if (!isConnected) return;
    await _runBusy('正在设置电源与休眠配置…', () async {
      await _driver!.configurePower(
        savePower: savePower,
        sleepMinutes: sleepMinutes,
      );
      try {
        await _refreshConfigInternal();
      } catch (_) {}
      statusMessage =
          '电源设置完成：节能=${savePower ? "ON" : "OFF"}, 休眠=$sleepMinutes分钟';
    });
  }

  Future<void> configureLanguage(InkjetLanguageCode language) async {
    if (!isConnected) return;
    await _runBusy('正在切换设备语言：${demoLabel(language.wireToken)}…', () async {
      await _driver!.configureLanguage(language);
      try {
        await _refreshConfigInternal();
      } catch (_) {}
      statusMessage = '设备语言已切换为 ${demoLabel(language.wireToken)}';
    });
  }

  Future<void> toggleActivePush(bool enable) async {
    if (!isConnected) return;
    await _runBusy(enable ? '正在开启 XSL 主动推送…' : '正在关闭 XSL 主动推送…', () async {
      if (enable) {
        await _pushSub?.cancel();
        _pushSub = _driver!.watchStatus().listen(
          (snap) {
            lastSnapshot = snap;
            lastPushAt = DateTime.now();
            _notifyIfAlive();
          },
          onError: (Object error) {
            statusMessage = '主动推送异常：$error';
            _notifyIfAlive();
          },
        );
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

  String _formatXsetError(String cmd, Object error) {
    final text = error.toString();
    if (error is FormatException &&
        (text.contains('Printer rejected XSET') ||
            text.contains('XSET FAIL'))) {
      return '打印机拒绝指令 $cmd（可能正忙或当前固件不支持）';
    }
    return '指令 $cmd 失败：$error';
  }

  Future<void> executeMaintenance(InkjetMaintenanceAction action) async {
    if (!isConnected) return;
    await _runBusy('正在执行维护：${action.name}...', () async {
      try {
        await _driver!.executeMaintenance(action);
      } on FormatException catch (error) {
        statusMessage = _formatXsetError(action.pjlCommand, error);
        return;
      }
      try {
        await _refreshStatusInternal();
      } catch (_) {}
      statusMessage = '维护指令 ${action.pjlCommand} 已执行';
    });
  }

  Future<void> scheduleNozzleWet(InkjetWetScheduleHours hours) async {
    if (!isConnected) return;
    await _runBusy('正在设置喷头保湿：${hours.hours}h...', () async {
      try {
        await _driver!.scheduleNozzleWet(hours);
      } on FormatException catch (error) {
        statusMessage = _formatXsetError('NOZZLE WET=${hours.hours}', error);
        return;
      }
      statusMessage = '喷头保湿定时：${hours.hours}h';
    });
  }

  Future<void> printBuiltInPage(InkjetBuiltInPage page) async {
    if (!isConnected) return;
    await _runBusy('正在打印内置页：${demoLabel(page)}...', () async {
      try {
        await _driver!.printBuiltInPage(page);
      } on FormatException catch (error) {
        statusMessage = _formatXsetError(page.pjlCommand, error);
        return;
      }
      try {
        await _refreshStatusInternal();
      } catch (_) {}
      statusMessage = '内置页指令 ${page.pjlCommand} 已发送';
    });
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
      lastActionFailed = true;
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
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
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return picked;
    } catch (e) {
      lastActionFailed = true;
      statusMessage = '操作失败：${DemoFeedbackCenter.formatMessage('$e')}';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return null;
    }
  }

  Future<CloudPrintResult> _executeXplPrintJob({
    required String jobName,
    required List<CloudPageRaster> pages,
    CloudPrintSettings? settingsOverride,
  }) async {
    final cancelToken = CloudCancelToken();
    _printCancelToken = cancelToken;
    try {
      final req = CloudPrintJobRequest(
        jobId: '${DateTime.now().millisecondsSinceEpoch % 100000}',
        jobName: jobName,
        settings: settingsOverride ?? buildCurrentSettings(),
        pages: pages,
        metadata: <String, Object?>{'inkjetResolution': selectedResolution},
        cancelToken: cancelToken,
      );
      final result = await _driver!.printJob(
        req,
        cancelToken: cancelToken,
        onProgress: (p) {
          jobProgress = p;
          _notifyIfAlive();
        },
      );
      lastPrintResult = result;
      if (result.success) {
        statusMessage =
            'XPL 数据发送完成：${result.pagesPrinted} sheet(s) (${result.bytesTransferred} B)';
      } else if (result.finalStage == CloudJobStage.cancelled) {
        statusMessage = 'XPL 任务已取消（${result.bytesTransferred} B sent)';
      } else {
        statusMessage = 'XPL 任务被阻止或失败：${result.error?.message ?? "error"}';
      }
      return result;
    } finally {
      _printCancelToken = null;
    }
  }

  Future<CloudPrintResult?> printXplDocument({
    CloudPrintSettings? settingsOverride,
    int? pageCountOverride,
    int rasterWidth = 128,
    int rasterHeight = 160,
  }) async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return null;
    }
    CloudPrintResult? result;
    await _runBusy('正在发送 XPL JBIG-1 页面…', () async {
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
      result = await _executeXplPrintJob(
        jobName: 'demo_xpl_doc.pdf',
        pages: pages,
        settingsOverride: settingsOverride,
      );
    });
    return result;
  }

  Future<CloudPrintResult?> printLocalImageXplDocument({
    CloudPrintSettings? settingsOverride,
  }) async {
    if (!isConnected) {
      lastActionFailed = true;
      statusMessage = '请先连接喷墨打印机 XSL/XPL';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return null;
    }
    final img = selectedLocalImage;
    if (img == null) {
      lastActionFailed = true;
      statusMessage = '请先选择本地图片';
      feedback?.emitError(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
      _notifyIfAlive();
      return null;
    }
    CloudPrintResult? result;
    await _runBusy('正在编码并发送本地图片 XPL 页面…', () async {
      final scaled = await scaleInkjetRgbaInIsolate(
        srcRgba: img.rgbaBytes,
        srcWidth: img.width,
        srcHeight: img.height,
        maxWidth: localImageMaxWidth,
        maxHeight: localImageMaxHeight,
      );
      result = await _executeXplPrintJob(
        jobName: img.name,
        pages: <CloudPageRaster>[
          CloudPageRaster(
            width: scaled.width,
            height: scaled.height,
            rgbaBytes: scaled.rgbaBytes,
          ),
        ],
        settingsOverride: settingsOverride,
      );
    });
    return result;
  }

  Future<void> cancelActivePrint() async {
    _printCancelToken?.cancel('Cancelled by user');
    await _driver?.cancel('Cancelled by user');
  }

  Future<void> disconnectDriver({bool notifyFeedback = false}) async {
    final wasConnected = _driver != null;
    await _pushSub?.cancel();
    _pushSub = null;
    activePushEnabled = false;
    lastPushAt = null;
    lastWifiSta = null;
    lastPowerConfig = null;
    lastLanguage = null;
    await _driver?.dispose();
    _driver = null;
    if (notifyFeedback && wasConnected) {
      lastActionFailed = false;
      statusMessage = '已断开喷墨 XSL/XPL 连接';
      feedback?.emitInfo(
        statusMessage,
        family: CloudPrinterFamily.colorInkjetPjl,
      );
    }
    _notifyIfAlive();
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
          family: CloudPrinterFamily.colorInkjetPjl,
        );
      }
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
    if (directWifiInfo != null) {
      await _printerWifiSession.disconnectPrinterWifi().catchError((_) {});
      directWifiInfo = null;
    }
    await realBleDevice?.disconnect();
    super.dispose();
  }
}
