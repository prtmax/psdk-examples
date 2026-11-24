import '../models/demo_labels.dart';
import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../controllers/real_transport_helper.dart';
import '../controllers/thermal_lan_controller.dart';
import 'common_widgets.dart';
import 'lan_setup_panel.dart';

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
  final _labelCtrl = TextEditingController(text: 'PSDK Thermal LAN Demo');

  @override
  void dispose() {
    _labelCtrl.dispose();
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
              family: CloudPrinterFamily.thermalLanStream,
              runMode: c.mode,
              statusMessage: c.statusMessage,
              busy: c.busy,
            ),
            const SizedBox(height: 12),
            LanSetupPanel(
              controller: c.setup,
              helper: widget.realTransportHelper,
              disabled: c.busy,
            ),
            const SizedBox(height: 12),
            DemoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '2. TCP 9100 连接与打印',
                    trailing: StatusPill(
                      label: c.isTcpConnected ? 'TCP 已连接' : '空闲',
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
                      FilledButton.tonalIcon(
                        onPressed: c.busy || c.discoveredPrinters.isEmpty
                            ? null
                            : () => c.connectTcpPrinter(),
                        icon: const Icon(Icons.lan_outlined),
                        label: const Text('连接 TCP 9100'),
                      ),
                      if (c.isTcpConnected)
                        OutlinedButton(
                          onPressed: c.busy
                              ? null
                              : () => c.disconnectTcpPrinter(
                                  notifyFeedback: true,
                                ),
                          child: const Text('断开 TCP'),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(labelText: 'TSPL 标签文字'),
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
                        label: const Text('发送 TSPL 打印'),
                      ),
                      if (c.busy && c.isTcpConnected)
                        OutlinedButton.icon(
                          onPressed: c.cancelTsplPrintJob,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('取消'),
                        ),
                    ],
                  ),
                  if (c.printProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: c.printProgress!.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '${demoLabel(c.printProgress!.stage)}: ${c.printProgress!.bytesSent}/${c.printProgress!.totalBytes} B',
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
