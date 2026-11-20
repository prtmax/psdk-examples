import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../controllers/esc_wan_controller.dart';
import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';
import '../stubs/sim_esc_wan_stub.dart';
import 'common_widgets.dart';

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
  final _ssidCtrl = TextEditingController(text: 'DemoOfficeWiFi');
  final _pwdCtrl = TextEditingController(text: 'office-pass-2026');
  final _hostsCtrl = TextEditingController(
    text: 'cprint-api.iprtapp.com:30501',
  );
  final _keyCtrl = TextEditingController(text: 'demo-device-key');
  final _apiUrlCtrl = TextEditingController(
    text: 'https://cprint-api.iprtapp.com',
  );
  final _mqttHostCtrl = TextEditingController(text: 'mqtt.iprtapp.com');
  final _snCtrl = TextEditingController(text: 'SIM-ESC-2026001');
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
                  const SectionHeader(
                    title: '1. ESC BLE TLV Provisioning (psdk_fruit_esc)',
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hostsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cloud Hosts (ESetHost)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Device Key (ESetKey)',
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
                        label: const Text('Provision ESC TLV'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy ? null : c.inspectEscDevice,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Inspect ESC Info'),
                      ),
                      OutlinedButton.icon(
                        onPressed: c.busy ? null : c.resetNetworkInfo,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Net Info'),
                      ),
                    ],
                  ),
                  if (c.lastSerialNumber != null ||
                      c.lastStaResult != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(
                      label: 'Serial Number',
                      value: c.lastSerialNumber ?? '-',
                    ),
                    KeyValueRow(label: 'MAC Address', value: c.lastMac ?? '-'),
                    KeyValueRow(
                      label: 'Firmware',
                      value: c.lastFirmwareVersion ?? '-',
                    ),
                    KeyValueRow(
                      label: 'Wi-Fi Name',
                      value: c.lastWifiName ?? '-',
                    ),
                    KeyValueRow(
                      label: 'STA Link State',
                      value: c.lastStaResult?.state.name ?? '-',
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
                    title: '2. Cloud WAN Driver (psdk_cloud_wan)',
                    trailing: StatusPill(
                      label: c.isWanConnected ? 'Connected' : 'Disconnected',
                      color: c.isWanConnected
                          ? const Color(0xFF2E7D32)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isSim) ...[
                    TextField(
                      controller: _apiUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cloud API Base URL',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mqttHostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'MQTT v5 TLS Host',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _snCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Printer Serial Number',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Device Token (optional)',
                      ),
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
                        label: const Text('Connect WAN'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: c.busy || !c.isWanConnected
                            ? null
                            : c.queryWanStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Query State'),
                      ),
                      FilledButton.icon(
                        onPressed: c.busy || !c.isWanConnected
                            ? null
                            : c.submitWanPrintJob,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Upload & Print .prn'),
                      ),
                      if (c.busy && c.isWanConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelActiveWanJob,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Job'),
                        ),
                      if (c.isWanConnected)
                        OutlinedButton(
                          onPressed: c.busy ? null : c.disconnectWan,
                          child: const Text('Disconnect'),
                        ),
                    ],
                  ),
                  if (c.wanSnapshot != null) ...[
                    const Divider(height: 20),
                    KeyValueRow(
                      label: 'WAN State',
                      value: c.wanSnapshot!.state.name,
                    ),
                    KeyValueRow(
                      label: 'Issues',
                      value: c.wanSnapshot!.issues.isEmpty
                          ? 'None'
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
                      'Job Stage: ${c.jobProgress!.stage.name} — ${c.jobProgress!.message ?? ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (isSim) ...[
                    const Divider(height: 20),
                    const SectionHeader(
                      title: 'Simulation Fault & Fallback Controls',
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: c.selectedFaultCode,
                      decoration: const InputDecoration(
                        labelText: 'Simulated Cloud Fault Code',
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 - Normal')),
                        DropdownMenuItem(
                          value: 6001,
                          child: Text('6001 - LACK_PAPER'),
                        ),
                        DropdownMenuItem(
                          value: 6003,
                          child: Text('6003 - OVERHEAT'),
                        ),
                        DropdownMenuItem(
                          value: 6004,
                          child: Text('6004 - LOW_BATTERY'),
                        ),
                        DropdownMenuItem(
                          value: 6006,
                          child: Text('6006 - COVER_OPEN'),
                        ),
                        DropdownMenuItem(
                          value: 6013,
                          child: Text('6013 - PAPER_ERROR'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setSimulatedFaultCode(v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SimCloudJobOutcome>(
                      initialValue: c.selectedJobOutcome,
                      decoration: const InputDecoration(
                        labelText: 'Next Cloud Job Outcome',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.success,
                          child: Text(
                            'Success (confirm -> printing -> success)',
                          ),
                        ),
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.failWithFault,
                          child: Text('Remote Fail (errCode fault)'),
                        ),
                        DropdownMenuItem(
                          value: SimCloudJobOutcome.stopPrintEvent,
                          child: Text('Remote Stop Event (stop_print)'),
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
                      label: const Text(
                        'Simulate >=3 Poll Failures -> Offline',
                      ),
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
