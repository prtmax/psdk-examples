import '../models/demo_labels.dart';
import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../controllers/esc_wan_controller.dart';
import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';
import '../stubs/sim_esc_wan_stub.dart';
import 'common_widgets.dart';
import 'wifi_ssid_field.dart';

class EscWanTab extends StatefulWidget {
  const EscWanTab({
    super.key,
    required this.controller,
    required this.realTransportHelper,
  });

  final EscWanController controller;
  final RealTransportHelper realTransportHelper;

  @override
  State<EscWanTab> createState() => _EscWanTabState();
}

class _EscWanTabState extends State<EscWanTab> {
  late final _ssidCtrl = TextEditingController(
    text: widget.controller.mode == DemoRunMode.simulation
        ? 'DemoOfficeWiFi'
        : '',
  );
  final _pwdCtrl = TextEditingController(text: 'office-pass-2026');
  final _hostsCtrl = TextEditingController(
    text: 'cprint-api.iprtapp.com:30501',
  );
  final _keyCtrl = TextEditingController(text: 'demo-device-key');
  final _apiUrlCtrl = TextEditingController(
    text: 'https://cprint-api.iprtapp.com',
  );
  final _mqttHostCtrl = TextEditingController(text: 'mqtt.iprtapp.com');
  final _snCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _hostsCtrl.dispose();
    _keyCtrl.dispose();
    _apiUrlCtrl.dispose();
    _mqttHostCtrl.dispose();
    _snCtrl.dispose();
    _tokenCtrl.dispose();
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
              family: CloudPrinterFamily.escWanCloud,
              runMode: c.mode,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            if (!isSim) ...[
              RealBleConnectorRow(
                family: CloudPrinterFamily.escWanCloud,
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
                  const SectionHeader(title: '1. ESC 蓝牙 TLV 配网'),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hostsCtrl,
                    decoration: const InputDecoration(
                      labelText: '云端地址（ESetHost）',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyCtrl,
                    decoration: const InputDecoration(
                      labelText: '设备密钥（ESetKey）',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => c.provisionBleWifi(
                                ssid: _ssidCtrl.text,
                                password: _pwdCtrl.text,
                                hostsText: _hostsCtrl.text,
                                key: _keyCtrl.text,
                              ),
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('开始 TLV 配网'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy ? null : c.inspectEscDevice,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('查询设备信息'),
                      ),
                      OutlinedButton.icon(
                        onPressed: c.busy ? null : c.resetNetworkInfo,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('重置网络信息'),
                      ),
                    ],
                  ),
                  if (c.lastSerialNumber != null ||
                      c.lastStaResult != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(label: '序列号', value: c.lastSerialNumber ?? '-'),
                    KeyValueRow(label: 'MAC 地址', value: c.lastMac ?? '-'),
                    KeyValueRow(
                      label: '固件版本',
                      value: c.lastFirmwareVersion ?? '-',
                    ),
                    KeyValueRow(
                      label: 'Wi-Fi 名称',
                      value: c.lastWifiName ?? '-',
                    ),
                    KeyValueRow(
                      label: '路由器连接状态',
                      value: demoLabel(c.lastStaResult?.state),
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
                    title: '2. 云端打印',
                    trailing: StatusPill(
                      label: c.isWanConnected ? '已连接' : '未连接',
                      color: c.isWanConnected
                          ? const Color(0xFF2E7D32)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isSim) ...[
                    TextField(
                      controller: _apiUrlCtrl,
                      decoration: const InputDecoration(labelText: '云端 API 地址'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mqttHostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'MQTT v5 TLS 地址',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _snCtrl,
                      decoration: const InputDecoration(labelText: '打印机序列号'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(labelText: '设备令牌（选填）'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => c.connectWan(
                                apiBaseUrl: _apiUrlCtrl.text,
                                mqttHost: _mqttHostCtrl.text,
                                serialNumber: _snCtrl.text,
                                deviceToken: _tokenCtrl.text,
                              ),
                        icon: const Icon(Icons.cloud_done_outlined),
                        label: const Text('连接云端'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isWanConnected
                            ? null
                            : c.queryWanStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('查询状态'),
                      ),
                      FilledButton.icon(
                        onPressed: c.busy || !c.isWanConnected
                            ? null
                            : c.submitWanPrintJob,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('上传并打印 .prn'),
                      ),
                      if (c.busy && c.isWanConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActiveWanJob,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('取消任务'),
                        ),
                      if (c.isWanConnected)
                        OutlinedButton(
                          onPressed: c.busy ? null : c.disconnectWan,
                          child: const Text('断开连接'),
                        ),
                    ],
                  ),
                  if (c.wanSnapshot != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(
                      label: '云端状态',
                      value: demoLabel(c.wanSnapshot!.state),
                    ),
                    KeyValueRow(
                      label: '故障信息',
                      value: c.wanSnapshot!.issues.isEmpty
                          ? '无'
                          : c.wanSnapshot!.issues
                                .map((e) => '${e.code}: ${e.message}')
                                .join('; '),
                    ),
                  ],
                  if (c.jobProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: c.jobProgress!.stage == CloudJobStage.completed
                          ? 1.0
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '任务阶段：${demoLabel(c.jobProgress!.stage)} — ${c.jobProgress!.message ?? ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isSim) ...[
                    const Divider(height: 20),
                    const SectionHeader(title: '模拟故障与异常处理'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: c.selectedFaultCode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '模拟云端故障码'),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            '0 - 正常',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6001,
                          child: Text(
                            '6001 - 缺纸',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6003,
                          child: Text(
                            '6003 - 过热',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6004,
                          child: Text(
                            '6004 - 电量低',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6006,
                          child: Text(
                            '6006 - 上盖打开',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6013,
                          child: Text(
                            '6013 - 纸张异常',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setSimulatedFaultCode(v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SimCloudJobOutcome>(
                      initialValue: c.selectedJobOutcome,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '下次云端任务结果'),
                      items: const [
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.success,
                          child: Text(
                            '成功（确认 → 打印 → 完成）',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.failWithFault,
                          child: Text(
                            '远程失败（故障码）',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.stopPrintEvent,
                          child: Text(
                            '远程停止（stop_print）',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setSimulatedJobOutcome(v);
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: c.busy || !c.isWanConnected
                          ? null
                          : c.simulateThreePollFailures,
                      icon: const Icon(Icons.cloud_off_outlined),
                      label: const Text('模拟连续 3 次轮询失败 → 离线'),
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
