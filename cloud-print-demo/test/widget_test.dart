import 'package:cloud_print_demo/main.dart';
import 'package:cloud_print_demo/src/controllers/demo_coordinator.dart';
import 'package:cloud_print_demo/src/controllers/esc_wan_controller.dart';
import 'package:cloud_print_demo/src/controllers/inkjet_controller.dart';
import 'package:cloud_print_demo/src/controllers/real_transport_helper.dart';
import 'package:cloud_print_demo/src/controllers/sublimation_controller.dart';
import 'package:cloud_print_demo/src/controllers/thermal_lan_controller.dart';
import 'package:cloud_print_demo/src/models/demo_feedback.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';
import 'package:cloud_print_demo/src/utils/local_image_service.dart';
import 'package:cloud_print_demo/src/widgets/common_widgets.dart';
import 'package:cloud_print_demo/src/widgets/inkjet_tab.dart';
import 'package:cloud_print_demo/src/widgets/sublimation_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_network/psdk_network.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import 'fakes/sim_esc_wan_stub.dart';
import 'fakes/sim_inkjet_stub.dart';
import 'fakes/sim_lan_ble_device.dart';
import 'fakes/sim_sublimation_stub.dart';
import 'fakes/sim_thermal_lan_stub.dart';

class _TestRealTransportHelper extends RealTransportHelper {
  _TestRealTransportHelper(super.inspector, this.seededDevices);

  final List<DemoBleDevice> seededDevices;

  @override
  Future<List<DemoBleDevice>> scanBle({
    required CloudPrinterFamily family,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    discoveredBleDevices
      ..clear()
      ..addAll(seededDevices);
    notifyListeners();
    return List.unmodifiable(discoveredBleDevices);
  }

  @override
  Future<void> stopBleScan() async {}
}

class _FakePrinterWifiSession extends PrinterWifiSession {
  @override
  Future<PrinterWifiConnectionInfo> connectToPrinterWifi({
    required String ssid,
    required String password,
    Duration timeout = const Duration(seconds: 35),
  }) async {
    return PrinterWifiConnectionInfo(
      ssid: ssid,
      interfaceName: 'wlan0-ap',
      address: '192.168.4.2',
      prefixLength: 24,
      gateway: '192.168.4.1',
    );
  }

  @override
  Future<void> disconnectPrinterWifi() async {}

  @override
  Future<PrinterWifiConnectionInfo?> refreshInfo() async => null;
}

class _WidgetTestRig {
  _WidgetTestRig({LocalImagePickerService? localImagePicker})
    : colorCore = const PureDartColorCoreEngine(),
      registry = CloudPrinterRegistry(),
      printerWifiSession = _FakePrinterWifiSession() {
    final inspector = ProtocolInspectorController();
    final feedback = DemoFeedbackCenter();
    final helper = _TestRealTransportHelper(inspector, const <DemoBleDevice>[]);

    escBle = SimEscConnectedDevice(inspector: inspector);
    escBackend = SimCloudWanBackend(inspector: inspector);
    final esc = EscWanController(
      inspector: inspector,
      feedback: feedback,
      localImagePicker: localImagePicker,
      provisionSettleDelay: const Duration(milliseconds: 15),
      provisionPollInterval: const Duration(milliseconds: 15),
      wanConfigFactory:
          ({
            String? apiBaseUrl,
            String? mqttHost,
            int mqttPort = 30501,
            bool mqttUseTls = true,
            String? serialNumber,
            String? deviceToken,
          }) => escBackend.createConfig(
            overrideSerialNumber: (serialNumber ?? '').isNotEmpty
                ? serialNumber
                : escBackend.serialNumber,
          ),
    )..realBleDevice = escBle;

    thermalBle = SimulatedLanBleDevice(
      inspector: inspector,
      family: CloudPrinterFamily.thermalLanStream,
      assignedIp: '192.168.1.77',
    );
    thermalBackend = SimThermalLanBackend(
      inspector: inspector,
      wifiDevice: thermalBle,
    );
    final thermal = ThermalLanController(
      inspector: inspector,
      feedback: feedback,
      realTransportHelper: helper,
      localImagePicker: localImagePicker,
      networkFactory: thermalBackend.createScopedNetwork,
      discoveryScannerFactory: () =>
          thermalBackend.createScopedNetwork().createScanner(),
      useAndroidDiscoveryHooks: false,
      postProvisionDiscoveryDelay: Duration.zero,
      provisionSettleDelay: const Duration(milliseconds: 15),
      provisionPollInterval: const Duration(milliseconds: 15),
      scanTimeout: const Duration(milliseconds: 120),
      scanProbeInterval: const Duration(milliseconds: 50),
      discoveryAttempts: 1,
    )..setup.realBleDevice = thermalBle;

    subBle = SimulatedLanBleDevice(inspector: inspector);
    subUdp = SimulatedSublimationUdpTransport(inspector: inspector);
    subTcp = SimulatedSublimationTcpDevice(inspector: inspector);
    final sub =
        SublimationController(
            inspector: inspector,
            feedback: feedback,
            registry: registry,
            colorCore: colorCore,
            printerWifiSession: printerWifiSession,
            localImagePicker: localImagePicker,
            discoveryScannerFactory: () =>
                SublimationLanScanner(transport: subUdp),
            directDeviceOverride: () => subTcp,
            useAndroidDiscoveryHooks: false,
            statusPollInterval: const Duration(milliseconds: 20),
            cardWidth: 96,
            cardHeight: 64,
            printQuality: CloudPrintQuality.fine,
          )
          ..setup.realBleDevice = subBle
          ..selectedPrinter = DiscoveredCloudPrinter(
            id: 'sim-sub-d300',
            displayName: 'SubSim-D300Kp',
            family: CloudPrinterFamily.sublimationRpc,
            host: '192.168.1.88',
            port: 9100,
            macAddress: '11:22:33:44:55:66',
          );

    inkjetBle = SimulatedInkjetBleDevice(inspector: inspector);
    inkjetTcp = SimulatedInkjetTcpDevice(inspector: inspector);
    inkjetMdns = SimulatedInkjetMdnsBrowser(inspector: inspector);
    inkjetSoftApProbe = SimulatedInkjetSoftApProbe(
      inspector: inspector,
      tcpDevice: inkjetTcp,
    );
    inkjetNetworkBinder = SimulatedInkjetNetworkBinder(inkjetTcp);
    final ink =
        InkjetController(
            inspector: inspector,
            feedback: feedback,
            registry: registry,
            colorCore: colorCore,
            printerWifiSession: printerWifiSession,
            localImagePicker: localImagePicker,
            networkBinderOverride: inkjetNetworkBinder,
            mdnsBrowserOverride: inkjetMdns.browse,
            softApProbeOverride: inkjetSoftApProbe.call,
            bleGattHooksOverride: inkjetBle.buildGattHooks(),
            directDeviceOverride: () => inkjetTcp,
            allowLoopbackForTesting: true,
            useAndroidDiscoveryHooks: false,
            discoveryTimeout: const Duration(milliseconds: 120),
            discoveryProbeInterval: const Duration(milliseconds: 50),
            discoveryAttempts: 1,
            localImageMaxWidth: 160,
            localImageMaxHeight: 200,
          )
          ..realBleDevice = inkjetBle
          ..selectedPrinter = DiscoveredCloudPrinter(
            id: 'sim-inkjet',
            displayName: 'SimColorJet-Pro',
            family: CloudPrinterFamily.colorInkjetPjl,
            host: '192.168.1.92',
            port: 9100,
          );

    coordinator = DemoCoordinator(
      colorCore: colorCore,
      localImagePicker: localImagePicker,
      inspector: inspector,
      feedback: feedback,
      printerWifiSession: printerWifiSession,
      realTransportHelper: helper,
      registry: registry,
      escWan: esc,
      thermalLan: thermal,
      sublimation: sub,
      inkjet: ink,
    );
  }

  final ColorCoreEngine colorCore;
  final CloudPrinterRegistry registry;
  final _FakePrinterWifiSession printerWifiSession;
  late final DemoCoordinator coordinator;
  late final SimEscConnectedDevice escBle;
  late final SimCloudWanBackend escBackend;
  late final SimulatedLanBleDevice thermalBle;
  late final SimThermalLanBackend thermalBackend;
  late final SimulatedLanBleDevice subBle;
  late final SimulatedSublimationUdpTransport subUdp;
  late final SimulatedSublimationTcpDevice subTcp;
  late final SimulatedInkjetBleDevice inkjetBle;
  late final SimulatedInkjetTcpDevice inkjetTcp;
  late final SimulatedInkjetMdnsBrowser inkjetMdns;
  late final SimulatedInkjetSoftApProbe inkjetSoftApProbe;
  late final SimulatedInkjetNetworkBinder inkjetNetworkBinder;

  Future<void> dispose() async {
    escBackend.dispose();
    await subTcp.disconnect();
    await inkjetBle.disconnect();
    await inkjetTcp.disconnect();
    await thermalBle.disconnect();
    await coordinator.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const wifiChannel = MethodChannel('dev.fluttercommunity.plus/network_info');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          wifiChannel,
          (call) async => call.method == 'wifiName' ? 'TestOfficeWifi' : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wifiChannel, null);
  });
  testWidgets(
    'renders all 4 real-device tabs without simulation switcher and opens/filters Protocol Inspector Drawer',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rig = _WidgetTestRig();
      addTearDown(rig.dispose);
      final coordinator = rig.coordinator;

      await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
      await tester.pumpAndSettle();

      // Only Real Device mode exists — global switcher & simulation label are gone
      expect(find.byKey(const Key('global_mode_switcher')), findsNothing);
      expect(find.text('模拟'), findsNothing);
      expect(find.text('ESC 云打印'), findsOneWidget);
      expect(find.text('1. ESC 蓝牙 TLV 配网'), findsOneWidget);
      expect(find.text('TestOfficeWifi'), findsOneWidget);

      // Trigger ESC provisioning inside real async zone (uses Timer/DateTime deadlines)
      await tester.runAsync(() async {
        await coordinator.escWan.provisionBleWifi(
          ssid: 'DemoOfficeWiFi',
          password: 'office-pass-2026',
        );
      });
      await tester.pump();
      expect(
        coordinator.escWan.lastProvisionResult?.success,
        isTrue,
        reason:
            'busy=${coordinator.escWan.busy}, msg=${coordinator.escWan.statusMessage}, logs=${coordinator.inspector.entries.map((e) => e.decodedSummary).toList()}',
      );
      expect(coordinator.inspector.count, greaterThan(0));

      // Switch to Thermal LAN tab
      await tester.tap(find.byKey(const Key('tab_thermalLanStream')));
      await tester.pumpAndSettle();
      expect(find.text('热敏局域网打印'), findsOneWidget);
      expect(find.text('1. 蓝牙配网与局域网发现'), findsOneWidget);
      expect(
        find.byKey(const Key('ble_name_prefix_filter_field')),
        findsNothing,
      );

      // Switch to Sublimation tab & verify real guard when no printer is selected
      await tester.tap(find.byKey(const Key('tab_sublimationRpc')));
      await tester.pumpAndSettle();
      expect(find.text('热升华 RPC'), findsOneWidget);
      expect(find.text('1. 蓝牙配网与局域网发现'), findsOneWidget);
      final subFilterFinder = find.byKey(
        const Key('ble_name_prefix_filter_field'),
      );
      expect(subFilterFinder, findsOneWidget);
      expect(
        tester.widget<TextField>(subFilterFinder).controller?.text,
        equals('z11'),
      );
      final savedSubPrinter = coordinator.sublimation.selectedPrinter;
      coordinator.sublimation.selectedPrinter = null;
      await coordinator.sublimation.connectDriver();
      expect(coordinator.sublimation.statusMessage, contains('请先发现并选择打印机'));
      expect(coordinator.sublimation.isConnected, isFalse);
      coordinator.sublimation.selectedPrinter = savedSubPrinter;

      // Switch to Color Inkjet tab
      await tester.tap(find.byKey(const Key('tab_colorInkjetPjl')));
      await tester.pumpAndSettle();
      expect(find.text('彩色喷墨 PJL'), findsOneWidget);
      expect(find.text('1. 蓝牙 ACL 配网与局域网发现'), findsOneWidget);
      final inkFilterFinder = find.byKey(
        const Key('ble_name_prefix_filter_field'),
      );
      expect(inkFilterFinder, findsOneWidget);
      expect(
        tester.widget<TextField>(inkFilterFinder).controller?.text,
        equals('h100'),
      );
      expect(find.textContaining('模拟故障与墨量'), findsNothing);

      // Connect XSL/XPL, trigger Yellow Low preset on fake TCP, and verify Preflight flow
      await tester.runAsync(() async {
        await coordinator.inkjet.connectDriver();
        rig.inkjetTcp.applyInkPreset(
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
        await coordinator.inkjet.queryFullStatus();
      });
      await tester.pumpAndSettle();
      expect(coordinator.inkjet.isConnected, isTrue);
      expect(find.text('黄色（Y）'), findsOneWidget);
      expect(find.text('12% (墨量低)'), findsOneWidget);

      // Verify preflight result triggers confirmation flow and completes XPL print
      final preflight = await tester.runAsync(
        () => coordinator.inkjet.runPreflightCheck(),
      );
      expect(preflight?.outcome, equals(InkjetPreflightOutcome.blocked));
      expect(preflight?.checkCode, equals(InkjetPreflightCheckCode.allInkLow));

      await tester.runAsync(() async {
        await coordinator.inkjet.printXplDocument(
          settingsOverride: coordinator.inkjet.buildCurrentSettings(
            continueOnLowOverride: true,
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(coordinator.inkjet.lastPrintResult?.success, isTrue);

      // Open Protocol Inspector Page and verify captured frames, clear button, and system Back
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      expect(find.textContaining('协议日志（'), findsOneWidget);

      await tester.tap(find.byTooltip('清空日志'));
      await tester.pumpAndSettle();
      expect(coordinator.inspector.count, equals(0));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('协议日志（'), findsNothing);
      expect(find.text('打印测试'), findsOneWidget);
    },
  );

  testWidgets(
    'renders all 4 tabs, scrolls, and opens Protocol Inspector Drawer at 360x640 mobile viewport with zero RenderFlex overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final errors = <FlutterErrorDetails>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        prevOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = prevOnError;
      });

      final rig = _WidgetTestRig();
      addTearDown(rig.dispose);
      final coordinator = rig.coordinator;

      await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
      await tester.pumpAndSettle();

      Future<void> scrollCurrentTab() async {
        final listView = find.byType(ListView).first;
        for (var i = 0; i < 4; i++) {
          await tester.drag(listView, const Offset(0, -350));
          await tester.pumpAndSettle();
        }
        for (var i = 0; i < 4; i++) {
          await tester.drag(listView, const Offset(0, 350));
          await tester.pumpAndSettle();
        }
      }

      // 1. ESC WAN Cloud tab (connected + scrolled)
      await tester.runAsync(() => coordinator.escWan.connectWan());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 2. Thermal LAN Stream tab (scrolled)
      final thermalTab = find.byKey(const Key('tab_thermalLanStream'));
      await tester.ensureVisible(thermalTab);
      await tester.tap(thermalTab);
      await tester.pumpAndSettle();
      expect(find.text('热敏局域网打印'), findsOneWidget);
      expect(find.text('开始配网'), findsOneWidget);
      expect(find.textContaining('Mesh'), findsNothing);
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 3. Sublimation RPC tab (connected + scrolled)
      final subTab = find.byKey(const Key('tab_sublimationRpc'));
      await tester.ensureVisible(subTab);
      await tester.tap(subTab);
      await tester.pumpAndSettle();
      expect(find.text('热升华 RPC'), findsOneWidget);
      await tester.runAsync(() => coordinator.sublimation.connectDriver());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 4. Color Inkjet PJL tab (connected + all DropdownButtonFormFields + scrolled)
      final inkjetTab = find.byKey(const Key('tab_colorInkjetPjl'));
      await tester.ensureVisible(inkjetTab);
      await tester.tap(inkjetTab);
      await tester.pumpAndSettle();
      expect(find.text('彩色喷墨 PJL'), findsOneWidget);
      await tester.runAsync(() => coordinator.inkjet.connectDriver());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 5. Protocol Inspector Page at 360x640 + system Back returns to main page
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TX'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部').last);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('打印测试'), findsOneWidget);

      expect(
        errors,
        isEmpty,
        reason: errors.map((e) => e.exceptionAsString()).join('\n'),
      );
    },
  );

  testWidgets(
    'unmounting CloudPrintDemoApp while Provision ESC TLV is in progress cancels timers cleanly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rig = _WidgetTestRig();
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        CloudPrintDemoApp(
          coordinator: rig.coordinator,
          disposeCoordinatorOnUnmount: true,
        ),
      );
      await tester.pumpAndSettle();

      final provisionBtn = find.text('开始 TLV 配网');
      await tester.ensureVisible(provisionBtn);
      await tester.tap(provisionBtn);
      await tester.pump(const Duration(milliseconds: 5));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unmount immediately while CloudWanEscProvisioner has an active commandTimeout
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump();
    },
  );

  group('BLE name prefix filtering', () {
    test(
      'parseBleNamePrefixes and matchesBleNamePrefixes handle comma separation and case insensitivity',
      () {
        final subDefaultPrefixes = parseBleNamePrefixes('z11');
        expect(subDefaultPrefixes, equals(<String>['z11']));
        expect(matchesBleNamePrefixes('Z11-1234', subDefaultPrefixes), isTrue);
        expect(matchesBleNamePrefixes('z11_AB', subDefaultPrefixes), isTrue);
        expect(matchesBleNamePrefixes('  Z11 ', subDefaultPrefixes), isTrue);
        expect(matchesBleNamePrefixes('my-z11', subDefaultPrefixes), isFalse);
        expect(matchesBleNamePrefixes('H100-1', subDefaultPrefixes), isFalse);
        expect(matchesBleNamePrefixes(null, subDefaultPrefixes), isFalse);
        expect(matchesBleNamePrefixes('', subDefaultPrefixes), isFalse);
        expect(matchesBleNamePrefixes('   ', subDefaultPrefixes), isFalse);

        final inkjetDefaultPrefixes = parseBleNamePrefixes('h100');
        expect(inkjetDefaultPrefixes, equals(<String>['h100']));
        expect(
          matchesBleNamePrefixes('H100-1234', inkjetDefaultPrefixes),
          isTrue,
        );
        expect(
          matchesBleNamePrefixes('h100_AB', inkjetDefaultPrefixes),
          isTrue,
        );
        expect(matchesBleNamePrefixes('Z11-1', inkjetDefaultPrefixes), isFalse);

        final multi = parseBleNamePrefixes('z11, h100， P10 , ');
        expect(multi, equals(<String>['z11', 'h100', 'p10']));
        expect(matchesBleNamePrefixes('H100-99', multi), isTrue);
        expect(matchesBleNamePrefixes('p10_test', multi), isTrue);
        expect(matchesBleNamePrefixes('X1-z11', multi), isFalse);

        final empty = parseBleNamePrefixes(' , ， ');
        expect(empty, isEmpty);
        expect(matchesBleNamePrefixes('AnyDevice', empty), isTrue);
        expect(matchesBleNamePrefixes('   ', empty), isFalse);
        expect(matchesBleNamePrefixes(null, empty), isFalse);
      },
    );

    testWidgets(
      'SublimationTab filters discovered BLE devices by comma-separated prefixes starting with z11 and clears cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final inspector = ProtocolInspectorController();
        final registry = CloudPrinterRegistry();
        final subController = SublimationController(
          inspector: inspector,
          registry: registry,
          colorCore: const PureDartColorCoreEngine(),
        );
        final helper = _TestRealTransportHelper(inspector, <DemoBleDevice>[
          DemoBleDevice.test(name: 'Z11-AA11', mac: 'AA:00:00:00:00:01'),
          DemoBleDevice.test(name: 'z11_bb22', mac: 'AA:00:00:00:00:02'),
          DemoBleDevice.test(name: 'H100-CC33', mac: 'AA:00:00:00:00:03'),
          DemoBleDevice.test(name: 'Other-z11', mac: 'AA:00:00:00:00:04'),
        ]);
        addTearDown(() async {
          await subController.dispose();
          await helper.dispose();
          inspector.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SublimationTab(
                controller: subController,
                realTransportHelper: helper,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final filterField = find.byKey(
          const Key('ble_name_prefix_filter_field'),
        );
        expect(filterField, findsOneWidget);
        expect(
          tester.widget<TextField>(filterField).controller?.text,
          equals('z11'),
        );

        // Open BLE picker with default 'z11' prefix
        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('Z11-AA11'), findsOneWidget);
        expect(find.text('z11_bb22'), findsOneWidget);
        expect(find.text('H100-CC33'), findsNothing);
        expect(find.text('Other-z11'), findsNothing);
        expect(find.text('前缀过滤：z11'), findsOneWidget);

        // Close picker, update filter to 'z11，h100' (Chinese comma + spaces)
        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();
        await tester.enterText(filterField, 'z11， h100');
        await tester.pumpAndSettle();
        expect(subController.setup.bleNamePrefixFilter, equals('z11， h100'));

        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('Z11-AA11'), findsOneWidget);
        expect(find.text('z11_bb22'), findsOneWidget);
        expect(find.text('H100-CC33'), findsOneWidget);
        expect(find.text('Other-z11'), findsNothing);
        expect(find.text('前缀过滤：z11, h100'), findsOneWidget);

        // Clear filter inside picker and verify all 4 devices appear
        await tester.tap(find.text('清空过滤').last);
        await tester.pumpAndSettle();
        expect(subController.setup.bleNamePrefixFilter, isEmpty);
        expect(find.text('Z11-AA11'), findsOneWidget);
        expect(find.text('z11_bb22'), findsOneWidget);
        expect(find.text('H100-CC33'), findsOneWidget);
        expect(find.text('Other-z11'), findsOneWidget);

        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'InkjetTab filters discovered BLE devices by comma-separated prefixes starting with h100 and clears cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final inspector = ProtocolInspectorController();
        final registry = CloudPrinterRegistry();
        final inkjetController = InkjetController(
          inspector: inspector,
          registry: registry,
          colorCore: const PureDartColorCoreEngine(),
        );
        final helper = _TestRealTransportHelper(inspector, <DemoBleDevice>[
          DemoBleDevice.test(name: 'H100-AA11', mac: 'BB:00:00:00:00:01'),
          DemoBleDevice.test(name: 'h100_bb22', mac: 'BB:00:00:00:00:02'),
          DemoBleDevice.test(name: 'Z11-CC33', mac: 'BB:00:00:00:00:03'),
          DemoBleDevice.test(name: 'Other-h100', mac: 'BB:00:00:00:00:04'),
        ]);
        addTearDown(() async {
          await inkjetController.dispose();
          await helper.dispose();
          inspector.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkjetTab(
                controller: inkjetController,
                realTransportHelper: helper,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final filterField = find.byKey(
          const Key('ble_name_prefix_filter_field'),
        );
        expect(filterField, findsOneWidget);
        expect(
          tester.widget<TextField>(filterField).controller?.text,
          equals('h100'),
        );

        // Open BLE picker with default 'h100' prefix
        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('H100-AA11'), findsOneWidget);
        expect(find.text('h100_bb22'), findsOneWidget);
        expect(find.text('Z11-CC33'), findsNothing);
        expect(find.text('Other-h100'), findsNothing);
        expect(find.text('前缀过滤：h100'), findsOneWidget);

        // Close picker, update filter to 'h100， z11' (Chinese comma + spaces)
        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();
        await tester.enterText(filterField, 'h100， z11');
        await tester.pumpAndSettle();
        expect(inkjetController.bleNamePrefixFilter, equals('h100， z11'));

        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('H100-AA11'), findsOneWidget);
        expect(find.text('h100_bb22'), findsOneWidget);
        expect(find.text('Z11-CC33'), findsOneWidget);
        expect(find.text('Other-h100'), findsNothing);
        expect(find.text('前缀过滤：h100, z11'), findsOneWidget);

        // Clear filter inside picker and verify all 4 devices appear
        await tester.tap(find.text('清空过滤').last);
        await tester.pumpAndSettle();
        expect(inkjetController.bleNamePrefixFilter, isEmpty);
        expect(find.text('H100-AA11'), findsOneWidget);
        expect(find.text('h100_bb22'), findsOneWidget);
        expect(find.text('Z11-CC33'), findsOneWidget);
        expect(find.text('Other-h100'), findsOneWidget);

        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'SublimationTab and InkjetTab with BLE prefix filter render without overflow at 360x640',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
          prevOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = prevOnError;
        });

        final inspector = ProtocolInspectorController();
        final registry = CloudPrinterRegistry();
        final subController = SublimationController(
          inspector: inspector,
          registry: registry,
          colorCore: const PureDartColorCoreEngine(),
        );
        final inkjetController = InkjetController(
          inspector: inspector,
          registry: registry,
          colorCore: const PureDartColorCoreEngine(),
        );
        final helper = _TestRealTransportHelper(inspector, <DemoBleDevice>[
          DemoBleDevice.test(name: 'Z11-AA11', mac: 'AA:00:00:00:00:01'),
          DemoBleDevice.test(name: 'H100-AA11', mac: 'BB:00:00:00:00:01'),
        ]);
        addTearDown(() async {
          await subController.dispose();
          await inkjetController.dispose();
          await helper.dispose();
          inspector.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SublimationTab(
                controller: subController,
                realTransportHelper: helper,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('ble_name_prefix_filter_field')),
          findsOneWidget,
        );

        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('Z11-AA11'), findsOneWidget);
        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('lan_manual_ip_field')), findsOneWidget);
        expect(
          find.byKey(const Key('lan_probe_manual_ip_btn')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkjetTab(
                controller: inkjetController,
                realTransportHelper: helper,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('ble_name_prefix_filter_field')),
          findsOneWidget,
        );

        await tester.tap(find.text('扫描蓝牙'));
        await tester.pumpAndSettle();
        expect(find.text('H100-AA11'), findsOneWidget);
        await tester.tap(find.byTooltip('关闭扫描'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('inkjet_manual_ip_field')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('inkjet_manual_ip_field')), findsOneWidget);
        expect(
          find.byKey(const Key('inkjet_probe_manual_ip_btn')),
          findsOneWidget,
        );

        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      },
    );
  });

  group('InkjetTab UX and regression guards', () {
    testWidgets(
      'syncs resolution when quality changes, shows paperType dropdown, confirms factoryRestore, and avoids 360x640 overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
          prevOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = prevOnError;
        });

        final rig = _WidgetTestRig();
        addTearDown(rig.dispose);
        final coordinator = rig.coordinator;

        await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
        await tester.pumpAndSettle();

        final inkjetTabFinder = find.byKey(const Key('tab_colorInkjetPjl'));
        await tester.ensureVisible(inkjetTabFinder);
        await tester.pumpAndSettle();
        await tester.tap(inkjetTabFinder);
        await tester.pumpAndSettle();

        final inkjet = coordinator.inkjet;
        expect(inkjet.selectedQuality, equals(CloudPrintQuality.standard));
        expect(inkjet.selectedResolution, equals(InkjetResolution.dpi600x600));
        expect(inkjet.pageCount, equals(1));

        inkjet.setQuality(CloudPrintQuality.draft);
        expect(inkjet.selectedResolution, equals(InkjetResolution.dpi300x600));
        inkjet.setQuality(CloudPrintQuality.photo);
        expect(inkjet.selectedResolution, equals(InkjetResolution.dpi600x1200));

        await tester.runAsync(() async {
          await inkjet.connectDriver();
          await inkjet.queryDeviceConfig();
        });
        await tester.pumpAndSettle();

        final listScrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('查询网络/电源/语言'),
          250,
          scrollable: listScrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text('查询网络/电源/语言'), findsOneWidget);
        expect(inkjet.lastWifiSta?.ipv4, equals('192.168.1.92'));
        expect(inkjet.lastWifiSta?.subnetMask, equals('255.255.255.0'));
        expect(inkjet.lastWifiSta?.gateway, equals('192.168.1.1'));

        // Tapping factory restore opens confirmation dialog and does not fire
        // command if cancelled.
        final restoreBtn = find.text('恢复出厂设置');
        await tester.scrollUntilVisible(
          restoreBtn,
          250,
          scrollable: listScrollable,
        );
        await tester.pumpAndSettle();
        await tester.tap(restoreBtn);
        await tester.pumpAndSettle();
        expect(find.text('确认恢复出厂设置？'), findsOneWidget);
        await tester.tap(find.text('取消').last);
        await tester.pumpAndSettle();
        expect(
          rig.inkjetTcp.lastMaintenanceAction,
          isNot(equals(InkjetMaintenanceAction.factoryRestore)),
        );

        await tester.scrollUntilVisible(
          find.text('纸张类型'),
          250,
          scrollable: listScrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text('纸张类型'), findsOneWidget);

        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      },
    );
  });

  group('Unified interactive feedback UX', () {
    testWidgets(
      'SublimationTab shows SnackBar and ActionStatusBanner feedback on settings update and invalid input at 360x640',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
          prevOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = prevOnError;
        });

        final rig = _WidgetTestRig();
        addTearDown(rig.dispose);
        final coordinator = rig.coordinator;

        await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
        await tester.pumpAndSettle();

        final subTab = find.byKey(const Key('tab_sublimationRpc'));
        await tester.ensureVisible(subTab);
        await tester.tap(subTab);
        await tester.pumpAndSettle();

        await tester.runAsync(() => coordinator.sublimation.connectDriver());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(const Key('demo_feedback_snackbar')), findsOneWidget);
        expect(find.byType(ActionStatusBanner), findsAtLeastNWidgets(1));

        final listScrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        final applyBtn = find.widgetWithText(FilledButton, '应用');
        await tester.scrollUntilVisible(
          applyBtn,
          60,
          scrollable: listScrollable,
        );
        await tester.pumpAndSettle();

        final autoShutDownField = find.widgetWithText(TextField, '15');
        await tester.enterText(autoShutDownField, '30');
        await tester.pump();
        await Scrollable.ensureVisible(
          tester.element(applyBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();

        Future<void> waitSubIdle() => tester.runAsync(() async {
          final deadline = DateTime.now().add(const Duration(seconds: 3));
          while (coordinator.sublimation.busy &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });

        await tester.tap(applyBtn);
        await tester.pump();
        await waitSubIdle();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(coordinator.sublimation.lastActionFailed, isFalse);
        expect(
          coordinator.sublimation.statusMessage,
          contains('自动关机分钟数已更新：30 min'),
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('demo_feedback_snackbar')),
            matching: find.textContaining('自动关机分钟数已更新：30 min'),
          ),
          findsOneWidget,
        );

        await tester.enterText(find.widgetWithText(TextField, '30'), '1');
        await tester.pump();
        await Scrollable.ensureVisible(
          tester.element(applyBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(applyBtn);
        await tester.pump();
        await waitSubIdle();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(coordinator.sublimation.lastActionFailed, isTrue);
        expect(
          find.descendant(
            of: find.byKey(const Key('demo_feedback_snackbar')),
            matching: find.textContaining(
              'autoShutDownMinutes must be 0 or in 2..65535 minutes',
            ),
          ),
          findsOneWidget,
        );

        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      },
    );

    testWidgets(
      'DirectApWifiPanel renders without overflow at 360x640 on SublimationTab and InkjetTab and queries BLE AP credentials',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
          prevOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = prevOnError;
        });

        final rig = _WidgetTestRig();
        addTearDown(rig.dispose);
        final coordinator = rig.coordinator;

        await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
        await tester.pumpAndSettle();

        // 1. SublimationTab DirectApWifiPanel + BLE query
        final subTab = find.byKey(const Key('tab_sublimationRpc'));
        await tester.ensureVisible(subTab);
        await tester.tap(subTab);
        await tester.pumpAndSettle();

        final subScrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        final queryBleBtn = find.byKey(const Key('ap_query_ble_btn'));
        await tester.scrollUntilVisible(
          queryBleBtn,
          80,
          scrollable: subScrollable,
        );
        await Scrollable.ensureVisible(
          tester.element(queryBleBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();

        await tester.tap(queryBleBtn);
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 25));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          if (!coordinator.sublimation.busy &&
              coordinator.sublimation.directWifiSsid.isNotEmpty) {
            break;
          }
        }
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          coordinator.sublimation.directWifiSsid,
          equals('Z11_SIM_AP'),
          reason:
              'bleState=${rig.subBle.connectionState().name}; '
              'status=${coordinator.sublimation.statusMessage}; '
              'inspector=${coordinator.inspector.entries.map((e) => '${e.transport}:${e.decodedSummary}').join(' | ')}',
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('ap_ssid_field')),
            matching: find.text('Z11_SIM_AP'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('demo_feedback_snackbar')),
            matching: find.textContaining('Z11_SIM_AP'),
          ),
          findsOneWidget,
        );

        // 2. InkjetTab DirectApWifiPanel + BLE query
        final inkjetTab = find.byKey(const Key('tab_colorInkjetPjl'));
        await tester.ensureVisible(inkjetTab);
        await tester.tap(inkjetTab);
        await tester.pumpAndSettle();

        final inkScrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        final inkQueryBleBtn = find.byKey(const Key('ap_query_ble_btn'));
        await tester.scrollUntilVisible(
          inkQueryBleBtn,
          80,
          scrollable: inkScrollable,
        );
        await Scrollable.ensureVisible(
          tester.element(inkQueryBleBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();

        await tester.tap(inkQueryBleBtn);
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 25));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          if (!coordinator.inkjet.busy &&
              coordinator.inkjet.directWifiSsid.isNotEmpty) {
            break;
          }
        }
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          coordinator.inkjet.directWifiSsid,
          equals('H100-SIM-AP'),
          reason: 'status=${coordinator.inkjet.statusMessage}',
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('ap_ssid_field')),
            matching: find.text('H100-SIM-AP'),
          ),
          findsOneWidget,
        );
        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      },
    );

    testWidgets(
      'LocalImagePrintCard renders and picks local image across all 4 tabs at 360x640 without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details);
          prevOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = prevOnError;
        });

        final rgba = Uint8List(24 * 16 * 4)..fillRange(0, 24 * 16 * 4, 255);
        final pickedSample = PickedLocalImage.fromRgba(
          name: 'picked_demo.png',
          width: 24,
          height: 16,
          rgbaBytes: rgba,
        );
        final rig = _WidgetTestRig(
          localImagePicker: LocalImagePickerService(
            pickerOverride: () async => pickedSample,
          ),
        );
        addTearDown(rig.dispose);
        final coordinator = rig.coordinator;

        await tester.runAsync(() async {
          await coordinator.escWan.connectWan();
          await coordinator.thermalLan.setup.discoverPrinters();
          await coordinator.thermalLan.connectTcpPrinter();
          await coordinator.sublimation.connectDriver();
          await coordinator.inkjet.connectDriver();
        });

        await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
        await tester.pumpAndSettle();

        final cases = <(CloudPrinterFamily, String)>[
          (CloudPrinterFamily.escWanCloud, 'esc'),
          (CloudPrinterFamily.thermalLanStream, 'thermal'),
          (CloudPrinterFamily.sublimationRpc, 'sub'),
          (CloudPrinterFamily.colorInkjetPjl, 'inkjet'),
        ];

        for (final entry in cases) {
          final (family, prefix) = entry;
          final tab = find.byKey(Key('tab_${family.name}'));
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();

          final scrollable = find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first;
          final pickBtn = find.byKey(Key('${prefix}_pick_local_image_btn'));
          await tester.scrollUntilVisible(pickBtn, 100, scrollable: scrollable);
          await Scrollable.ensureVisible(
            tester.element(pickBtn),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();

          final printBtnFinder = find.byKey(
            Key('${prefix}_print_local_image_btn'),
          );
          final beforeBtn = tester.widget<ButtonStyleButton>(printBtnFinder);
          expect(beforeBtn.onPressed, isNull);

          await tester.tap(pickBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          expect(
            find.byKey(Key('${prefix}_local_image_preview')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(Key('${prefix}_local_image_preview')),
              matching: find.text('picked_demo.png'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(Key('${prefix}_local_image_preview')),
              matching: find.text('24 × 16 px'),
            ),
            findsOneWidget,
          );

          final afterBtn = tester.widget<ButtonStyleButton>(printBtnFinder);
          expect(afterBtn.onPressed, isNotNull);
        }

        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      },
    );
  });
}
