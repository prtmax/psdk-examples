import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_print_demo/src/controllers/demo_coordinator.dart';
import 'package:cloud_print_demo/src/controllers/inkjet_controller.dart';
import 'package:cloud_print_demo/src/models/protocol_inspector.dart';
import 'package:cloud_print_demo/src/stubs/sim_esc_wan_stub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_fruit_wifi/psdk_fruit_wifi.dart';

void main() {
  group('Simulation E2E Protocol Flows', () {
    late DemoCoordinator coordinator;

    setUp(() {
      coordinator = DemoCoordinator(colorCore: const PureDartColorCoreEngine());
    });

    tearDown(() async {
      await coordinator.dispose();
    });

    test(
      'ProtocolInspectorController redacts sensitive Wi-Fi & token strings',
      () {
        coordinator.inspector.recordText(
          family: CloudPrinterFamily.thermalLanStream,
          transport: 'UDP 22368',
          direction: WireDirection.rx,
          text:
              'NET BROADCAST,WIFI NAME:LabNet,WIFI PASSWORD:top-secret-123\r\n',
          decodedSummary: 'BLUETOOTH SETSSID,LabNet,my-secret-pwd',
        );
        coordinator.inspector.recordText(
          family: CloudPrinterFamily.colorInkjetPjl,
          transport: 'TCP :9100 XSL',
          direction: WireDirection.tx,
          text: '@PJL WIFI STA CFG="LabNet","secret-inkjet"\r\n',
          decodedSummary: 'WLAN PWD "wlan-secret"',
        );

        final entries = coordinator.inspector.entries;
        expect(entries, hasLength(2));
        expect(entries[0].textPreview, isNot(contains('top-secret-123')));
        expect(entries[0].textPreview, contains('[REDACTED]'));
        expect(entries[0].decodedSummary, isNot(contains('my-secret-pwd')));
        expect(entries[1].textPreview, isNot(contains('secret-inkjet')));
        expect(entries[1].decodedSummary, isNot(contains('wlan-secret')));
      },
    );

    test(
      'ProtocolInspectorController and all 4 stubs redact JSON tokens, ESetKey/EGetKey, MQTT CONNECT, Sublimation getLocalPwd, and chunked Inkjet ACL cmd=24',
      () async {
        String hexOf(String secret) => utf8
            .encode(secret)
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(' ');

        void expectNoSecretLeak(String secret, String label) {
          final secretHex = hexOf(secret);
          for (final entry in coordinator.inspector.entries) {
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
        coordinator.inspector.recordText(
          family: CloudPrinterFamily.escWanCloud,
          transport: 'WAN HTTP',
          direction: WireDirection.rx,
          text: '{"deviceToken":"$jsonTok","token":"Bearer $bearerTok"}',
          decodedSummary: '{"deviceToken":"$jsonTok","token":"$bearerTok"}',
        );
        expectNoSecretLeak(jsonTok, 'JSON deviceToken');
        expectNoSecretLeak(bearerTok, 'JSON token');

        // 2. ESC ESetKey, EGetKey & MQTT CONNECT
        const escKey = 'EscKeySecret!4455';
        await coordinator.escWan.provisionBleWifi(
          ssid: 'CloudSecretLab',
          password: 'EscWifiPass!9900',
          key: escKey,
        );
        await coordinator.escWan.inspectEscDevice();
        await coordinator.escWan.connectWan();
        expectNoSecretLeak(escKey, 'ESC ESetKey/EGetKey');
        expectNoSecretLeak('EscWifiPass!9900', 'ESC ESetWifi');
        expectNoSecretLeak(
          coordinator.escWan.simBackend.currentToken,
          'MQTT CONNECT token',
        );

        // 3. Sublimation BLE Mesh getLocalWifiPassword
        const subPwd = 'SubLocalSecret!321';
        coordinator.sublimation.simBleDevice.localPassword = subPwd;
        final meshGetPwd = SublimationBleMeshCodec.buildGetLocalWifiPassword();
        await coordinator.sublimation.simBleDevice.write(meshGetPwd);
        await Future<void>.delayed(Duration.zero);
        expectNoSecretLeak(subPwd, 'Sublimation getLocalWifiPassword');

        // 4. Inkjet BLE ACL cmd=24 sent in chunks < 178B (100B + 87B)
        const aclPwd = 'InkAclSecret!654';
        final fullAcl = InkjetAclCodec.encodeWifiConfigFrame(
          ssid: 'InkLab-5G',
          password: aclPwd,
        );
        expect(fullAcl.length, equals(187));
        await coordinator.inkjet.simBleDevice.write(
          Uint8List.sublistView(fullAcl, 0, 100),
          sendDone: false,
        );
        await coordinator.inkjet.simBleDevice.write(
          Uint8List.sublistView(fullAcl, 100),
          sendDone: true,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          coordinator.inkjet.simBleDevice.lastProvisionedSsid,
          equals('InkLab-5G'),
        );
        expect(
          coordinator.inkjet.simBleDevice.lastProvisionedPassword,
          equals(aclPwd),
        );
        expectNoSecretLeak(aclPwd, 'Chunked Inkjet ACL cmd=24');
      },
    );

    test(
      'escWanCloud: TLV LE16 provisioning, ESC info/reset, WAN OSS/MQTT job, fault, stop_print, and >=3 poll failures -> offline',
      () async {
        final esc = coordinator.escWan;

        // Exercise >255B payload to validate ESetWifi LE16 length fix
        final longPassword = 'p' * 270;
        await esc.provisionBleWifi(
          ssid: 'CloudOffice-5G',
          password: longPassword,
          hostsText: 'cprint-api.iprtapp.com:30501|backup.iprtapp.com:30501',
          key: 'wan-key-2026',
        );
        expect(esc.lastProvisionResult?.success, isTrue);
        expect(esc.simDevice.lastSetWifiPayloadLen, greaterThan(255));

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
        expect(esc.simBackend.ossUploadCount, equals(1));
        expect(esc.simBackend.lastUploadedFileName, equals('demo_receipt.prn'));

        // Fault injection (6001 Lack Paper -> 6006 Cover Open -> 0 Ready)
        esc.setSimulatedFaultCode(6001);
        await esc.queryWanStatus();
        expect(esc.wanSnapshot?.issues.first.rawCode, equals(6001));

        esc.setSimulatedFaultCode(6006);
        await esc.queryWanStatus();
        expect(esc.wanSnapshot?.issues.first.rawCode, equals(6006));

        esc.setSimulatedFaultCode(0);

        // Remote stop_print event -> cancelled
        esc.setSimulatedJobOutcome(SimCloudJobOutcome.stopPrintEvent);
        await esc.submitWanPrintJob(jobName: 'cancelled_job.prn');
        expect(
          esc.lastPrintResult?.finalStage,
          equals(CloudJobStage.cancelled),
        );

        // >=3 HTTP poll failures -> CloudPrinterState.offline
        await esc.simulateThreePollFailures();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(esc.wanSnapshot?.state, equals(CloudPrinterState.offline));

        // Reset network info via ESC
        await esc.resetNetworkInfo();
        expect(esc.lastResetOk, isTrue);
        expect(esc.lastStaResult?.state, equals(EscWifiLinkState.disconnected));
        expect(
          coordinator.inspector.filtered(
            family: CloudPrinterFamily.escWanCloud,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'thermalLanStream: Bluetooth AT & TSPL WLAN dual dialects, UDP 22368 discovery redaction, TCP :9100 stream & cancel',
      () async {
        final thermal = coordinator.thermalLan;

        await thermal.runBluetoothAtProvisioning(
          ssid: 'ThermalLab',
          password: 'at-secret-password',
        );
        expect(thermal.lastAtSsid, equals('ThermalLab'));
        expect(
          thermal.lastAtLinkState,
          equals(BluetoothWifiLinkState.connected),
        );

        await thermal.runTsplWlanProvisioning(
          ssid: 'ThermalLab-Static',
          password: 'wlan-secret-password',
          dhcp: false,
          staticIp: '192.168.1.80',
        );
        expect(thermal.lastTsplDiagSummary, contains('192.168.1.80'));

        await thermal.discoverLanPrinters();
        expect(thermal.discoveredPrinters, hasLength(1));
        final discovered = thermal.discoveredPrinters.first;
        expect(discovered.host, equals('192.168.1.80'));
        expect(discovered.metadata.containsKey('wifiPassword'), isFalse);
        final thermalLogs = coordinator.inspector.filtered(
          family: CloudPrinterFamily.thermalLanStream,
        );
        expect(
          thermalLogs.any((e) => (e.textPreview ?? '').contains('[REDACTED]')),
          isTrue,
        );
        expect(
          thermalLogs.any(
            (e) => (e.textPreview ?? '').contains('wlan-secret-password'),
          ),
          isFalse,
        );

        await thermal.connectTcpPrinter(discovered);
        expect(thermal.isTcpConnected, isTrue);

        await thermal.streamTsplPrintJob(text: 'Thermal E2E Test');
        expect(thermal.printProgress?.stage, equals(CloudJobStage.completed));
        expect(thermal.simLanBackend.totalTcpBytesReceived, greaterThan(0));

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
        expect(thermal.lastStreamResult, contains('cancelled'));

        await thermal.resetTsplWlanDefaults();
        expect(thermal.lastTsplDiagSummary, equals('OK'));
        expect(
          coordinator.inspector.filtered(
            family: CloudPrinterFamily.thermalLanStream,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'sublimationRpc: registry, Mode A AT & Mode B Mesh STA/AP, UDP 22368/1901, dashboard/autoShutDown, mechanical actions, 1B 44 + cache > 0 flow',
      () async {
        expect(
          coordinator.registry.supportsFamily(
            CloudPrinterFamily.sublimationRpc,
          ),
          isTrue,
        );
        final sub = coordinator.sublimation;

        // Mode A: AT Text
        await sub.provisionWifi(
          ssid: 'SubAT-WiFi',
          password: 'at-password',
          protocol: WifiProvisionProtocol.bluetoothAtText,
        );
        expect(sub.lastProvisionResult?.success, isTrue);

        // Mode B: Binary Mesh STA & SoftAP
        await sub.provisionWifi(
          ssid: 'SubMesh-WiFi',
          password: 'mesh-password',
          protocol: WifiProvisionProtocol.sublimationBleBinaryMesh,
          targetMode: WifiTargetMode.station,
        );
        expect(sub.lastProvisionResult?.success, isTrue);
        expect(sub.lastProvisionResult?.assignedIp, equals('192.168.1.88'));

        await sub.provisionWifi(
          ssid: 'D300_SoftAP',
          password: 'ap-password',
          protocol: WifiProvisionProtocol.sublimationBleBinaryMesh,
          targetMode: WifiTargetMode.softAp,
        );
        expect(sub.lastProvisionResult?.success, isTrue);
        expect(sub.lastProvisionResult?.assignedIp, equals('192.168.4.1'));

        // Dual discovery (UDP 22368 + 1901) & UDP 1901 command
        await sub.discoverPrinters();
        expect(sub.discoveredPrinters, isNotEmpty);
        await sub.setUdp1901Status(3);
        expect(sub.lastUdp1901Status, equals(3));
        await sub.queryUdp1901Status();
        expect(sub.lastUdp1901Status, equals(3));

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
          sub.simTcpDevice.capturedPlanes.any((p) => p.contains('Yellow')),
          isTrue,
        );
        expect(
          sub.simTcpDevice.capturedPlanes.any((p) => p.contains('OverCort')),
          isTrue,
        );
        expect(
          coordinator.inspector.filtered(
            family: CloudPrinterFamily.sublimationRpc,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'colorInkjetPjl: explicit registry, ACL cmd=24, mDNS/SoftAP, XSL maintenance/wet/push, preflight low-ink & mono fallback & door-open block, XPL JBIG-1 & cancel',
      () async {
        expect(
          coordinator.registry.supportsFamily(
            CloudPrinterFamily.colorInkjetPjl,
          ),
          isTrue,
        );
        final inkjet = coordinator.inkjet;

        // ACL cmd=24 success + reject
        await inkjet.provisionBleAcl(
          ssid: 'InkjetOffice',
          password: 'acl-password',
        );
        expect(inkjet.lastProvisionResult?.success, isTrue);

        await inkjet.provisionBleAcl(
          ssid: 'InkjetOffice',
          password: 'bad-password',
          rejectInSim: true,
        );
        expect(inkjet.lastProvisionResult?.success, isFalse);

        // mDNS + SoftAP discovery (with password redaction)
        await inkjet.discoverPrinters();
        expect(inkjet.discoveredPrinters, hasLength(2));
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
          inkjet.simTcpDevice.lastWetHours,
          equals(InkjetWetScheduleHours.fourHours),
        );
        await inkjet.printBuiltInPage(InkjetBuiltInPage.demo);
        expect(
          inkjet.simTcpDevice.lastBuiltInPage,
          equals(InkjetBuiltInPage.demo),
        );

        // Preflight cases:
        // 1) Yellow Low (0x39) -> blocked unless continueOnLowSupply: true
        await inkjet.applyFaultPreset(InkjetSimFaultPreset.yellowLow);
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
        await inkjet.applyFaultPreset(InkjetSimFaultPreset.cyanEmpty);
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
        await inkjet.applyFaultPreset(InkjetSimFaultPreset.frontDoorOpen);
        final doorBlocked = await inkjet.runPreflightCheck();
        expect(doorBlocked?.outcome, equals(InkjetPreflightOutcome.blocked));

        // 4) Reset to Ready and print multi-page XPL N-up 2-up custom paper JBIG-1 stream
        inkjet.fallbackToMonoWhenColorEmpty = false;
        await inkjet.applyFaultPreset(InkjetSimFaultPreset.ready);
        inkjet.selectedPaperSize = CloudPaperSize.custom;
        inkjet.customWidthMm = 140;
        inkjet.customHeightMm = 200;
        inkjet.borderless = true;
        inkjet.nupLayout = CloudNupLayout.twoUp;
        inkjet.selectedResolution = InkjetResolution.dpi300x300;
        inkjet.pageCount = 2;

        final printRes = await inkjet.printXplDocument();
        expect(printRes?.success, isTrue);
        expect(inkjet.simTcpDevice.capturedXplJobs, equals(1));
        expect(inkjet.simTcpDevice.capturedXplBands, greaterThan(0));

        // Mid-job cancellation via CloudCancelToken
        final cancelToken = CloudCancelToken();
        final cancelDriver = InkjetPrinterDriver(
          colorCore: coordinator.colorCore,
          runPreflightOnPrint: false,
          chunkSize: 64,
        );
        final slowTcp = _CancellingDeviceWrapper(
          coordinator.inkjet.simTcpDevice,
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

        // Regression: subsequent XSL queryFullStatus() on the same simTcpDevice must succeed
        await inkjet.queryFullStatus();
        expect(inkjet.statusMessage, isNot(startsWith('Error:')));
        expect(inkjet.lastQueryResult?.inkboxStatus?.cyan?.percent, equals(85));

        // Confirm inspector recorded frames for colorInkjetPjl
        expect(
          coordinator.inspector.filtered(
            family: CloudPrinterFamily.colorInkjetPjl,
          ),
          isNotEmpty,
        );
      },
    );
  });
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
