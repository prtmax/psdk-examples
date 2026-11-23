import 'package:cloud_print_demo/main.dart';
import 'package:cloud_print_demo/src/controllers/demo_coordinator.dart';
import 'package:cloud_print_demo/src/controllers/inkjet_controller.dart';
import 'package:cloud_print_demo/src/controllers/real_transport_helper.dart';
import 'package:cloud_print_demo/src/controllers/sublimation_controller.dart';
import 'package:cloud_print_demo/src/models/demo_mode.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:cloud_print_demo/src/widgets/inkjet_tab.dart';
import 'package:cloud_print_demo/src/widgets/sublimation_tab.dart';

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
    'switches all 4 CloudPrinterFamily tabs, toggles Sim/Real mode, and opens/filters Protocol Inspector Drawer',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final coordinator = DemoCoordinator(
        colorCore: const PureDartColorCoreEngine(),
      );
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(CloudPrintDemoApp(coordinator: coordinator));
      await tester.pumpAndSettle();

      // Default is Simulation Mode & ESC WAN tab
      expect(coordinator.runMode, equals(DemoRunMode.simulation));
      expect(find.text('ESC 云打印'), findsOneWidget);
      expect(find.text('1. ESC 蓝牙 TLV 配网'), findsOneWidget);

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

      // Switch to Sublimation tab
      await tester.tap(find.byKey(const Key('tab_sublimationRpc')));
      await tester.pumpAndSettle();
      expect(find.text('热升华 RPC'), findsOneWidget);
      expect(find.text('1. 蓝牙配网与局域网发现'), findsOneWidget);

      // Switch to Color Inkjet tab
      await tester.tap(find.byKey(const Key('tab_colorInkjetPjl')));
      await tester.pumpAndSettle();
      expect(find.text('彩色喷墨 PJL'), findsOneWidget);
      expect(find.text('1. 蓝牙 ACL 配网与局域网发现'), findsOneWidget);

      // Connect XSL/XPL, trigger Yellow Low preset, and verify Preflight Confirmation Dialog
      await tester.runAsync(() async {
        await coordinator.inkjet.connectDriver();
        await coordinator.inkjet.applyFaultPreset(
          InkjetSimFaultPreset.yellowLow,
        );
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

      // Toggle Global Mode Switcher to Real Device and back to Simulation
      await tester.tap(find.text('真机'));
      await tester.pumpAndSettle();
      expect(coordinator.runMode, equals(DemoRunMode.realDevice));
      await coordinator.sublimation.connectDriver();
      expect(coordinator.sublimation.statusMessage, contains('请先发现并选择打印机'));
      expect(coordinator.sublimation.isConnected, isFalse);
      expect(find.text('扫描蓝牙'), findsOneWidget);
      expect(find.text('TestOfficeWifi'), findsOneWidget);
      expect(coordinator.inkjet.isConnected, isFalse);
      expect(coordinator.inkjet.selectedPrinter, isNull);

      // Color Inkjet tab in Real mode shows BLE prefix filter defaulted to 'h100'
      final filterFinder = find.byKey(
        const Key('ble_name_prefix_filter_field'),
      );
      expect(filterFinder, findsOneWidget);
      expect(
        tester.widget<TextField>(filterFinder).controller?.text,
        equals('h100'),
      );

      // Sublimation tab in Real mode shows BLE prefix filter defaulted to 'z11'
      await tester.tap(find.byKey(const Key('tab_sublimationRpc')));
      await tester.pumpAndSettle();
      expect(filterFinder, findsOneWidget);
      expect(
        tester.widget<TextField>(filterFinder).controller?.text,
        equals('z11'),
      );

      // Thermal LAN tab in Real mode does not render the BLE prefix filter field
      await tester.tap(find.byKey(const Key('tab_thermalLanStream')));
      await tester.pumpAndSettle();
      expect(filterFinder, findsNothing);

      await tester.tap(find.text('模拟'));
      await tester.pumpAndSettle();
      expect(coordinator.runMode, equals(DemoRunMode.simulation));

      // Open Protocol Inspector Drawer and verify captured frames & clear button
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      expect(find.textContaining('协议日志（'), findsOneWidget);

      await tester.tap(find.byTooltip('清空日志'));
      await tester.pumpAndSettle();
      expect(coordinator.inspector.count, equals(0));
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

      final coordinator = DemoCoordinator(
        colorCore: const PureDartColorCoreEngine(),
      );
      addTearDown(coordinator.dispose);

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

      // 1. ESC WAN Cloud tab (populated + scrolled)
      await tester.runAsync(() => coordinator.escWan.connectWan());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 2. Thermal LAN Stream tab (both dialects + scrolled)
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

      // 4. Color Inkjet PJL tab (connected + all 6 DropdownButtonFormFields + scrolled)
      final inkjetTab = find.byKey(const Key('tab_colorInkjetPjl'));
      await tester.ensureVisible(inkjetTab);
      await tester.tap(inkjetTab);
      await tester.pumpAndSettle();
      expect(find.text('彩色喷墨 PJL'), findsOneWidget);
      await tester.runAsync(() => coordinator.inkjet.connectDriver());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 5. Protocol Inspector Drawer at 360x640
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TX'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部').last);
      await tester.pumpAndSettle();

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

      await tester.pumpWidget(const CloudPrintDemoApp());
      await tester.pumpAndSettle();

      final provisionBtn = find.text('开始 TLV 配网');
      await tester.ensureVisible(provisionBtn);
      await tester.tap(provisionBtn);
      await tester.pump(const Duration(milliseconds: 5));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unmount immediately while CloudWanEscProvisioner has an active commandTimeout
      await tester.pumpWidget(const SizedBox.shrink());
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
          modeGetter: () => DemoRunMode.realDevice,
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
          modeGetter: () => DemoRunMode.realDevice,
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
      'Real mode SublimationTab and InkjetTab with BLE prefix filter render without overflow at 360x640',
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
          modeGetter: () => DemoRunMode.realDevice,
        );
        final inkjetController = InkjetController(
          inspector: inspector,
          registry: registry,
          colorCore: const PureDartColorCoreEngine(),
          modeGetter: () => DemoRunMode.realDevice,
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

        final coordinator = DemoCoordinator(
          colorCore: const PureDartColorCoreEngine(),
        );
        addTearDown(coordinator.dispose);

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
          inkjet.simTcpDevice.lastMaintenanceAction,
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
}
