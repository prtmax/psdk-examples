import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';

import '../controllers/inkjet_controller.dart';
import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';
import 'common_widgets.dart';

class InkjetTab extends StatefulWidget {
  const InkjetTab({
    super.key,
    required this.controller,
    required this.realTransportHelper,
  });

  final InkjetController controller;
  final RealTransportHelper realTransportHelper;

  @override
  State<InkjetTab> createState() => _InkjetTabState();
}

class _InkjetTabState extends State<InkjetTab> {
  final _ssidCtrl = TextEditingController(text: 'InkjetLab-WiFi');
  final _pwdCtrl = TextEditingController(text: 'lab-secret-2026');
  final _customWCtrl = TextEditingController(text: '140');
  final _customHCtrl = TextEditingController(text: '200');

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _customWCtrl.dispose();
    _customHCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final isSim = c.mode == DemoRunMode.simulation;
        final inkbox = c.lastQueryResult?.inkboxStatus;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeroBanner(
              family: CloudPrinterFamily.colorInkjetPjl,
              runMode: c.mode,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            if (!isSim) ...[
              RealBleConnectorRow(
                family: CloudPrinterFamily.colorInkjetPjl,
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
                    title: '1. BLE ACL Provisioning & mDNS / SoftAP Discovery',
                  ),
                  const SizedBox(height: 10),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => c.provisionBleAcl(
                                ssid: _ssidCtrl.text,
                                password: _pwdCtrl.text,
                              ),
                        icon: const Icon(Icons.bluetooth_connected),
                        label: const Text('ACL cmd=24 Provision'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy ? null : c.discoverPrinters,
                        icon: const Icon(Icons.wifi_find),
                        label: const Text('mDNS + SoftAP Scan'),
                      ),
                      FilledButton.icon(
                        onPressed: c.busy ? null : c.connectDriver,
                        icon: const Icon(Icons.link),
                        label: const Text('Connect XSL/XPL'),
                      ),
                    ],
                  ),
                  if (c.discoveredPrinters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final p in c.discoveredPrinters)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.print_outlined),
                        title: Text('${p.displayName} (${p.host}:${p.port})'),
                        subtitle: Text(
                          'Via: ${p.discoveredVia.map((e) => e.name).join(", ")}',
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
                    title: '2. XSL Inkbox, 30+ Hardware Faults & Maintenance',
                    trailing: StatusPill(
                      label: c.isConnected ? 'XSL Ready' : 'Disconnected',
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
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : c.queryFullStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Query XSL'),
                      ),
                      FilterChip(
                        label: const Text('Active Status Push'),
                        selected: c.activePushEnabled,
                        onSelected: c.busy || !c.isConnected
                            ? null
                            : c.toggleActivePush,
                      ),
                    ],
                  ),
                  if (inkbox != null) ...[
                    const SizedBox(height: 12),
                    _InkBar(
                      label: 'Cyan (C)',
                      color: const Color(0xFF00AEEF),
                      cartridge: inkbox.cyan,
                    ),
                    _InkBar(
                      label: 'Magenta (M)',
                      color: const Color(0xFFEC008C),
                      cartridge: inkbox.magenta,
                    ),
                    _InkBar(
                      label: 'Yellow (Y)',
                      color: const Color(0xFFFFC107),
                      cartridge: inkbox.yellow,
                    ),
                    _InkBar(
                      label: 'Black (K)',
                      color: const Color(0xFF222222),
                      cartridge: inkbox.black,
                    ),
                    const SizedBox(height: 6),
                    KeyValueRow(
                      label: 'Hardware Status',
                      value:
                          '${c.lastQueryResult?.deviceStatus?.wireToken ?? "-"} · Fault: ${c.lastQueryResult?.faultCode?.descriptionEn ?? "No error"}',
                    ),
                    KeyValueRow(
                      label: 'Battery / Pages',
                      value:
                          '${c.lastQueryResult?.batteryInfo?.percent ?? "-"}% (${c.lastQueryResult?.batteryInfo?.state.wireToken ?? "-"}) · Printed: ${c.lastQueryResult?.printedTimes ?? "-"}',
                    ),
                  ],
                  if (isSim) ...[
                    const Divider(height: 20),
                    const Text(
                      'Simulated Fault & Ink Presets (for Preflight Demo):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final preset in InkjetSimFaultPreset.values)
                          ChoiceChip(
                            label: Text(preset.label),
                            selected: c.selectedFaultPreset == preset,
                            onSelected: c.busy
                                ? null
                                : (_) => c.applyFaultPreset(preset),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InkjetFaultCode>(
                      initialValue: c.selectedCustomFault,
                      decoration: const InputDecoration(
                        labelText: 'All 31 InkjetFaultCode Values',
                      ),
                      items: [
                        for (final fc in InkjetFaultCode.values)
                          DropdownMenuItem(
                            value: fc,
                            child: Text(
                              '0x${fc.code.toRadixString(16).padLeft(2, "0").toUpperCase()} - ${fc.descriptionEn}',
                            ),
                          ),
                      ],
                      onChanged: c.busy
                          ? null
                          : (v) {
                              if (v != null) c.applyCustomFaultCode(v);
                            },
                    ),
                  ],
                  const Divider(height: 20),
                  const SectionHeader(
                    title: 'Nozzle Maintenance, Wet Timer & Built-in Pages',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleClean,
                              ),
                        child: const Text('Clean'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleDeepClean,
                              ),
                        child: const Text('Deep Clean'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleTest,
                              ),
                        child: const Text('Nozzle Test'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleAdjust,
                              ),
                        child: const Text('Calibrate'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.factoryRestore,
                              ),
                        child: const Text('Factory Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final w in InkjetWetScheduleHours.values)
                        ActionChip(
                          label: Text('Wet ${w.hours}h'),
                          onPressed: c.busy || !c.isConnected
                              ? null
                              : () => c.scheduleNozzleWet(w),
                        ),
                      for (final page in InkjetBuiltInPage.values)
                        ActionChip(
                          label: Text('Page: ${page.name}'),
                          onPressed: c.busy || !c.isConnected
                              ? null
                              : () => c.printBuiltInPage(page),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title:
                        '3. Print Options, Preflight Dialog & XPL JBIG-1 Stream',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<CloudPrintQuality>(
                    initialValue: c.selectedQuality,
                    decoration: const InputDecoration(labelText: 'Quality'),
                    items: [
                      for (final q in CloudPrintQuality.values)
                        DropdownMenuItem(value: q, child: Text(q.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedQuality = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<InkjetResolution>(
                    initialValue: c.selectedResolution,
                    decoration: const InputDecoration(
                      labelText: 'Resolution (16 DPI Modes)',
                    ),
                    items: [
                      for (final r in InkjetResolution.values)
                        DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.dpiX} x ${r.dpiY} DPI (id=${r.wireId})',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedResolution = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CloudColorMode>(
                    initialValue: c.selectedColorMode,
                    decoration: const InputDecoration(labelText: 'Color Mode'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudColorMode.colorCmyk,
                        child: Text('CMYK (K+C+M+Y)'),
                      ),
                      DropdownMenuItem(
                        value: CloudColorMode.colorMixedBlack,
                        child: Text('CMY Mixed Black'),
                      ),
                      DropdownMenuItem(
                        value: CloudColorMode.monochrome,
                        child: Text('Monochrome (K only)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedColorMode = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CloudPaperSize>(
                    initialValue: c.selectedPaperSize,
                    decoration: const InputDecoration(labelText: 'Paper Size'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudPaperSize.a4,
                        child: Text('A4'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.a5,
                        child: Text('A5'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.b5,
                        child: Text('B5'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.letter,
                        child: Text('Letter'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo4R,
                        child: Text('Photo 4R'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo5R,
                        child: Text('Photo 5R'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo8R,
                        child: Text('Photo 8R'),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.custom,
                        child: Text('Custom (mm)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedPaperSize = v);
                    },
                  ),
                  if (c.selectedPaperSize == CloudPaperSize.custom) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customWCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Custom Width (mm)',
                            ),
                            onChanged: (s) {
                              c.customWidthMm =
                                  double.tryParse(s) ?? c.customWidthMm;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _customHCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Custom Height (mm)',
                            ),
                            onChanged: (s) {
                              c.customHeightMm =
                                  double.tryParse(s) ?? c.customHeightMm;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CloudNupLayout>(
                    initialValue: c.nupLayout,
                    decoration: const InputDecoration(labelText: 'N-up Layout'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudNupLayout.oneUp,
                        child: Text('1-up'),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.twoUp,
                        child: Text('2-up'),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.fourUp,
                        child: Text('4-up'),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.nineUp,
                        child: Text('9-up'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.nupLayout = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Borderless Print'),
                    value: c.borderless,
                    onChanged: (v) => setState(() => c.borderless = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pages: ${c.pageCount} · Copies: ${c.copies}',
                        ),
                      ),
                      IconButton(
                        onPressed: c.pageCount > 1
                            ? () => setState(() => c.pageCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        onPressed: c.pageCount < 4
                            ? () => setState(() => c.pageCount++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => _preflightAndPrint(context),
                        icon: const Icon(Icons.print),
                        label: const Text('Preflight & Print XPL'),
                      ),
                      if (c.busy && c.isConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActivePrint,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel Job'),
                        ),
                    ],
                  ),
                  if (c.jobProgress != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: c.jobProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '${c.jobProgress!.stage.name}: page ${c.jobProgress!.currentPage}/${c.jobProgress!.totalPages} (${c.jobProgress!.bytesSent}/${c.jobProgress!.totalBytes} B)',
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

  Future<void> _preflightAndPrint(BuildContext context) async {
    final c = widget.controller;
    final preflight = await c.runPreflightCheck();
    if (!context.mounted || preflight == null) return;

    if (preflight.outcome == InkjetPreflightOutcome.proceed) {
      await c.printXplDocument();
      return;
    }

    if (preflight.outcome == InkjetPreflightOutcome.blocked) {
      final issueText = preflight.issues.map((e) => e.message).join('\n');
      final allowContinueLow =
          preflight.checkCode == InkjetPreflightCheckCode.allInkLow ||
          preflight.checkCode == InkjetPreflightCheckCode.colorInkLow ||
          preflight.checkCode == InkjetPreflightCheckCode.blackInkLow;
      final allowMonoFallback =
          (preflight.checkCode == InkjetPreflightCheckCode.allInkEmpty ||
              preflight.checkCode == InkjetPreflightCheckCode.colorInkEmpty) &&
          !(c.lastQueryResult?.inkboxStatus?.isBlackEmpty ?? false);

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preflight Warning / Blocked'),
          content: Text(issueText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            if (allowContinueLow)
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await c.printXplDocument(
                    settingsOverride: c.buildCurrentSettings(
                      continueOnLowOverride: true,
                    ),
                  );
                },
                child: const Text('Continue on Low Ink'),
              ),
            if (allowMonoFallback)
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await c.printXplDocument(
                    settingsOverride: c.buildCurrentSettings(
                      fallbackToMonoOverride: true,
                    ),
                  );
                },
                child: const Text('Fallback to Monochrome'),
              ),
          ],
        ),
      );
      return;
    }

    // proceedWithWarning or proceedWithMonochromeFallback
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preflight Notice'),
        content: Text(
          '${preflight.issues.map((e) => e.message).join("\n")}\n\nEffective color mode: ${preflight.effectiveColorMode.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await c.printXplDocument();
    }
  }
}

class _InkBar extends StatelessWidget {
  const _InkBar({
    required this.label,
    required this.color,
    required this.cartridge,
  });

  final String label;
  final Color color;
  final InkjetInkCartridgeStatus? cartridge;

  @override
  Widget build(BuildContext context) {
    final pct = (cartridge?.percent ?? 0).clamp(0, 100);
    final stateName = cartridge?.state.wireToken ?? 'UNKNOWN';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$pct% ($stateName)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
