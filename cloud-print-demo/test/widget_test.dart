import 'package:cloud_print_demo/main.dart';
import 'package:cloud_print_demo/src/controllers/demo_coordinator.dart';
import 'package:cloud_print_demo/src/controllers/inkjet_controller.dart';
import 'package:cloud_print_demo/src/models/demo_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';

void main() {
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
      expect(find.text('ESC WAN Cloud'), findsOneWidget);
      expect(
        find.text('1. ESC BLE TLV Provisioning (psdk_fruit_esc)'),
        findsOneWidget,
      );

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
      expect(find.text('Thermal LAN Stream'), findsOneWidget);
      expect(
        find.text('1. Dual-Dialect Wi-Fi Provisioning (psdk_fruit_wifi)'),
        findsOneWidget,
      );

      // Switch to Sublimation tab
      await tester.tap(find.byKey(const Key('tab_sublimationRpc')));
      await tester.pumpAndSettle();
      expect(find.text('Sublimation RPC'), findsOneWidget);
      expect(
        find.text('1. Dual-Mode BLE Provisioning (0x180B AT & 0xA5 0x53 Mesh)'),
        findsOneWidget,
      );

      // Switch to Color Inkjet tab
      await tester.tap(find.byKey(const Key('tab_colorInkjetPjl')));
      await tester.pumpAndSettle();
      expect(find.text('Color Inkjet PJL'), findsOneWidget);
      expect(
        find.text('1. BLE ACL Provisioning & mDNS / SoftAP Discovery'),
        findsOneWidget,
      );

      // Connect XSL/XPL, trigger Yellow Low preset, and verify Preflight Confirmation Dialog
      await tester.runAsync(() async {
        await coordinator.inkjet.connectDriver();
        await coordinator.inkjet.applyFaultPreset(
          InkjetSimFaultPreset.yellowLow,
        );
      });
      await tester.pumpAndSettle();
      expect(coordinator.inkjet.isConnected, isTrue);
      expect(find.text('Yellow (Y)'), findsOneWidget);
      expect(find.text('12% (LOW)'), findsOneWidget);

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
      await tester.tap(find.text('Real'));
      await tester.pumpAndSettle();
      expect(coordinator.runMode, equals(DemoRunMode.realDevice));
      await coordinator.sublimation.setUdp1901Status(1);
      expect(
        coordinator.sublimation.statusMessage,
        contains('Select a discovered printer'),
      );
      expect(coordinator.sublimation.lastUdp1901Status, isNull);
      expect(find.text('Scan BLE'), findsOneWidget);
      expect(coordinator.inkjet.isConnected, isFalse);
      expect(coordinator.inkjet.selectedPrinter, isNull);

      await tester.tap(find.text('Sim'));
      await tester.pumpAndSettle();
      expect(coordinator.runMode, equals(DemoRunMode.simulation));

      // Open Protocol Inspector Drawer and verify captured frames & clear button
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Protocol Inspector ('), findsOneWidget);

      await tester.tap(find.byTooltip('Clear logs'));
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
      expect(find.text('Thermal LAN Stream'), findsOneWidget);
      await tester.tap(find.text('TSPL WLAN'));
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 3. Sublimation RPC tab (connected + scrolled)
      final subTab = find.byKey(const Key('tab_sublimationRpc'));
      await tester.ensureVisible(subTab);
      await tester.tap(subTab);
      await tester.pumpAndSettle();
      expect(find.text('Sublimation RPC'), findsOneWidget);
      await tester.runAsync(() => coordinator.sublimation.connectDriver());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 4. Color Inkjet PJL tab (connected + all 6 DropdownButtonFormFields + scrolled)
      final inkjetTab = find.byKey(const Key('tab_colorInkjetPjl'));
      await tester.ensureVisible(inkjetTab);
      await tester.tap(inkjetTab);
      await tester.pumpAndSettle();
      expect(find.text('Color Inkjet PJL'), findsOneWidget);
      await tester.runAsync(() => coordinator.inkjet.connectDriver());
      await tester.pumpAndSettle();
      await scrollCurrentTab();

      // 5. Protocol Inspector Drawer at 360x640
      await tester.tap(find.byKey(const Key('open_protocol_inspector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TX'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
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

      final provisionBtn = find.text('Provision ESC TLV');
      await tester.ensureVisible(provisionBtn);
      await tester.tap(provisionBtn);
      await tester.pump(const Duration(milliseconds: 5));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unmount immediately while CloudWanEscProvisioner has an active commandTimeout
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
