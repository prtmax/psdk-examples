import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../controllers/real_transport_helper.dart';
import '../controllers/sublimation_controller.dart';
import '../models/demo_mode.dart';
import 'common_widgets.dart';

class SublimationTab extends StatefulWidget {
  const SublimationTab({
    super.key,
    required this.controller,
    required this.realTransportHelper,
  });

  final SublimationController controller;
  final RealTransportHelper realTransportHelper;

  @override
  State<SublimationTab> createState() => _SublimationTabState();
}

class _SublimationTabState extends State<SublimationTab> {
  final _ssidCtrl = TextEditingController(text: 'SubOffice-WiFi');
  final _pwdCtrl = TextEditingController(text: 'sub-secret-2026');
  final _autoShutDownCtrl = TextEditingController(text: '15');

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _autoShutDownCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final isSim = c.mode == DemoRunMode.simulation;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeroBanner(
              family: CloudPrinterFamily.sublimationRpc,
              runMode: c.mode,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            if (!isSim) ...[
              RealBleConnectorRow(
                family: CloudPrinterFamily.sublimationRpc,
                helper: widget.realTransportHelper,
                connectedDevice: c.realBleDevice,
                onConnected: (dev) => setState(() => c.realBleDevice = dev),
                onDisconnected: () => setState(() => c.realBleDevice = null),
              ),
              const SizedBox(height: 12),
            ],
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title:
                        '1. Dual-Mode BLE Provisioning (0x180B AT & 0xA5 0x53 Mesh)',
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<WifiProvisionProtocol>(
                    segments: const [
                      ButtonSegment(
                        value: WifiProvisionProtocol.bluetoothAtText,
                        label: Text('AT Text'),
                      ),
                      ButtonSegment(
                        value: WifiProvisionProtocol.sublimationBleBinaryMesh,
                        label: Text('Binary Mesh'),
                      ),
                    ],
                    selected: <WifiProvisionProtocol>{
                      c.selectedProvisionProtocol,
                    },
                    onSelectionChanged: (s) =>
                        setState(() => c.selectedProvisionProtocol = s.first),
                  ),
                  const SizedBox(height: 8),
                  if (c.selectedProvisionProtocol ==
                      WifiProvisionProtocol.sublimationBleBinaryMesh)
                    SegmentedButton<WifiTargetMode>(
                      segments: const [
                        ButtonSegment(
                          value: WifiTargetMode.station,
                          label: Text('STA Router'),
                        ),
                        ButtonSegment(
                          value: WifiTargetMode.softAp,
                          label: Text('SoftAP'),
                        ),
                      ],
                      selected: <WifiTargetMode>{c.selectedTargetMode},
                      onSelectionChanged: (s) =>
                          setState(() => c.selectedTargetMode = s.first),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ssidCtrl,
                    decoration: const InputDecoration(labelText: 'Wi-Fi SSID'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Wi-Fi Password',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: c.busy
                        ? null
                        : () => c.provisionWifi(
                            ssid: _ssidCtrl.text,
                            password: _pwdCtrl.text,
                          ),
                    icon: const Icon(Icons.wifi_lock),
                    label: const Text('Provision Sublimation Wi-Fi'),
                  ),
                  if (c.lastProvisionResult != null) ...[
                    const Divider(height: 18),
                    KeyValueRow(
                      label: 'Result',
                      value: c.lastProvisionResult!.success
                          ? 'Success (${c.lastProvisionResult!.assignedIp ?? c.lastProvisionResult!.finalState.name})'
                          : 'Failed (${c.lastProvisionResult!.message ?? c.lastProvisionResult!.errorCode.name})',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: '2. UDP 22368 / 1901 Discovery & 1901 Command',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy ? null : c.discoverPrinters,
                        icon: const Icon(Icons.search),
                        label: const Text('Scan UDP 22368+1901'),
                      ),
                      FilledButton.tonal(
                        onPressed: c.busy ? null : c.queryUdp1901Status,
                        child: const Text('Get 1901 Status'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy ? null : () => c.setUdp1901Status(2),
                        child: const Text('Set 1901 Status=2'),
                      ),
                    ],
                  ),
                  if (c.lastUdp1901Status != null) ...[
                    const SizedBox(height: 8),
                    KeyValueRow(
                      label: 'UDP 1901 Status',
                      value: '${c.lastUdp1901Status}',
                    ),
                  ],
                  if (c.discoveredPrinters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final p in c.discoveredPrinters)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined),
                        title: Text('${p.displayName} (${p.host}:${p.port})'),
                        subtitle: Text(
                          'Via: ${p.discoveredVia.map((e) => e.name).join(", ")} · MAC: ${p.macAddress ?? "-"}',
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '3. Dashboard, Settings & Mechanical Actions',
                    trailing: StatusPill(
                      label: c.isConnected ? 'RPC Connected' : 'Disconnected',
                      color: c.isConnected
                          ? const Color(0xFF2E7D32)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy ? null : c.connectDriver,
                        icon: const Icon(Icons.link),
                        label: const Text('Connect RPC'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : c.queryDashboard,
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('Query Dashboard'),
                      ),
                      if (c.isConnected)
                        OutlinedButton(
                          onPressed: c.busy ? null : c.disconnectDriver,
                          child: const Text('Disconnect'),
                        ),
                    ],
                  ),
                  if (c.rawStatus != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(
                      label: 'Main Status',
                      value: c.rawStatus!.mainStatus.label,
                    ),
                    KeyValueRow(
                      label: 'Ribbon Remaining',
                      value:
                          '${c.consumables?.ribbonRemainingPercent ?? "-"}% (${c.consumables?.ribbonType.displayName ?? "-"})',
                    ),
                    KeyValueRow(
                      label: 'Temperature',
                      value:
                          'Head ${c.rawStatus!.printHeadTemperatureC.toStringAsFixed(1)}°C · Chassis ${c.rawStatus!.chassisTemperatureC.toStringAsFixed(1)}°C',
                    ),
                    KeyValueRow(
                      label: 'Card Position',
                      value: c.cardPosition?.position.label ?? '-',
                    ),
                    KeyValueRow(
                      label: 'Paper / Ribbon Box',
                      value:
                          '${c.rawStatus!.paperBoxType.label} / ${c.rawStatus!.ribbonBoxType.label}',
                    ),
                    KeyValueRow(
                      label: 'Battery / Cache',
                      value:
                          '${c.rawStatus!.estimatedBatteryPercent ?? "-"}% (${c.rawStatus!.isCharging ? "Charging" : "Discharging"}) · Cache Slots: ${c.rawStatus!.printerCacheSlots}',
                    ),
                    KeyValueRow(
                      label: 'Card Counts',
                      value:
                          'Issued ${c.cardCount?.cardIssuedCount ?? 0} · Total ${c.cardCount?.printTotalCount ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _autoShutDownCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Auto Shutdown (0 or 2..65535 min)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: c.busy || !c.isConnected
                              ? null
                              : () {
                                  final mins =
                                      int.tryParse(_autoShutDownCtrl.text) ??
                                      15;
                                  c.updateAutoShutDownMinutes(mins);
                                },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Mechanical & Maintenance'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Inject',
                                  (d) => d.cardOps.injectCard(),
                                ),
                          child: const Text('Inject'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Eject',
                                  (d) => d.cardOps.ejectCard(),
                                ),
                          child: const Text('Eject'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Hold Eject',
                                  (d) => d.cardOps.ejectCard(
                                    mode: SublimationEjectMode.holdPaper,
                                  ),
                                ),
                          child: const Text('Hold Eject'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Flip',
                                  (d) => d.cardOps.flipCard(),
                                ),
                          child: const Text('Flip'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Move RFID',
                                  (d) => d.cardOps.moveCard(
                                    SublimationMoveTarget.contactless,
                                  ),
                                ),
                          child: const Text('Move RFID'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Move Back',
                                  (d) => d.cardOps.moveCardBack(),
                                ),
                          child: const Text('Move Back'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Recycle',
                                  (d) => d.cardOps.recycleCard(),
                                ),
                          child: const Text('Recycle'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Initialize',
                                  (d) => d.printerOps.initializePrinter(),
                                ),
                          child: const Text('Init'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Clear Cache',
                                  (d) => d.printerOps.clearPrinterCache(),
                                ),
                          child: const Text('Clear Cache'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Self Test',
                                  (d) => d.printerOps.printSelfTestCard(),
                                ),
                          child: const Text('Self Test'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  'Test Card',
                                  (d) => d.printerOps.printTestCard(),
                                ),
                          child: const Text('Test Card'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: '4. 1B 44 Multi-Plane Card Print & Flow Control',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<CloudColorMode>(
                    initialValue: c.selectedColorMode,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Color Mode'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudColorMode.colorCmyk,
                        child: Text(
                          'Color (Y/M/C/O + K)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: CloudColorMode.monochrome,
                        child: Text(
                          'Monochrome (K only)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedColorMode = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SublimationDitherMode>(
                    initialValue: c.selectedDitherMode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'K-Plane Dither Mode',
                    ),
                    items: [
                      for (final m in SublimationDitherMode.values)
                        DropdownMenuItem(
                          value: m,
                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedDitherMode = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Font / Vertical Line Beautify'),
                    value: c.fontBeautify,
                    onChanged: (v) => setState(() => c.fontBeautify = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include Overcoat (O Plane)'),
                    value: c.includeOvercoat,
                    onChanged: (v) => setState(() => c.includeOvercoat = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dual-Sided Print (FlipCard)'),
                    value: c.dualSided,
                    onChanged: (v) => setState(() => c.dualSided = v),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : c.printTestCardJob,
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Print Test Card'),
                      ),
                      if (c.busy && c.isConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActivePrint,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                        ),
                    ],
                  ),
                  if (c.jobProgress != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: c.jobProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      'Stage: ${c.jobProgress!.stage.name} · Stages seen: ${c.observedJobStages.map((e) => e.name).join(" -> ")}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
