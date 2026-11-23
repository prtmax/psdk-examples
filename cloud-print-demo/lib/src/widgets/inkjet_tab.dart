import '../models/demo_labels.dart';
import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';

import '../controllers/inkjet_controller.dart';
import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';
import 'common_widgets.dart';
import 'wifi_ssid_field.dart';

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
  late final _ssidCtrl = TextEditingController(
    text: widget.controller.mode == DemoRunMode.simulation
        ? 'InkjetLab-WiFi'
        : '',
  );
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
                  const SectionHeader(title: '1. 蓝牙 ACL 配网与局域网发现'),
                  const SizedBox(height: 10),
                  WifiSsidField(
                    controller: _ssidCtrl,
                    helper: widget.realTransportHelper,
                    mode: c.mode,
                    enabled: !c.busy,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Wi-Fi 密码'),
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
                        label: const Text('开始 ACL 配网（24）'),
                      ),
                      if (c.provisioning)
                        OutlinedButton.icon(
                          onPressed: c.cancelProvisioning,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('取消配网'),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy ? null : c.discoverPrinters,
                        icon: const Icon(Icons.wifi_find),
                        label: const Text('局域网发现（最长 15 秒）'),
                      ),
                      FilledButton.icon(
                        onPressed: c.busy ? null : c.connectDriver,
                        icon: const Icon(Icons.link),
                        label: const Text('连接 XSL/XPL'),
                      ),
                    ],
                  ),
                  if (c.discoveredPrinters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final p in c.discoveredPrinters)
                      Builder(
                        builder: (_) {
                          final isSelected =
                              c.selectedPrinter != null &&
                              isSameInkjetPrinter(p, c.selectedPrinter!);
                          return ListTile(
                            key: ValueKey('inkjet-printer-${p.host}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            selected: isSelected,
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.print_outlined,
                            ),
                            title: Text(
                              '${p.displayName} (${p.host}:${p.port})',
                            ),
                            subtitle: Text(
                              '发现方式：${p.discoveredVia.map((e) => e.name).join(", ")}',
                            ),
                            onTap: c.busy ? null : () => c.selectPrinter(p),
                          );
                        },
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
                    title: '2. 墨量、硬件故障与维护',
                    trailing: StatusPill(
                      label: c.isConnected ? 'XSL 已就绪' : '未连接',
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
                        label: const Text('查询 XSL 状态'),
                      ),
                      FilterChip(
                        label: const Text('主动状态推送'),
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
                      label: '青色（C）',
                      color: const Color(0xFF00AEEF),
                      cartridge: inkbox.cyan,
                    ),
                    _InkBar(
                      label: '品红（M）',
                      color: const Color(0xFFEC008C),
                      cartridge: inkbox.magenta,
                    ),
                    _InkBar(
                      label: '黄色（Y）',
                      color: const Color(0xFFFFC107),
                      cartridge: inkbox.yellow,
                    ),
                    _InkBar(
                      label: '黑色（K）',
                      color: const Color(0xFF222222),
                      cartridge: inkbox.black,
                    ),
                    const SizedBox(height: 6),
                    KeyValueRow(
                      label: '硬件状态',
                      value:
                          '${c.lastQueryResult?.deviceStatus?.wireToken ?? "-"} · 故障：${c.lastQueryResult?.faultCode?.descriptionZh ?? "无故障"}',
                    ),
                    KeyValueRow(
                      label: '电量 / 页数',
                      value:
                          '${c.lastQueryResult?.batteryInfo?.percent ?? "-"}% (${c.lastQueryResult?.batteryInfo?.state.wireToken ?? "-"}) · 已打印：${c.lastQueryResult?.printedTimes ?? "-"}',
                    ),
                  ],
                  if (isSim) ...[
                    const Divider(height: 20),
                    const Text(
                      '模拟故障与墨量（打印预检测试）：',
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
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '全部喷墨故障码'),
                      items: [
                        for (final fc in InkjetFaultCode.values)
                          DropdownMenuItem(
                            value: fc,
                            child: Text(
                              '0x${fc.code.toRadixString(16).padLeft(2, "0").toUpperCase()} - ${fc.descriptionZh}',
                              overflow: TextOverflow.ellipsis,
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
                  const SectionHeader(title: '喷头维护、保湿定时与内置页面'),
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
                        child: const Text('清洗喷头'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleDeepClean,
                              ),
                        child: const Text('深度清洗'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleTest,
                              ),
                        child: const Text('喷嘴测试'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.nozzleAdjust,
                              ),
                        child: const Text('校准喷头'),
                      ),
                      OutlinedButton(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : () => c.executeMaintenance(
                                InkjetMaintenanceAction.factoryRestore,
                              ),
                        child: const Text('恢复出厂设置'),
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
                          label: Text('保湿 ${w.hours} 小时'),
                          onPressed: c.busy || !c.isConnected
                              ? null
                              : () => c.scheduleNozzleWet(w),
                        ),
                      for (final page in InkjetBuiltInPage.values)
                        ActionChip(
                          label: Text('内置页：${demoLabel(page)}'),
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
                  const SectionHeader(title: '3. 打印设置、预检与 XPL JBIG-1 传输'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<CloudPrintQuality>(
                    initialValue: c.selectedQuality,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '打印质量'),
                    items: [
                      for (final q in CloudPrintQuality.values)
                        DropdownMenuItem(
                          value: q,
                          child: Text(
                            demoLabel(q),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedQuality = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<InkjetResolution>(
                    initialValue: c.selectedResolution,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '分辨率（16 种 DPI）',
                    ),
                    items: [
                      for (final r in InkjetResolution.values)
                        DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.dpiX} x ${r.dpiY} DPI (id=${r.wireId})',
                            overflow: TextOverflow.ellipsis,
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
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '色彩模式'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudColorMode.colorCmyk,
                        child: Text(
                          'CMYK（K+C+M+Y）',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: CloudColorMode.colorMixedBlack,
                        child: Text(
                          'CMY 混合黑色',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: CloudColorMode.monochrome,
                        child: Text('黑白（仅 K）', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedColorMode = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CloudPaperSize>(
                    initialValue: c.selectedPaperSize,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '纸张尺寸'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudPaperSize.a4,
                        child: Text('A4', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.a5,
                        child: Text('A5', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.b5,
                        child: Text('B5', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.letter,
                        child: Text('Letter', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo4R,
                        child: Text('4R 照片', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo5R,
                        child: Text('5R 照片', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.photo8R,
                        child: Text('8R 照片', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperSize.custom,
                        child: Text('自定义（毫米）', overflow: TextOverflow.ellipsis),
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
                              labelText: '自定义宽度（毫米）',
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
                              labelText: '自定义高度（毫米）',
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
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '合版布局'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudNupLayout.oneUp,
                        child: Text('每版 1 页', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.twoUp,
                        child: Text('每版 2 页', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.fourUp,
                        child: Text('每版 4 页', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudNupLayout.nineUp,
                        child: Text('每版 9 页', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.nupLayout = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('无边距打印'),
                    value: c.borderless,
                    onChanged: (v) => setState(() => c.borderless = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text('页数：${c.pageCount} · 份数：${c.copies}'),
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
                        label: const Text('预检并打印 XPL'),
                      ),
                      if (c.busy && c.isConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActivePrint,
                          icon: const Icon(Icons.cancel),
                          label: const Text('取消任务'),
                        ),
                    ],
                  ),
                  if (c.jobProgress != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: c.jobProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '${demoLabel(c.jobProgress!.stage)}：第 ${c.jobProgress!.currentPage}/${c.jobProgress!.totalPages} (${c.jobProgress!.bytesSent}/${c.jobProgress!.totalBytes} B)',
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
      final issueText = _preflightMessage(preflight);
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
          title: const Text('打印预检：警告 / 阻止'),
          content: Text(issueText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
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
                child: const Text('墨量低，继续打印'),
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
                child: const Text('改用黑白打印'),
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
        title: const Text('打印预检提示'),
        content: Text(
          '${_preflightMessage(preflight)}\n\n实际色彩模式：${demoLabel(preflight.effectiveColorMode)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('继续'),
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
                '$pct% (${demoLabel(stateName)})',
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

String _preflightMessage(InkjetPreflightResult result) {
  if (result.checkCode != null) return demoLabel(result.checkCode);
  if (result.faultCode != null) return result.faultCode!.descriptionZh;
  return result.issues.map((issue) => issue.message).join('\n');
}
