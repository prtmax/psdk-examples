import 'package:flutter/material.dart';

import '../controllers/lan_setup_controller.dart';
import '../controllers/real_transport_helper.dart';
import 'common_widgets.dart';
import 'wifi_ssid_field.dart';

/// 两种 LAN 打印协议使用相同的配网表单、蓝牙入口和设备选择列表。
class LanSetupPanel extends StatefulWidget {
  const LanSetupPanel({
    super.key,
    required this.controller,
    required this.helper,
    this.disabled = false,
    this.showBleNamePrefixFilter = false,
  });
  final LanSetupController controller;
  final RealTransportHelper helper;
  final bool disabled;
  final bool showBleNamePrefixFilter;

  @override
  State<LanSetupPanel> createState() => _LanSetupPanelState();
}

class _LanSetupPanelState extends State<LanSetupPanel> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  late final _blePrefixFilter = TextEditingController(
    text: widget.controller.bleNamePrefixFilter,
  );
  final _manualIpCtrl = TextEditingController();

  @override
  void didUpdateWidget(covariant LanSetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller &&
        _blePrefixFilter.text != widget.controller.bleNamePrefixFilter) {
      _blePrefixFilter.text = widget.controller.bleNamePrefixFilter;
    }
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    _blePrefixFilter.dispose();
    _manualIpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final disabled = widget.disabled || c.busy;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AbsorbPointer(
            absorbing: disabled,
            child: RealBleConnectorRow(
              family: c.family,
              helper: widget.helper,
              connectedDevice: c.realBleDevice,
              namePrefixFilterController: widget.showBleNamePrefixFilter
                  ? _blePrefixFilter
                  : null,
              onNamePrefixFilterChanged: widget.showBleNamePrefixFilter
                  ? (value) => c.bleNamePrefixFilter = value
                  : null,
              onConnected: (device) => setState(() => c.realBleDevice = device),
              onDisconnected: () => setState(() => c.realBleDevice = null),
            ),
          ),
          const SizedBox(height: 12),
          DemoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: '1. 蓝牙配网与局域网发现'),
                const SizedBox(height: 10),
                const Text('热敏与 4 寸热升华共用蓝牙 Wi-Fi 配网。发现打印机时，手机与打印机需连接同一局域网。'),
                const SizedBox(height: 10),
                WifiSsidField(
                  controller: _ssid,
                  helper: widget.helper,
                  enabled: !disabled,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  enabled: !disabled,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Wi-Fi 密码'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: disabled
                          ? null
                          : () => c.provisionWifi(
                              ssid: _ssid.text,
                              password: _password.text,
                            ),
                      icon: const Icon(Icons.wifi_lock),
                      label: const Text('开始配网'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: disabled ? null : c.discoverPrinters,
                      icon: const Icon(Icons.radar),
                      label: const Text('发现打印机（UDP）'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('lan_manual_ip_field'),
                        controller: _manualIpCtrl,
                        enabled: !disabled,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '直连打印机 IP（可选）',
                          hintText: '如 192.168.200.161',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: const Key('lan_probe_manual_ip_btn'),
                      onPressed: disabled
                          ? null
                          : () => c.probeManualHost(_manualIpCtrl.text),
                      icon: const Icon(Icons.radar, size: 18),
                      label: const Text('探测'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ActionStatusBanner(
                  message: c.statusMessage,
                  busy: c.busy,
                  isError: c.lastActionFailed,
                ),
                for (final printer in c.discoveredPrinters)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    selected: c.selectedPrinter?.host == printer.host,
                    leading: Icon(
                      c.selectedPrinter?.host == printer.host
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(
                      '${printer.displayName} (${printer.host}:${printer.port})',
                    ),
                    subtitle: Text(
                      'MAC：${printer.macAddress ?? "未知"} · ${printer.discoveredVia.isEmpty ? "手动直连" : "UDP 22368"}',
                    ),
                    onTap: disabled ? null : () => c.selectPrinter(printer),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
