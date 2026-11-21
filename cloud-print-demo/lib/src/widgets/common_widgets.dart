import 'package:flutter/material.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart' as adapter;
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';

class DemoPanel extends StatelessWidget {
  const DemoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: const Color(0xFFFBFCFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.family,
    required this.runMode,
    required this.statusMessage,
    this.busy = false,
  });

  final CloudPrinterFamily family;
  final DemoRunMode runMode;
  final String statusMessage;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(family.icon, color: scheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      family.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: runMode.label,
                color: runMode == DemoRunMode.simulation
                    ? scheme.primary
                    : scheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Expanded(
                child: Text(
                  statusMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class RealBleConnectorRow extends StatelessWidget {
  const RealBleConnectorRow({
    super.key,
    required this.family,
    required this.helper,
    required this.connectedDevice,
    required this.onConnected,
    required this.onDisconnected,
  });

  final CloudPrinterFamily family;
  final RealTransportHelper helper;
  final adapter.ConnectedDevice<dynamic>? connectedDevice;
  final ValueChanged<adapter.ConnectedDevice<dynamic>> onConnected;
  final VoidCallback onDisconnected;

  @override
  Widget build(BuildContext context) {
    final connected =
        connectedDevice != null &&
        connectedDevice!.connectionState() == adapter.ConnectionState.connected;
    return DemoPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              connected
                  ? 'BLE: ${connectedDevice!.deviceName() ?? connectedDevice!.deviceMac() ?? "Connected"}'
                  : 'Real Device BLE (${family.title})',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (connected)
            OutlinedButton(
              onPressed: () async {
                await connectedDevice!.disconnect();
                if (context.mounted) onDisconnected();
              },
              child: const Text('Disconnect BLE'),
            )
          else
            FilledButton.tonal(
              onPressed: () => _scanAndPick(context),
              child: const Text('Scan BLE'),
            ),
        ],
      ),
    );
  }

  Future<void> _scanAndPick(BuildContext context) async {
    final devices = await helper.scanBle(family: family);
    if (!context.mounted) return;
    if (helper.lastError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(helper.lastError!)));
      return;
    }
    if (devices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No BLE devices found')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: devices.length,
        itemBuilder: (ctx, i) {
          final dev = devices[i];
          return ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(dev.name ?? 'Unnamed BLE Printer'),
            subtitle: Text(dev.mac ?? 'Unknown MAC'),
            onTap: () async {
              Navigator.of(ctx).pop();
              final conn = await helper.connectBle(family: family, device: dev);
              if (!context.mounted) {
                await conn?.disconnect();
                return;
              }
              if (conn != null) {
                onConnected(conn);
              } else if (context.mounted && helper.lastError != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(helper.lastError!)));
              }
            },
          );
        },
      ),
    );
  }
}
