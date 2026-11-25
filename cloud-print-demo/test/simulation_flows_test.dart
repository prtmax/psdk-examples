import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_print_demo/src/controllers/demo_coordinator.dart';
import 'package:cloud_print_demo/src/controllers/esc_wan_controller.dart';
import 'package:cloud_print_demo/src/controllers/inkjet_controller.dart';
import 'package:cloud_print_demo/src/controllers/lan_setup_controller.dart';
import 'package:cloud_print_demo/src/controllers/real_transport_helper.dart';
import 'package:cloud_print_demo/src/controllers/sublimation_controller.dart';
import 'package:cloud_print_demo/src/controllers/thermal_lan_controller.dart';
import 'package:cloud_print_demo/src/models/demo_feedback.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';
import 'package:cloud_print_demo/src/protocol_registry.dart';
import 'package:cloud_print_demo/src/utils/local_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_network/psdk_network.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import 'fakes/sim_esc_wan_stub.dart';
import 'fakes/sim_inkjet_stub.dart';
import 'fakes/sim_lan_ble_device.dart';
import 'fakes/sim_sublimation_stub.dart';
import 'fakes/sim_thermal_lan_stub.dart';

class _FakePrinterWifiSession extends PrinterWifiSession {
  int connectCalls = 0;
  int disconnectCalls = 0;
  String? activeSsid;
  String? lastPassword;

  @override
  Future<PrinterWifiConnectionInfo> connectToPrinterWifi({
    required String ssid,
    required String password,
    Duration timeout = const Duration(seconds: 35),
  }) async {
    connectCalls++;
    activeSsid = ssid;
    lastPassword = password;
    return PrinterWifiConnectionInfo(
      ssid: ssid,
      interfaceName: 'wlan0-ap',
      address: '192.168.4.2',
      prefixLength: 24,
      gateway: '192.168.4.1',
    );
  }

  @override
  Future<void> disconnectPrinterWifi() async {
    disconnectCalls++;
    activeSsid = null;
  }

  @override
  PrinterWifiConnectionInfo? get current {
    final ssid = activeSsid;
    if (ssid == null) return null;
    return PrinterWifiConnectionInfo(
      ssid: ssid,
      interfaceName: 'wlan0-ap',
      address: '192.168.4.2',
      prefixLength: 24,
      gateway: '192.168.4.1',
    );
  }

  @override
  bool get isConnected => activeSsid != null;

  @override
  Future<PrinterWifiConnectionInfo?> refreshInfo() async => current;
}

class _FlowTestRig {
  _FlowTestRig({
    LocalImagePickerService? localImagePicker,
    bool clearCacheAwaitAck = false,
  }) : colorCore = const PureDartColorCoreEngine(),
       registry = CloudPrinterRegistry(),
       printerWifiSession = _FakePrinterWifiSession() {
    late final DemoCoordinator c;
    final inspector = ProtocolInspectorController();
    final feedback = DemoFeedbackCenter();
    final helper = RealTransportHelper(inspector);

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
            manualHostProberOverride: (host, iface) async =>
                DiscoveredCloudPrinter(
                  id: host,
                  displayName: 'SubSim-D300Kp',
                  family: CloudPrinterFamily.sublimationRpc,
                  host: host,
                  port: 9100,
                  model: 'SubSim-D300Kp',
                  networkInterface: iface,
                ),
            directDeviceOverride: () => subTcp,
            useAndroidDiscoveryHooks: false,
            statusPollInterval: const Duration(milliseconds: 20),
            postProvisionDiscoveryDelay: Duration.zero,
            provisionSettleDelay: const Duration(milliseconds: 15),
            provisionPollInterval: const Duration(milliseconds: 15),
            scanTimeout: const Duration(milliseconds: 120),
            scanProbeInterval: const Duration(milliseconds: 50),
            discoveryAttempts: 1,
            cardWidth: 96,
            cardHeight: 64,
            printQuality: CloudPrintQuality.fine,
            clearCacheAwaitAck: clearCacheAwaitAck,
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
            postProvisionDiscoveryDelay: Duration.zero,
            provisionSettleDelay: const Duration(milliseconds: 15),
            provisionPollInterval: const Duration(milliseconds: 15),
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

    c = DemoCoordinator(
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
    coordinator = c;
    registerDemoProtocols(
      registry,
      colorCore: colorCore,
      sublimationUdpTransport: subUdp,
      sublimationConnector: (printer, timeout) async => subTcp,
      allowInkjetLoopback: true,
      inkjetMdnsBrowser: inkjetMdns.browse,
      inkjetSoftApProbe: inkjetSoftApProbe.call,
      inkjetNetworkBinder: inkjetNetworkBinder,
      inkjetBleGattHooks: inkjetBle.buildGattHooks(),
    );
    this.inspector = coordinator.inspector;
    this.feedback = coordinator.feedback;
  }

  final ColorCoreEngine colorCore;
  final CloudPrinterRegistry registry;
  final _FakePrinterWifiSession printerWifiSession;
  late final DemoCoordinator coordinator;
  late final ProtocolInspectorController inspector;
  late final DemoFeedbackCenter feedback;
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
  group('End-to-End Real-Controller Protocol Flows (with Test Fakes)', () {
    late _FlowTestRig rig;

    setUp(() {
      rig = _FlowTestRig();
    });

    tearDown(() async {
      await rig.dispose();
    });

    test(
      'ProtocolInspectorController redacts sensitive Wi-Fi & token strings',
      () {
        rig.coordinator.inspector.recordText(
          family: CloudPrinterFamily.thermalLanStream,
          transport: 'UDP 22368',
          direction: WireDirection.rx,
          text:
              'NET BROADCAST,WIFI NAME:LabNet,WIFI PASSWORD:top-secret-123\r\n',
          decodedSummary: 'BLUETOOTH SETSSID,LabNet,my-secret-pwd',
        );
        rig.coordinator.inspector.recordText(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XSL',
          direction: WireDirection.tx,
          text: '@PJL WIFI STA CFG="LabNet","secret-inkjet"\r\n',
          decodedSummary: 'WLAN PWD "wlan-secret"',
        );

        final entries = rig.coordinator.inspector.entries;
        expect(entries, hasLength(2));
        expect(entries[0].textPreview, isNot(contains('top-secret-123')));
        expect(entries[0].textPreview, contains('[REDACTED]'));
        expect(entries[0].decodedSummary, isNot(contains('my-secret-pwd')));
        expect(entries[1].textPreview, isNot(contains('secret-inkjet')));
        expect(entries[1].decodedSummary, isNot(contains('wlan-secret')));
      },
    );

    test(
      'ProtocolInspectorController and all 4 fakes redact JSON tokens, ESetKey/EGetKey, MQTT CONNECT, shared BLE SETSSID, and chunked Inkjet ACL cmd=24',
      () async {
        String hexOf(String secret) => utf8
            .encode(secret)
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(' ');

        void expectNoSecretLeak(String secret, String label) {
          final secretHex = hexOf(secret);
          for (final entry in rig.coordinator.inspector.entries) {
            expect(
              entry.decodedSummary,
              isNot(contains(secret)),
              reason: '$label decodedSummary leaked $secret',
            );
            expect(
              entry.textPreview ?? '',
              isNot(contains(secret)),
              reason: '$label textPreview leaked $secret',
            );
            expect(
              entry.hexPreview,
              isNot(contains(secretHex)),
              reason: '$label hexPreview leaked hex of $secret',
            );
            final exported = entry.toExportLine();
            expect(
              exported,
              isNot(contains(secret)),
              reason: '$label export leaked $secret',
            );
            expect(
              exported,
              isNot(contains(secretHex)),
              reason: '$label export leaked hex of $secret',
            );
          }
        }

        // 1. JSON quoted keys in redactSecrets
        const jsonTok = 'TokSecret!9988';
        const bearerTok = 'WanSecret!7788';
        rig.coordinator.inspector.recordText(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'WAN HTTP',
          direction: WireDirection.rx,
          text: '{"deviceToken":"$jsonTok","token":"Bearer $bearerTok"}',
          decodedSummary:
              '{"deviceToken":"$jsonTok","token":"Bearer $bearerTok"}',
        );
        expectNoSecretLeak(jsonTok, 'JSON deviceToken');
        expectNoSecretLeak(bearerTok, 'JSON token');

        // 2. ESC ESetKey, EGetKey & MQTT CONNECT
        const escKey = 'EscKeySecret!4455';
        await rig.coordinator.escWan.provisionBleWifi(
          ssid: 'CloudSecretLab',
          password: 'EscWifiPass!9900',
          key: escKey,
        );
        await rig.coordinator.escWan.inspectEscDevice();
        await rig.coordinator.escWan.connectWan();
        expectNoSecretLeak(escKey, 'ESC ESetKey/EGetKey');
        expectNoSecretLeak('EscWifiPass!9900', 'ESC ESetWifi');
        expectNoSecretLeak(rig.escBackend.currentToken, 'MQTT CONNECT token');

        // 3. Shared BLUETOOTH SETSSID credentials are redacted.
        const subPwd = 'SubWifiSecret!321';
        await rig.coordinator.sublimation.setup.provisionWifi(
          ssid: 'SubLab',
          password: subPwd,
          discoverAfterProvision: false,
        );
        expectNoSecretLeak(subPwd, 'Shared BLE provisioning');

        // 4. Inkjet BLE ACL cmd=24 sent in chunks < 178B (100B + 87B)
        const aclPwd = 'InkAclSecret!654';
        final fullAcl = InkjetAclCodec.encodeWifiConfigFrame(
          ssid: 'InkLab-5G',
          password: aclPwd,
        );
        expect(fullAcl.length, equals(187));
        await rig.inkjetBle.write(
          Uint8List.sublistView(fullAcl, 0, 100),
          sendDone: false,
        );
        await rig.inkjetBle.write(
          Uint8List.sublistView(fullAcl, 100),
          sendDone: true,
        );
        await Future<void>.delayed(Duration.zero);
        expect(rig.inkjetBle.lastProvisionedSsid, equals('InkLab-5G'));
        expect(rig.inkjetBle.lastProvisionedPassword, equals(aclPwd));
        expectNoSecretLeak(aclPwd, 'Chunked Inkjet ACL cmd=24');
      },
    );

    test(
      'escWanCloud: TLV LE16 provisioning, ESC info/reset, WAN OSS/MQTT job, fault, stop_print, and >=3 poll failures -> offline',
      () async {
        final esc = rig.coordinator.escWan;

        // Exercise >255B payload to validate ESetWifi LE16 length fix
        final longPassword = 'p' * 270;
        await esc.provisionBleWifi(
          ssid: 'CloudOffice-5G',
          password: longPassword,
          hostsText: 'cprint-api.iprtapp.com:30501|backup.iprtapp.com:30501',
          key: 'wan-key-2026',
        );
        expect(esc.lastProvisionResult?.success, isTrue);
        expect(rig.escBle.lastSetWifiPayloadLen, greaterThan(255));

        await esc.inspectEscDevice();
        expect(esc.lastSerialNumber, equals('SIM-ESC-2026001'));
        expect(esc.lastMac, equals('AA:BB:CC:11:22:33'));
        expect(esc.lastFirmwareVersion, equals('1.4.2'));
        expect(esc.lastWifiName, equals('CloudOffice-5G'));
        expect(esc.lastDeviceKey, equals('wan-key-2026'));
        expect(
          esc.lastStaResult?.state,
          equals(EscWifiLinkState.cloudConnected),
        );

        await esc.connectWan();
        expect(esc.isWanConnected, isTrue);
        expect(esc.wanSnapshot?.state, equals(CloudPrinterState.ready));

        // Submit print job via OSS multipart + REST + MQTT v5
        await esc.submitWanPrintJob(jobName: 'demo_receipt.prn');
        expect(esc.lastPrintResult?.success, isTrue);
        expect(rig.escBackend.ossUploadCount, equals(1));
        expect(rig.escBackend.lastUploadedFileName, equals('demo_receipt.prn'));

        // Fault injection (6001 Lack Paper -> 6006 Cover Open -> 0 Ready)
        rig.escBackend.injectFaultCode(6001);
        await esc.queryWanStatus();
        expect(esc.wanSnapshot?.issues.first.rawCode, equals(6001));

        rig.escBackend.injectFaultCode(6006);
        await esc.queryWanStatus();
        expect(esc.wanSnapshot?.issues.first.rawCode, equals(6006));

        rig.escBackend.injectFaultCode(0);

        // Remote stop_print event -> cancelled
        rig.escBackend.nextJobOutcome = SimCloudJobOutcome.stopPrintEvent;
        await esc.submitWanPrintJob(jobName: 'cancelled_job.prn');
        expect(
          esc.lastPrintResult?.finalStage,
          equals(CloudJobStage.cancelled),
        );

        // >=3 HTTP poll failures -> CloudPrinterState.offline
        rig.escBackend.simulateHttpPollFailure = true;
        try {
          for (var i = 0; i < 3; i++) {
            await esc.debugStatusMonitor!.pollOnce(
              timeout: const Duration(seconds: 2),
            );
          }
        } finally {
          rig.escBackend.simulateHttpPollFailure = false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(esc.wanSnapshot?.state, equals(CloudPrinterState.offline));

        // Reset network info via ESC
        await esc.resetNetworkInfo();
        expect(esc.lastResetOk, isTrue);
        expect(esc.lastStaResult?.state, equals(EscWifiLinkState.disconnected));
        expect(
          rig.coordinator.inspector.filtered(
            family: CloudPrinterFamily.escWanCloud,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'thermalLanStream: shared Bluetooth Wi-Fi provisioning, UDP 22368 discovery redaction, TCP :9100 stream & cancel',
      () async {
        final thermal = rig.coordinator.thermalLan;

        await thermal.setup.provisionWifi(
          ssid: 'ThermalLab',
          password: 'at-secret-password',
        );
        expect(thermal.setup.lastSsid, equals('ThermalLab'));
        expect(thermal.setup.lastProvisionResult?.success, isTrue);

        expect(thermal.discoveredPrinters, hasLength(1));
        final discovered = thermal.discoveredPrinters.first;
        expect(discovered.host, equals('192.168.1.77'));
        expect(discovered.metadata.containsKey('wifiPassword'), isFalse);
        final thermalLogs = rig.coordinator.inspector.filtered(
          family: CloudPrinterFamily.thermalLanStream,
        );
        expect(
          thermalLogs.any((e) => (e.textPreview ?? '').contains('[REDACTED]')),
          isTrue,
        );
        expect(
          thermalLogs.any(
            (e) => (e.textPreview ?? '').contains('at-secret-password'),
          ),
          isFalse,
        );

        await thermal.connectTcpPrinter(discovered);
        expect(thermal.isTcpConnected, isTrue);

        await thermal.streamTsplPrintJob(text: 'Thermal E2E Test');
        expect(thermal.printProgress?.stage, equals(CloudJobStage.completed));
        expect(rig.thermalBackend.totalTcpBytesReceived, greaterThan(0));

        // Exercise ThermalLanController.cancelTsplPrintJob mid-stream
        var cancelledTriggered = false;
        void onThermalChange() {
          if (!cancelledTriggered &&
              thermal.busy &&
              thermal.printProgress?.stage == CloudJobStage.sending) {
            cancelledTriggered = true;
            thermal.cancelTsplPrintJob();
          }
        }

        thermal.addListener(onThermalChange);
        try {
          await thermal.streamTsplPrintJob(text: 'X' * 2048);
        } finally {
          thermal.removeListener(onThermalChange);
        }
        expect(cancelledTriggered, isTrue);
        expect(thermal.lastStreamResult, contains('已取消'));

        expect(
          rig.coordinator.inspector.filtered(
            family: CloudPrinterFamily.thermalLanStream,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'sublimationRpc: registry, shared Bluetooth Wi-Fi provisioning, UDP 22368, dashboard/autoShutDown, mechanical actions, 1B 44 + cache > 0 flow',
      () async {
        expect(
          rig.coordinator.registry.supportsFamily(
            CloudPrinterFamily.sublimationRpc,
          ),
          isTrue,
        );
        final sub = rig.coordinator.sublimation;

        // Mode A: AT Text
        await sub.setup.provisionWifi(
          ssid: 'SubAT-WiFi',
          password: 'at-password',
          discoverAfterProvision: false,
        );
        expect(sub.setup.lastProvisionResult?.success, isTrue);

        // Unified multi-protocol discovery includes both UDP 22368 and UDP 1901.
        await sub.setup.discoverPrinters();
        expect(sub.setup.discoveredPrinters, isNotEmpty);
        expect(
          rig.coordinator.inspector.entries.any(
            (entry) => entry.transport.contains('1901'),
          ),
          isTrue,
        );

        // RPC Connect, Dashboard & autoShutDownMinutes
        await sub.connectDriver();
        expect(sub.isConnected, isTrue);
        expect(sub.rawStatus?.mainStatus, equals(SublimationMainStatus.ready));
        expect(sub.consumables?.ribbonRemainingPercent, equals(88));

        await sub.updateAutoShutDownMinutes(25);
        expect(sub.printerSetting?.autoShutDownMinutes, equals(25));

        // Mechanical actions: Inject -> Move RFID -> Flip -> MoveBack -> Hold Eject -> Recycle
        await sub.runMechanicalAction('Inject', (d) => d.cardOps.injectCard());
        expect(
          sub.cardPosition?.position,
          equals(SublimationCardPosition.print),
        );

        await sub.runMechanicalAction(
          'Move RFID',
          (d) => d.cardOps.moveCard(SublimationMoveTarget.contactless),
        );
        expect(
          sub.cardPosition?.position,
          equals(SublimationCardPosition.contactless),
        );

        await sub.runMechanicalAction('Flip', (d) => d.cardOps.flipCard());
        await sub.runMechanicalAction(
          'MoveBack',
          (d) => d.cardOps.moveCardBack(),
        );
        expect(
          sub.cardPosition?.position,
          equals(SublimationCardPosition.print),
        );

        await sub.runMechanicalAction(
          'HoldEject',
          (d) => d.cardOps.ejectCard(mode: SublimationEjectMode.holdPaper),
        );
        expect(
          sub.cardPosition?.position,
          equals(SublimationCardPosition.frontClipCard),
        );

        // A held card must be removed or recycled before moving it to RFID.
        final moveSw = Stopwatch()..start();
        await sub.runMechanicalAction(
          'Move RFID after HoldEject',
          (d) => d.cardOps.moveCard(SublimationMoveTarget.contactless),
        );
        moveSw.stop();
        expect(moveSw.elapsed, lessThan(const Duration(seconds: 2)));
        expect(sub.statusMessage, contains('takePaperOut'));
        expect(
          sub.cardPosition?.position,
          SublimationCardPosition.frontClipCard,
        );

        await sub.runMechanicalAction(
          'Recycle',
          (d) => d.cardOps.recycleCard(),
        );
        expect(
          sub.cardPosition?.position,
          equals(SublimationCardPosition.noCard),
        );

        await sub.runMechanicalAction(
          'SelfTest',
          (d) => d.printerOps.printSelfTestCard(),
        );
        await sub.runMechanicalAction(
          'TestCard',
          (d) => d.printerOps.printTestCard(),
        );
        await sub.runMechanicalAction(
          'ClearCache',
          (d) => d.printerOps.clearPrinterCache(),
        );
        await sub.runMechanicalAction(
          'Init',
          (d) => d.printerOps.initializePrinter(),
        );

        // 1B 44 Multi-Plane Print + cache > 0 flow control (waitingCache)
        sub.selectedColorMode = CloudColorMode.colorCmyk;
        sub.fontBeautify = true;
        sub.includeOvercoat = true;
        await sub.printTestCardJob();
        expect(sub.lastPrintResult?.success, isTrue);
        expect(
          sub.observedJobStages,
          containsAll(<CloudJobStage>[
            CloudJobStage.preflighting,
            CloudJobStage.rasterizing,
            CloudJobStage.waitingCache,
            CloudJobStage.sending,
            CloudJobStage.completed,
          ]),
        );
        expect(
          rig.subTcp.capturedPlanes.any((p) => p.contains('Yellow')),
          isTrue,
        );
        expect(
          rig.subTcp.capturedPlanes.any((p) => p.contains('OverCort')),
          isTrue,
        );
        expect(
          rig.coordinator.inspector.filtered(
            family: CloudPrinterFamily.sublimationRpc,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'SublimationController.clearPrinterCache succeeds with feedback event',
      () async {
        final ackRig = _FlowTestRig(clearCacheAwaitAck: true);
        addTearDown(ackRig.dispose);

        final sub = ackRig.coordinator.sublimation;
        await sub.connectDriver();
        expect(sub.isConnected, isTrue);

        await sub.clearPrinterCache();

        expect(sub.lastActionFailed, isFalse);
        expect(sub.statusMessage, contains('清空缓存 已完成'));
        expect(
          ackRig.coordinator.feedback.latest?.kind,
          equals(DemoFeedbackKind.success),
        );
        expect(
          ackRig.coordinator.feedback.latest?.message,
          contains('清空缓存 已完成'),
        );
      },
    );

    test(
      'LanSetupController.probeManualHost validates IPv4 and SublimationController enforces Z11 Y/M/C/O single-sided rules',
      () async {
        final inspector = ProtocolInspectorController();
        final simUdp = SimulatedSublimationUdpTransport(inspector: inspector);
        final probedHosts = <String>[];
        final setup = LanSetupController(
          family: CloudPrinterFamily.sublimationRpc,
          inspector: inspector,
          scannerFactory: () => SublimationLanScanner(transport: simUdp),
          useAndroidDiscoveryHooks: false,
          manualHostProber: (host, iface) async {
            probedHosts.add(host);
            return DiscoveredCloudPrinter(
              id: host,
              displayName: 'Z11',
              family: CloudPrinterFamily.sublimationRpc,
              host: host,
              port: 9100,
              model: 'Z11',
            );
          },
        );
        addTearDown(() async {
          await setup.dispose();
          inspector.dispose();
        });

        await setup.probeManualHost('invalid-ip');
        expect(setup.statusMessage, contains('有效的 IPv4'));
        expect(probedHosts, isEmpty);

        await setup.probeManualHost('0.0.0.0');
        expect(setup.statusMessage, contains('有效的 IPv4'));
        expect(probedHosts, isEmpty);

        await setup.probeManualHost('192.168.200.161');
        expect(probedHosts, <String>['192.168.200.161']);
        expect(setup.discoveredPrinters, hasLength(1));
        expect(setup.selectedPrinter?.host, '192.168.200.161');
        expect(setup.statusMessage, contains('Z11'));

        // Z11 controller auto-detects Z11 model and omits K plane & dualSided
        final z11Tcp = SimulatedSublimationTcpDevice(
          inspector: inspector,
          modelName: 'Z11',
        );
        final z11Controller =
            SublimationController(
                inspector: inspector,
                registry: rig.registry,
                colorCore: rig.colorCore,
                directDeviceOverride: () => z11Tcp,
                useAndroidDiscoveryHooks: false,
                statusPollInterval: const Duration(milliseconds: 20),
                cardWidth: 96,
                cardHeight: 64,
                printQuality: CloudPrintQuality.fine,
              )
              ..selectedPrinter = DiscoveredCloudPrinter(
                id: 'z11-local',
                displayName: 'Z11',
                family: CloudPrinterFamily.sublimationRpc,
                host: '192.168.200.161',
                port: 9100,
                model: 'Z11',
              );
        addTearDown(() async {
          await z11Controller.dispose();
          await z11Tcp.disconnect();
        });

        await z11Controller.connectDriver();
        expect(z11Controller.isConnected, isTrue);
        expect(z11Controller.isZ11PhotoPrinter, isTrue);
        expect(z11Controller.printerSetting?.autoShutDownMinutes, 15);

        z11Controller.selectedColorMode = CloudColorMode.monochrome;
        await z11Controller.printTestCardJob();
        expect(z11Controller.statusMessage, contains('不支持黑白'));

        z11Controller.selectedColorMode = CloudColorMode.colorCmyk;
        z11Controller.dualSided = true;
        await z11Controller.printTestCardJob();
        expect(z11Controller.statusMessage, contains('不支持双面'));

        z11Controller.dualSided = false;
        await z11Controller.printTestCardJob();
        expect(z11Controller.lastPrintResult?.success, isTrue);
        expect(
          z11Tcp.capturedPlanes.map((p) => p.replaceAll('\x00', '')).toList(),
          equals(const <String>['Yellow', 'Magenta', 'Cyan', 'OverCort']),
        );

        // Top-level Isolate photo generator does not capture controller state.
        final photoRgba = await SublimationController.generateRealPhotoRgba(
          width: 96,
          height: 64,
        );
        expect(photoRgba.length, equals(96 * 64 * 4));

        // DemoFeedbackCenter formats protocol errors cleanly and redacts secrets.
        final formattedError = DemoFeedbackCenter.formatMessage(
          '操作失败：SublimationProtocolException(argsError, rawStatusCode: null, message: autoShutDownMinutes must be 0 or in 2..65535 minutes)\n <- trace line',
        );
        expect(
          formattedError,
          equals(
            'autoShutDownMinutes must be 0 or in 2..65535 minutes (argsError)',
          ),
        );
        final redacted = DemoFeedbackCenter.formatMessage(
          'BLUETOOTH SETSSID,AIYIN8,secret-pass-123',
        );
        expect(redacted, isNot(contains('secret-pass-123')));
        expect(redacted, contains('[REDACTED]'));
      },
    );

    test(
      'colorInkjetPjl: explicit registry, ACL cmd=24, mDNS/SoftAP, XSL maintenance/wet/push, preflight low-ink & mono fallback & door-open block, XPL JBIG-1 & cancel',
      () async {
        expect(
          rig.coordinator.registry.supportsFamily(
            CloudPrinterFamily.colorInkjetPjl,
          ),
          isTrue,
        );
        final inkjet = rig.coordinator.inkjet;

        // ACL cmd=24 success + reject
        await inkjet.provisionBleAcl(
          ssid: 'InkjetOffice',
          password: 'acl-password',
          discoverAfterProvision: false,
        );
        expect(inkjet.lastProvisionResult?.success, isTrue);

        rig.inkjetBle.rejectNextProvision = true;
        await inkjet.provisionBleAcl(
          ssid: 'InkjetOffice',
          password: 'bad-password',
          discoverAfterProvision: false,
        );
        expect(inkjet.lastProvisionResult?.success, isFalse);

        // mDNS + SoftAP discovery (with password redaction)
        await inkjet.discoverPrinters();
        expect(inkjet.discoveredPrinters, hasLength(1));
        expect(inkjet.discoveredPrinters.single.port, equals(9100));
        expect(
          inkjet.discoveredPrinters.single.discoveredVia,
          containsAll(<LanDiscoveryProtocol>{
            LanDiscoveryProtocol.mdnsPrinterTcp,
            LanDiscoveryProtocol.softApProbe,
          }),
        );
        expect(
          inkjet.discoveredPrinters.first.metadata['wifi_pwd'],
          equals('[REDACTED]'),
        );

        // XSL connect, query, active push & maintenance
        await inkjet.connectDriver();
        expect(inkjet.isConnected, isTrue);
        expect(inkjet.lastQueryResult?.inkboxStatus?.cyan?.percent, equals(85));

        await inkjet.toggleActivePush(true);
        expect(inkjet.activePushEnabled, isTrue);

        await inkjet.executeMaintenance(InkjetMaintenanceAction.nozzleClean);
        await inkjet.executeMaintenance(
          InkjetMaintenanceAction.nozzleDeepClean,
        );
        await inkjet.executeMaintenance(InkjetMaintenanceAction.nozzleTest);
        await inkjet.executeMaintenance(InkjetMaintenanceAction.nozzleAdjust);
        await inkjet.scheduleNozzleWet(InkjetWetScheduleHours.fourHours);
        expect(
          rig.inkjetTcp.lastWetHours,
          equals(InkjetWetScheduleHours.fourHours),
        );
        await inkjet.printBuiltInPage(InkjetBuiltInPage.demo);
        expect(rig.inkjetTcp.lastBuiltInPage, equals(InkjetBuiltInPage.demo));

        // Preflight cases:
        // 1) Yellow Low (0x39) -> blocked unless continueOnLowSupply: true
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
        await inkjet.queryFullStatus();
        final lowBlocked = await inkjet.runPreflightCheck();
        expect(lowBlocked?.outcome, equals(InkjetPreflightOutcome.blocked));

        inkjet.continueOnLowSupply = true;
        final lowProceed = await inkjet.runPreflightCheck();
        expect(
          lowProceed?.outcome,
          equals(InkjetPreflightOutcome.proceedWithWarning),
        );

        // 2) Cyan Empty (0x37) -> blocked unless fallbackToMonochromeWhenColorEmpty: true
        inkjet.continueOnLowSupply = false;
        rig.inkjetTcp.applyInkPreset(
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
        await inkjet.queryFullStatus();
        final emptyBlocked = await inkjet.runPreflightCheck();
        expect(emptyBlocked?.outcome, equals(InkjetPreflightOutcome.blocked));

        inkjet.fallbackToMonoWhenColorEmpty = true;
        final monoFallback = await inkjet.runPreflightCheck();
        expect(
          monoFallback?.outcome,
          equals(InkjetPreflightOutcome.proceedWithMonochromeFallback),
        );
        expect(
          monoFallback?.effectiveColorMode,
          equals(CloudColorMode.monochrome),
        );

        // 3) Front Door Open (0x34) -> always blocked
        rig.inkjetTcp.applyInkPreset(
          fault: InkjetFaultCode.openTheFrontDoor,
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
        await inkjet.queryFullStatus();
        final doorBlocked = await inkjet.runPreflightCheck();
        expect(doorBlocked?.outcome, equals(InkjetPreflightOutcome.blocked));

        // 4) Reset to Ready and print multi-page XPL N-up 2-up custom paper JBIG-1 stream
        inkjet.fallbackToMonoWhenColorEmpty = false;
        rig.inkjetTcp.applyInkPreset(
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
        await inkjet.queryFullStatus();
        inkjet.selectedPaperSize = CloudPaperSize.custom;
        inkjet.customWidthMm = 140;
        inkjet.customHeightMm = 200;
        inkjet.borderless = true;
        inkjet.nupLayout = CloudNupLayout.twoUp;
        inkjet.selectedResolution = InkjetResolution.dpi300x300;
        inkjet.pageCount = 2;

        final printRes = await inkjet.printXplDocument();
        expect(printRes?.success, isTrue);
        expect(rig.inkjetTcp.capturedXplJobs, equals(1));
        expect(rig.inkjetTcp.capturedXplBands, greaterThan(0));

        // Mid-job cancellation via CloudCancelToken
        final cancelToken = CloudCancelToken();
        final cancelDriver = InkjetPrinterDriver(
          colorCore: rig.coordinator.colorCore,
          runPreflightOnPrint: false,
          chunkSize: 64,
        );
        final slowTcp = _CancellingDeviceWrapper(
          rig.inkjetTcp,
          onSecondWrite: () => cancelToken.cancel('User aborted XPL'),
        );
        await cancelDriver.connect(device: slowTcp);
        final cancelledRes = await cancelDriver.printJob(
          CloudPrintJobRequest(
            jobId: '99',
            jobName: 'cancel_me',
            rawPayload: Uint8List(512),
          ),
          cancelToken: cancelToken,
        );
        expect(cancelledRes.finalStage, equals(CloudJobStage.cancelled));
        await cancelDriver.dispose();

        // Regression: subsequent XSL queryFullStatus() on the same inkjetTcp must succeed
        await inkjet.queryFullStatus();
        expect(inkjet.statusMessage, isNot(startsWith('操作失败：')));
        expect(inkjet.lastQueryResult?.inkboxStatus?.cyan?.percent, equals(85));

        // Confirm inspector recorded frames for colorInkjetPjl
        expect(
          rig.coordinator.inspector.filtered(
            family: CloudPrinterFamily.colorInkjetPjl,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'Z11 Sublimation & H100 Inkjet Direct AP Wi-Fi flows: manual SSID/pwd + BLE AP query + auto-connect + print + secret redaction',
      () async {
        // 1. Secret redaction covers APPASSWORD / WIFI SAP CFG / GETPASSWORD
        expect(
          ProtocolInspectorController.redactSecrets(
            'DIAGNOSTIC REPORT APPASSWORD:ap-top-secret\r\n'
            '@PJL WIFI SAP CFG="H100-AP","ap-sap-secret"\r\n'
            'BLUETOOTH GETPASSWORD:bt-secret-99\r\n',
          ),
          allOf(
            isNot(contains('ap-top-secret')),
            isNot(contains('ap-sap-secret')),
            isNot(contains('bt-secret-99')),
            contains('"H100-AP","[REDACTED]"'),
          ),
        );

        // 2. Z11 Sublimation: manual AP connect -> RPC print
        final sub = rig.coordinator.sublimation;
        await sub.connectDirectApWifi(
          ssid: 'Z11_MANUAL_AP',
          password: 'manual-ap-password',
          hostOverride: '192.168.4.1',
        );
        expect(sub.isDirectWifiConnected, isTrue);
        expect(sub.directWifiInfo?.ssid, equals('Z11_MANUAL_AP'));
        expect(sub.selectedPrinter?.host, equals('192.168.4.1'));
        expect(sub.isConnected, isTrue);
        await sub.printTestCardJob();
        expect(sub.lastPrintResult?.success, isTrue);
        await sub.disconnectDirectApWifi();
        expect(sub.isDirectWifiConnected, isFalse);
        expect(sub.isConnected, isFalse);

        // 3. Z11 Sublimation: BLE query AP credentials -> auto-connect -> print
        rig.subBle.apSsid = 'Z11_BLE_HOTSPOT';
        rig.subBle.apPassword = 'z11-ble-secret';
        await sub.queryBleAndConnectDirectAp();
        expect(sub.directWifiSsid, equals('Z11_BLE_HOTSPOT'));
        expect(sub.directWifiPassword, equals('z11-ble-secret'));
        expect(sub.isDirectWifiConnected, isTrue);
        expect(sub.isConnected, isTrue);
        await sub.disconnectDirectApWifi();

        // 4. H100 Inkjet: manual AP connect -> XPL print
        final inkjet = rig.coordinator.inkjet;
        await inkjet.connectDirectApWifi(
          ssid: 'H100_MANUAL_AP',
          password: '',
          hostOverride: '192.168.4.1',
        );
        expect(inkjet.isDirectWifiConnected, isTrue);
        expect(inkjet.directWifiInfo?.ssid, equals('H100_MANUAL_AP'));
        expect(inkjet.selectedPrinter?.host, equals('192.168.4.1'));
        expect(inkjet.isConnected, isTrue);
        final manualRes = await inkjet.printXplDocument();
        expect(manualRes?.success, isTrue);
        await inkjet.disconnectDirectApWifi();
        expect(inkjet.isDirectWifiConnected, isFalse);

        // 5. H100 Inkjet: BLE SoftAP XSL query -> auto-connect -> XPL print
        rig.inkjetBle.sapSsid = 'H100_BLE_AP';
        rig.inkjetBle.sapPassword = 'h100-ble-secret';
        await inkjet.queryBleAndConnectDirectAp();
        expect(inkjet.directWifiSsid, equals('H100_BLE_AP'));
        expect(inkjet.directWifiPassword, equals('h100-ble-secret'));
        expect(inkjet.isDirectWifiConnected, isTrue);
        expect(inkjet.isConnected, isTrue);
        final bleRes = await inkjet.printXplDocument();
        expect(bleRes?.success, isTrue);
        await inkjet.disconnectDirectApWifi();

        // Ensure inspector export contains no plaintext AP secrets.
        final exported = rig.coordinator.inspector.exportAll();
        expect(exported, isNot(contains('z11-ble-secret')));
        expect(exported, isNot(contains('h100-ble-secret')));
        expect(exported, isNot(contains('manual-ap-password')));
        expect(rig.printerWifiSession.connectCalls, equals(4));
        expect(rig.printerWifiSession.disconnectCalls, equals(4));
      },
    );

    test(
      'LocalImageProcessor & all 4 controllers pick local image and print end-to-end',
      () async {
        // 1. Alpha flatten on white
        final semiRgba = Uint8List.fromList(<int>[
          0, 0, 0, 0, // fully transparent -> white
          200, 100, 0, 128, // 50% alpha -> blended onto white
          10, 20, 30, 255, // opaque
          0, 0, 0, 255, // opaque black
        ]);
        final flat = LocalImageProcessor.flattenAlphaOnWhite(semiRgba);
        expect(flat.sublist(0, 4), equals(<int>[255, 255, 255, 255]));
        expect(flat[4], greaterThan(220));
        expect(flat[7], equals(255));
        expect(flat.sublist(8, 12), equals(<int>[10, 20, 30, 255]));

        // 2. Orientation auto-rotation & aspect-fit onto 96x64 card
        final portraitRgba = Uint8List(32 * 48 * 4)
          ..fillRange(0, 32 * 48 * 4, 40);
        for (var i = 3; i < portraitRgba.length; i += 4) {
          portraitRgba[i] = 255;
        }
        final fitted = LocalImageProcessor.fitRgbaToCanvas(
          srcRgba: portraitRgba,
          srcWidth: 32,
          srcHeight: 48,
          targetWidth: 96,
          targetHeight: 64,
          cover: false,
          autoRotateToMatchOrientation: true,
        );
        expect(fitted.length, equals(96 * 64 * 4));
        expect(fitted[0], equals(40));
        expect(fitted[3], equals(255));

        // 3. ESC raster & TSPL BITMAP payload generation
        final sampleRgba = Uint8List(40 * 30 * 4);
        for (var i = 0; i < sampleRgba.length; i += 4) {
          final isDark = ((i ~/ 4) % 7) < 3;
          final v = isDark ? 10 : 250;
          sampleRgba[i] = v;
          sampleRgba[i + 1] = v;
          sampleRgba[i + 2] = v;
          sampleRgba[i + 3] = 255;
        }
        final escPayload = LocalImageProcessor.buildEscImagePayload(
          rgbaBytes: sampleRgba,
          width: 40,
          height: 30,
        );
        final escHex = escPayload
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        expect(escHex, contains('1d7630'));

        final tsplPayload = LocalImageProcessor.buildTsplBitmapPayload(
          rgbaBytes: sampleRgba,
          width: 40,
          height: 30,
        );
        final tsplPreview = latin1.decode(tsplPayload);
        expect(tsplPreview, contains('BITMAP 0,0,5,30,0,'));
        expect(tsplPreview, endsWith('\r\nPRINT 1,1\r\n'));

        // 4. All 4 real controllers pick + print local image using test fakes
        final pickedSample = PickedLocalImage.fromRgba(
          name: 'photo_sample.png',
          width: 40,
          height: 30,
          rgbaBytes: sampleRgba,
        );
        final localRig = _FlowTestRig(
          localImagePicker: LocalImagePickerService(
            pickerOverride: () async => pickedSample,
          ),
        );
        addTearDown(localRig.dispose);

        // ESC WAN Cloud
        await localRig.coordinator.escWan.connectWan();
        expect(localRig.coordinator.escWan.isWanConnected, isTrue);
        expect(await localRig.coordinator.escWan.pickLocalImage(), isNotNull);
        await localRig.coordinator.escWan.submitLocalImageWanPrintJob();
        expect(
          localRig.coordinator.escWan.lastPrintResult?.success,
          isTrue,
          reason: 'status=${localRig.coordinator.escWan.statusMessage}',
        );
        expect(
          localRig.coordinator.escWan.lastPrintResult?.bytesTransferred,
          equals(escPayload.length),
        );

        // Thermal LAN TSPL
        await localRig.coordinator.thermalLan.setup.discoverPrinters();
        await localRig.coordinator.thermalLan.connectTcpPrinter();
        expect(localRig.coordinator.thermalLan.isTcpConnected, isTrue);
        expect(
          await localRig.coordinator.thermalLan.pickLocalImage(),
          isNotNull,
        );
        await localRig.coordinator.thermalLan.streamLocalImageTsplPrintJob();
        expect(
          localRig.coordinator.thermalLan.lastStreamResult,
          contains('${tsplPayload.length} B'),
        );
        await localRig.coordinator.thermalLan.disconnectTcpPrinter();
        expect(
          localRig.thermalBackend.capturedTcpJobs.last,
          equals(tsplPayload),
        );

        // Sublimation RPC
        await localRig.coordinator.sublimation.connectDriver();
        expect(localRig.coordinator.sublimation.isConnected, isTrue);
        expect(
          await localRig.coordinator.sublimation.pickLocalImage(),
          isNotNull,
        );
        await localRig.coordinator.sublimation.printLocalImageJob();
        expect(
          localRig.coordinator.sublimation.lastPrintResult?.success,
          isTrue,
        );
        expect(
          localRig.coordinator.sublimation.observedJobStages,
          contains(CloudJobStage.completed),
        );

        // Color Inkjet XPL
        await localRig.coordinator.inkjet.connectDriver();
        expect(localRig.coordinator.inkjet.isConnected, isTrue);
        expect(await localRig.coordinator.inkjet.pickLocalImage(), isNotNull);
        final inkResult = await localRig.coordinator.inkjet
            .printLocalImageXplDocument();
        expect(inkResult?.success, isTrue);
        expect(inkResult?.pagesPrinted, equals(1));

        // 5. ProtocolInspectorController redacts secrets in rawBytes / hexPreview too
        final guardInspector = ProtocolInspectorController();
        guardInspector.record(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'BLE',
          direction: WireDirection.rx,
          rawBytes: Uint8List.fromList(
            utf8.encode('WIFI SAP CFG="AP","RawByteSecret"\r\n'),
          ),
          decodedSummary: 'WIFI SAP CFG="AP","SummarySecret"',
        );
        final guardEntry = guardInspector.entries.single;
        expect(utf8.decode(guardEntry.rawBytes), contains('[REDACTED]'));
        expect(
          utf8.decode(guardEntry.rawBytes),
          isNot(contains('RawByteSecret')),
        );
        expect(guardEntry.toExportLine(), isNot(contains('SummarySecret')));
        guardInspector.dispose();
      },
    );

    test(
      'Sublimation, ThermalLan, and Inkjet all use unified allProtocols Wi-Fi '
      'discovery and discover both Z11 and H100 without filtering',
      () async {
        final recordedProtocolSets = <Set<LanDiscoveryProtocol>>[];

        LanPrinterScanner makeMixedScanner() => _MixedDiscoveryTestScanner(
          onScan: (options) => recordedProtocolSets.add(options.protocols),
        );

        final inspector = ProtocolInspectorController();
        final feedback = DemoFeedbackCenter();
        final sharedCache = VerifiedPrinterIpCache();
        final helper = RealTransportHelper(inspector);

        final thermal = ThermalLanController(
          inspector: inspector,
          feedback: feedback,
          ipCache: sharedCache,
          realTransportHelper: helper,
          discoveryScannerFactory: makeMixedScanner,
          useAndroidDiscoveryHooks: false,
          scanTimeout: const Duration(milliseconds: 50),
          discoveryAttempts: 1,
        );
        final sub = SublimationController(
          inspector: inspector,
          feedback: feedback,
          ipCache: sharedCache,
          registry: CloudPrinterRegistry(),
          colorCore: const PureDartColorCoreEngine(),
          discoveryScannerFactory: makeMixedScanner,
          useAndroidDiscoveryHooks: false,
          scanTimeout: const Duration(milliseconds: 50),
          discoveryAttempts: 1,
        );
        final inkjet = InkjetController(
          inspector: inspector,
          feedback: feedback,
          ipCache: sharedCache,
          registry: CloudPrinterRegistry(),
          colorCore: const PureDartColorCoreEngine(),
          discoveryScannerFactory: makeMixedScanner,
          useAndroidDiscoveryHooks: false,
          discoveryTimeout: const Duration(milliseconds: 50),
          discoveryAttempts: 1,
        );

        addTearDown(() async {
          await thermal.dispose();
          await sub.dispose();
          await inkjet.dispose();
          inspector.dispose();
          feedback.dispose();
        });

        await thermal.setup.discoverPrinters();
        await sub.setup.discoverPrinters();
        await inkjet.discoverPrinters();

        expect(recordedProtocolSets, hasLength(3));
        for (final set in recordedProtocolSets) {
          expect(set, equals(LanPrinterDiscovery.allProtocols));
        }
        for (final list in <List<DiscoveredCloudPrinter>>[
          thermal.discoveredPrinters,
          sub.setup.discoveredPrinters,
          inkjet.discoveredPrinters,
        ]) {
          expect(
            list.map((p) => p.model).toSet(),
            equals(<String?>{'Z11', 'H100'}),
          );
        }
      },
    );
  });
}

class _MixedDiscoveryTestScanner extends LanPrinterScanner {
  _MixedDiscoveryTestScanner({required this.onScan});

  final void Function(LanScanOptions options) onScan;

  @override
  Set<LanDiscoveryProtocol> get supportedProtocols =>
      LanPrinterDiscovery.allProtocols;

  @override
  Stream<DiscoveredCloudPrinter> scan(LanScanOptions options) {
    onScan(options);
    return Stream<DiscoveredCloudPrinter>.fromIterable(<DiscoveredCloudPrinter>[
      DiscoveredCloudPrinter(
        id: '192.168.1.50',
        displayName: 'Z11_001',
        discoveredVia: const <LanDiscoveryProtocol>{
          LanDiscoveryProtocol.udp22368Text,
        },
        host: '192.168.1.50',
        port: 9100,
        model: 'Z11',
        macAddress: 'AA:BB:CC:00:00:11',
      ),
      DiscoveredCloudPrinter(
        id: '192.168.1.88',
        displayName: 'H100_002',
        discoveredVia: const <LanDiscoveryProtocol>{
          LanDiscoveryProtocol.udp4201Multicast,
          LanDiscoveryProtocol.mdnsPrinterTcp,
        },
        host: '192.168.1.88',
        port: 9100,
        model: 'H100',
        serialNumber: 'H100-SN-02',
      ),
    ]);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _CancellingDeviceWrapper extends DelegatingSimDevice {
  _CancellingDeviceWrapper(super.inner, {required this.onSecondWrite});

  final void Function() onSecondWrite;
  int _writes = 0;

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {
    _writes++;
    await super.write(data, sendDone: sendDone);
    if (_writes >= 2) {
      onSecondWrite();
    }
  }
}

class DelegatingSimDevice extends InkjetConnectedDelegate {
  DelegatingSimDevice(super.inner);
}

class InkjetConnectedDelegate extends FakeInkjetConnectedDevice {
  InkjetConnectedDelegate(this.inner);
  final dynamic inner;

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) =>
      inner.write(data, sendDone: sendDone) as Future<void>;

  @override
  Stream<Uint8List> read(dynamic options) =>
      inner.read(options) as Stream<Uint8List>;
}

class FakeInkjetConnectedDevice extends ConnectedDevice<Object> {
  @override
  Object origin() => 'wrapper';

  @override
  String? deviceName() => 'wrapper';

  @override
  String? deviceMac() => '00:00:00:00:00:00';

  @override
  ConnectionState connectionState() => ConnectionState.connected;

  @override
  Future<void> disconnect() async {}

  @override
  Stream<Uint8List> read(ReadOptions? options) =>
      const Stream<Uint8List>.empty();

  @override
  Future<void> write(Uint8List data, {bool sendDone = true}) async {}
}
