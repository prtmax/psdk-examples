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
      expect(find.text('Scan BLE'), findsOneWidget);

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
}
