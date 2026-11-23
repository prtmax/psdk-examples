import '../models/demo_labels.dart';
import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../controllers/real_transport_helper.dart';
import '../controllers/sublimation_controller.dart';
import 'common_widgets.dart';
import 'lan_setup_panel.dart';

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
  final _autoShutDownCtrl = TextEditingController(text: '15');

  @override
  void dispose() {
    _autoShutDownCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
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
            LanSetupPanel(
              controller: c.setup,
              helper: widget.realTransportHelper,
              disabled: c.busy,
              showBleNamePrefixFilter: true,
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '2. 状态、设置与机械操作',
                    trailing: StatusPill(
                      label: c.isConnected ? 'RPC 已连接' : '未连接',
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
                        label: const Text('连接 RPC'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isConnected
                            ? null
                            : c.queryDashboard,
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('查询设备状态'),
                      ),
                      if (c.isConnected)
                        OutlinedButton(
                          onPressed: c.busy ? null : c.disconnectDriver,
                          child: const Text('断开连接'),
                        ),
                    ],
                  ),
                  if (c.rawStatus != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(
                      label: '主状态',
                      value: demoLabel(c.rawStatus!.mainStatus),
                    ),
                    KeyValueRow(
                      label: '色带余量',
                      value:
                          '${c.consumables?.ribbonRemainingPercent ?? "-"}% (${c.consumables?.ribbonType.displayName ?? "-"})',
                    ),
                    KeyValueRow(
                      label: '温度',
                      value:
                          '喷头 ${c.rawStatus!.printHeadTemperatureC.toStringAsFixed(1)}°C · 机身 ${c.rawStatus!.chassisTemperatureC.toStringAsFixed(1)}°C',
                    ),
                    KeyValueRow(
                      label: '卡片位置',
                      value: demoLabel(c.cardPosition?.position),
                    ),
                    KeyValueRow(
                      label: '纸盒 / 色带盒',
                      value:
                          '${demoLabel(c.rawStatus!.paperBoxType)} / ${demoLabel(c.rawStatus!.ribbonBoxType)}',
                    ),
                    KeyValueRow(
                      label: '电量 / 缓存',
                      value:
                          '${c.rawStatus!.estimatedBatteryPercent ?? "-"}% (${c.rawStatus!.isCharging ? "充电中" : "放电中"}) · 缓存槽：${c.rawStatus!.printerCacheSlots}',
                    ),
                    KeyValueRow(
                      label: '卡片计数',
                      value:
                          '已发卡 ${c.cardCount?.cardIssuedCount ?? 0} · 总计 ${c.cardCount?.printTotalCount ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _autoShutDownCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '自动关机（0 或 2～65535 分钟）',
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
                          child: const Text('应用'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: '机械操作与维护'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '进卡',
                                  (d) => d.cardOps.injectCard(),
                                ),
                          child: const Text('进卡'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '退卡',
                                  (d) => d.cardOps.ejectCard(),
                                ),
                          child: const Text('退卡'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '夹持退卡',
                                  (d) => d.cardOps.ejectCard(
                                    mode: SublimationEjectMode.holdPaper,
                                  ),
                                ),
                          child: const Text('夹持退卡'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '翻面',
                                  (d) => d.cardOps.flipCard(),
                                ),
                          child: const Text('翻面'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '移动到 RFID 位',
                                  (d) => d.cardOps.moveCard(
                                    SublimationMoveTarget.contactless,
                                  ),
                                ),
                          child: const Text('移动到 RFID 位'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '移动回打印位',
                                  (d) => d.cardOps.moveCardBack(),
                                ),
                          child: const Text('移动回打印位'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '回收卡片',
                                  (d) => d.cardOps.recycleCard(),
                                ),
                          child: const Text('回收卡片'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '初始化',
                                  (d) => d.printerOps.initializePrinter(),
                                ),
                          child: const Text('初始化'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '清空缓存',
                                  (d) => d.printerOps.clearPrinterCache(),
                                ),
                          child: const Text('清空缓存'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '打印自检卡',
                                  (d) => d.printerOps.printSelfTestCard(),
                                ),
                          child: const Text('打印自检卡'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.runMechanicalAction(
                                  '打印测试卡',
                                  (d) => d.printerOps.printTestCard(),
                                ),
                          child: const Text('打印测试卡'),
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
                  const SectionHeader(title: '3. 1B 44 多色面卡片打印与流控'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<CloudColorMode>(
                    initialValue: c.selectedColorMode,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '色彩模式'),
                    items: const [
                      DropdownMenuItem(
                        value: CloudColorMode.colorCmyk,
                        child: Text(
                          '彩色（Y/M/C/O + K）',
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
                  DropdownButtonFormField<SublimationDitherMode>(
                    initialValue: c.selectedDitherMode,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '黑色面抖动算法'),
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
                    title: const Text('字体 / 竖线优化'),
                    value: c.fontBeautify,
                    onChanged: (v) => setState(() => c.fontBeautify = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('包含覆膜（O 面）'),
                    value: c.includeOvercoat,
                    onChanged: (v) => setState(() => c.includeOvercoat = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('双面打印（翻卡）'),
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
                        label: const Text('打印测试卡'),
                      ),
                      if (c.busy && c.isConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActivePrint,
                          icon: const Icon(Icons.cancel),
                          label: const Text('取消'),
                        ),
                    ],
                  ),
                  if (c.jobProgress != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: c.jobProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '阶段：${demoLabel(c.jobProgress!.stage)} · 已经过阶段：${c.observedJobStages.map(demoLabel).join(" -> ")}',
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
