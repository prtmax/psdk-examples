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
  final _manualIpCtrl = TextEditingController();
  final _customWCtrl = TextEditingController(text: '140');
  final _customHCtrl = TextEditingController(text: '200');
  late final _blePrefixFilter = TextEditingController(
    text: widget.controller.bleNamePrefixFilter,
  );

  @override
  void didUpdateWidget(covariant InkjetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller &&
        _blePrefixFilter.text != widget.controller.bleNamePrefixFilter) {
      _blePrefixFilter.text = widget.controller.bleNamePrefixFilter;
    }
  }

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _manualIpCtrl.dispose();
    _customWCtrl.dispose();
    _customHCtrl.dispose();
    _blePrefixFilter.dispose();
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
        final preferSnap =
            c.activePushEnabled &&
            c.lastPushAt != null &&
            c.lastSnapshot != null;
        final cyanCartridge = _resolveCartridge(
          queryCartridge: inkbox?.cyan,
          snap: c.lastSnapshot,
          kind: CloudSupplyKind.cyanInk,
          preferSnap: preferSnap,
        );
        final magentaCartridge = _resolveCartridge(
          queryCartridge: inkbox?.magenta,
          snap: c.lastSnapshot,
          kind: CloudSupplyKind.magentaInk,
          preferSnap: preferSnap,
        );
        final yellowCartridge = _resolveCartridge(
          queryCartridge: inkbox?.yellow,
          snap: c.lastSnapshot,
          kind: CloudSupplyKind.yellowInk,
          preferSnap: preferSnap,
        );
        final blackCartridge = _resolveCartridge(
          queryCartridge: inkbox?.black,
          snap: c.lastSnapshot,
          kind: CloudSupplyKind.blackInk,
          preferSnap: preferSnap,
        );
        final hasSupplies =
            cyanCartridge != null ||
            magentaCartridge != null ||
            yellowCartridge != null ||
            blackCartridge != null;
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
                namePrefixFilterController: _blePrefixFilter,
                onNamePrefixFilterChanged: (value) =>
                    c.bleNamePrefixFilter = value,
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
                  if (!isSim) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('inkjet_manual_ip_field'),
                            controller: _manualIpCtrl,
                            enabled: !c.busy,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '直连打印机 IP（可选）',
                              hintText: '如 192.168.200.214',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          key: const Key('inkjet_probe_manual_ip_btn'),
                          onPressed: c.busy
                              ? null
                              : () => c.probeManualHost(_manualIpCtrl.text),
                          icon: const Icon(Icons.radar, size: 18),
                          label: const Text('探测'),
                        ),
                      ],
                    ),
                  ],
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
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : c.queryDeviceConfig,
                        icon: const Icon(Icons.settings_ethernet),
                        label: const Text('查询网络/电源/语言'),
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
                  if (hasSupplies ||
                      c.activePushEnabled ||
                      c.lastPushAt != null) ...[
                    const SizedBox(height: 12),
                    if (hasSupplies) ...[
                      _InkBar(
                        label: '青色（C）',
                        color: const Color(0xFF00AEEF),
                        cartridge: cyanCartridge,
                      ),
                      _InkBar(
                        label: '品红（M）',
                        color: const Color(0xFFEC008C),
                        cartridge: magentaCartridge,
                      ),
                      _InkBar(
                        label: '黄色（Y）',
                        color: const Color(0xFFFFC107),
                        cartridge: yellowCartridge,
                      ),
                      _InkBar(
                        label: '黑色（K）',
                        color: const Color(0xFF222222),
                        cartridge: blackCartridge,
                      ),
                      const SizedBox(height: 6),
                    ],
                    KeyValueRow(
                      label: '硬件状态',
                      value: preferSnap
                          ? '${demoLabel(c.lastSnapshot!.state.name)} · 故障：${c.lastSnapshot!.issues.isEmpty ? "无故障" : c.lastSnapshot!.issues.map((i) => i.message).join(" / ")}'
                          : '${demoLabel(c.lastQueryResult?.deviceStatus?.wireToken)} · 故障：${c.lastQueryResult?.faultCode?.descriptionZh ?? "无故障"}',
                    ),
                    KeyValueRow(
                      label: '电量 / 页数',
                      value:
                          '${c.lastQueryResult?.batteryInfo?.percent ?? c.lastSnapshot?.batteryPercent ?? "-"}% (${demoLabel(c.lastQueryResult?.batteryInfo?.state.wireToken)}) · 已打印：${c.lastQueryResult?.printedTimes ?? "-"}',
                    ),
                    if (c.activePushEnabled || c.lastPushAt != null)
                      KeyValueRow(
                        label: '主动推送最近更新',
                        value: c.lastPushAt == null
                            ? '等待首次状态回调…'
                            : '${_formatClock(c.lastPushAt!)}（${demoLabel(c.lastSnapshot?.state.name)}）',
                      ),
                  ],
                  if (c.lastWifiSta != null ||
                      c.lastPowerConfig != null ||
                      c.lastLanguage != null) ...[
                    const SizedBox(height: 6),
                    if (c.lastWifiSta != null)
                      KeyValueRow(
                        label: 'Wi-Fi STA',
                        value:
                            '${c.lastWifiSta!.ssid ?? "-"} · ${c.lastWifiSta!.ipv4 ?? "-"} / ${c.lastWifiSta!.subnetMask ?? "-"} / ${c.lastWifiSta!.gateway ?? "-"}',
                      ),
                    if (c.lastPowerConfig != null)
                      KeyValueRow(
                        label: '电源休眠',
                        value:
                            '${c.lastPowerConfig!.powerSave == true ? "开启" : "关闭"} · ${c.lastPowerConfig!.sleepMinutes ?? "-"} 分钟',
                      ),
                    if (c.lastLanguage != null)
                      KeyValueRow(
                        label: '设备语言',
                        value: demoLabel(c.lastLanguage!.wireToken),
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
                            : () => _confirmFactoryRestore(context, c),
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
                      if (v != null) c.setQuality(v);
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CloudPaperType>(
                    initialValue: c.selectedPaperType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '纸张类型'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudPaperType.normal,
                        child: Text('普通纸', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: CloudPaperType.photo,
                        child: Text('照片纸', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => c.selectedPaperType = v);
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

  Future<void> _confirmFactoryRestore(
    BuildContext context,
    InkjetController c,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复出厂设置？'),
        content: const Text('此操作可能清除打印机 Wi-Fi 配置并恢复出厂参数。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await c.executeMaintenance(InkjetMaintenanceAction.factoryRestore);
    }
  }
}

InkjetInkCartridgeStatus? _resolveCartridge({
  required InkjetInkCartridgeStatus? queryCartridge,
  required CloudStatusSnapshot? snap,
  required CloudSupplyKind kind,
  required bool preferSnap,
}) {
  if (preferSnap && snap != null) {
    for (final s in snap.supplies) {
      if (s.kind == kind) {
        final state = switch (s.state) {
          CloudSupplyState.normal => InkjetInkState.normal,
          CloudSupplyState.low => InkjetInkState.low,
          CloudSupplyState.empty => InkjetInkState.zero,
          _ => InkjetInkState.error,
        };
        return InkjetInkCartridgeStatus(
          kind: kind,
          state: state,
          percent: s.remainingPercent ?? 0,
        );
      }
    }
  }
  return queryCartridge;
}

String _formatClock(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
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
