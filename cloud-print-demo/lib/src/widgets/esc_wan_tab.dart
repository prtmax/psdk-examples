import '../models/demo_labels.dart';
import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../controllers/esc_wan_controller.dart';
import '../controllers/real_transport_helper.dart';
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
  final _ssidCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeroBanner(
              family: CloudPrinterFamily.escWanCloud,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            RealBleConnectorRow(
              family: CloudPrinterFamily.escWanCloud,
              helper: widget.realTransportHelper,
              connectedDevice: c.realBleDevice,
              onConnected: (dev) => setState(() => c.realBleDevice = dev),
              onDisconnected: () => setState(() => c.realBleDevice = null),
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: '1. ESC 蓝牙 TLV 配网'),
                  const SizedBox(height: 10),
                  WifiSsidField(
                    controller: _ssidCtrl,
                    helper: widget.realTransportHelper,
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
                    obscureText: true,
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
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '设备令牌（选填）'),
                  ),
                  const SizedBox(height: 10),
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
                          onPressed: c.busy
                              ? null
                              : () => c.disconnectWan(notifyFeedback: true),
                          child: const Text('断开连接'),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  LocalImagePrintCard(
                    keyPrefix: 'esc',
                    selectedImage: c.selectedLocalImage,
                    busy: c.busy,
                    canPrint: c.isWanConnected,
                    hintText: '选择手机相册/本地图片后，自动按 58mm 热敏宽度二值光栅化并通过云端打印。',
                    printButtonLabel: '上传并打印图片',
                    onPickImage: c.pickLocalImage,
                    onClearImage: c.clearLocalImage,
                    onPrintImage: c.submitLocalImageWanPrintJob,
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
