import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_wifi/psdk_fruit_wifi.dart';

import '../controllers/real_transport_helper.dart';
import '../controllers/thermal_lan_controller.dart';
import '../models/demo_mode.dart';
import 'common_widgets.dart';

class ThermalLanTab extends StatefulWidget {
  const ThermalLanTab({
    super.key,
    required this.controller,
    required this.realTransportHelper,
  });

  final ThermalLanController controller;
  final RealTransportHelper realTransportHelper;

  @override
  State<ThermalLanTab> createState() => _ThermalLanTabState();
}

class _ThermalLanTabState extends State<ThermalLanTab> {
  final _ssidCtrl = TextEditingController(text: 'ThermalShop-5G');
  final _pwdCtrl = TextEditingController(text: 'shop-secret-password');
  final _ipCtrl = TextEditingController(text: '192.168.1.77');
  final _labelCtrl = TextEditingController(text: 'PSDK Thermal LAN Demo');
  bool _dhcp = true;

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _ipCtrl.dispose();
    _labelCtrl.dispose();
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
              family: CloudPrinterFamily.thermalLanStream,
              runMode: c.mode,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            if (!isSim) ...[
              RealBleConnectorRow(
                family: CloudPrinterFamily.thermalLanStream,
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
                        '1. Dual-Dialect Wi-Fi Provisioning (psdk_fruit_wifi)',
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<WifiTextDialect>(
                    segments: const [
                      ButtonSegment(
                        value: WifiTextDialect.bluetoothAt,
                        label: Text('BLUETOOTH AT'),
                      ),
                      ButtonSegment(
                        value: WifiTextDialect.tsplWlan,
                        label: Text('TSPL WLAN'),
                      ),
                    ],
                    selected: <WifiTextDialect>{c.selectedDialect},
                    onSelectionChanged: (s) => c.setDialect(s.first),
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
                  if (c.selectedDialect == WifiTextDialect.tsplWlan) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use DHCP (WLAN DHCP)'),
                      value: _dhcp,
                      onChanged: (v) => setState(() => _dhcp = v),
                    ),
                    if (!_dhcp)
                      TextField(
                        controller: _ipCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Static IPv4',
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (c.selectedDialect == WifiTextDialect.bluetoothAt)
                        FilledButton.icon(
                          onPressed: c.busy
                              ? null
                              : () => c.runBluetoothAtProvisioning(
                                  ssid: _ssidCtrl.text,
                                  password: _pwdCtrl.text,
                                ),
                          icon: const Icon(Icons.bluetooth_audio),
                          label: const Text('Run AT Provision'),
                        )
                      else ...[
                        FilledButton.icon(
                          onPressed: c.busy
                              ? null
                              : () => c.runTsplWlanProvisioning(
                                  ssid: _ssidCtrl.text,
                                  password: _pwdCtrl.text,
                                  dhcp: _dhcp,
                                  staticIp: _ipCtrl.text,
                                ),
                          icon: const Icon(Icons.settings_ethernet),
                          label: const Text('Run TSPL WLAN'),
                        ),
                        OutlinedButton(
                          onPressed: c.busy ? null : c.resetTsplWlanDefaults,
                          child: const Text('WLAN DEFAULT'),
                        ),
                      ],
                    ],
                  ),
                  if (c.lastAtSsid != null ||
                      c.lastTsplDiagSummary != null) ...[
                    const Divider(height: 20),
                    if (c.lastAtSsid != null) ...[
                      KeyValueRow(label: 'AT SSID', value: c.lastAtSsid!),
                      KeyValueRow(
                        label: 'AT Link State',
                        value: c.lastAtLinkState.name,
                      ),
                    ],
                    if (c.lastTsplDiagSummary != null)
                      KeyValueRow(
                        label: 'TSPL Diagnostic',
                        value: c.lastTsplDiagSummary!,
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
                    title: '2. UDP 22368 Discovery & TCP :9100 Stream',
                    trailing: StatusPill(
                      label: c.isTcpConnected ? 'TCP Connected' : 'Idle',
                      color: c.isTcpConnected
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
                        onPressed: c.busy ? null : c.discoverLanPrinters,
                        icon: const Icon(Icons.radar),
                        label: const Text('Discover UDP 22368'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy || c.discoveredPrinters.isEmpty
                            ? null
                            : () => c.connectTcpPrinter(),
                        icon: const Icon(Icons.lan_outlined),
                        label: const Text('Connect TCP :9100'),
                      ),
                      if (c.isTcpConnected)
                        OutlinedButton(
                          onPressed: c.busy ? null : c.disconnectTcpPrinter,
                          child: const Text('Disconnect TCP'),
                        ),
                    ],
                  ),
                  if (c.discoveredPrinters.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final p in c.discoveredPrinters)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          c.selectedPrinter == p
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () => setState(() => c.selectedPrinter = p),
                        title: Text('${p.displayName} (${p.host}:${p.port})'),
                        subtitle: Text(
                          'MAC: ${p.macAddress ?? "-"} · SSID: ${p.wifiSsid ?? "-"} · PWD: ${p.metadata["wifiPassword"] ?? "[REDACTED]"}',
                        ),
                      ),
                  ],
                  const Divider(height: 20),
                  TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'TSPL Label Text',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: c.busy || !c.isTcpConnected
                            ? null
                            : () => c.streamTsplPrintJob(text: _labelCtrl.text),
                        icon: const Icon(Icons.print),
                        label: const Text('Stream TSPL Print'),
                      ),
                      if (c.busy && c.isTcpConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelTsplPrintJob,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Cancel'),
                        ),
                    ],
                  ),
                  if (c.printProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: c.printProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '${c.printProgress!.stage.name}: ${c.printProgress!.bytesSent}/${c.printProgress!.totalBytes} B',
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
