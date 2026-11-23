import 'dart:async';

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
    this.namePrefixFilterController,
    this.onNamePrefixFilterChanged,
  });

  final CloudPrinterFamily family;
  final RealTransportHelper helper;
  final adapter.ConnectedDevice<dynamic>? connectedDevice;
  final ValueChanged<adapter.ConnectedDevice<dynamic>> onConnected;
  final VoidCallback onDisconnected;
  final TextEditingController? namePrefixFilterController;
  final ValueChanged<String>? onNamePrefixFilterChanged;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: helper,
    builder: (context, _) => _buildConnectionRow(context),
  );

  Widget _buildConnectionRow(BuildContext context) {
    final connected =
        connectedDevice != null &&
        connectedDevice!.connectionState() == adapter.ConnectionState.connected;
    final filterController = namePrefixFilterController;
    return DemoPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  connected
                      ? 'BLE: ${connectedDevice!.deviceName() ?? connectedDevice!.deviceMac() ?? "已连接"}'
                      : '真机蓝牙（${family.title})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (connected)
                OutlinedButton(
                  onPressed: helper.connecting
                      ? null
                      : () async {
                          await connectedDevice!.disconnect();
                          if (context.mounted) onDisconnected();
                        },
                  child: const Text('断开蓝牙'),
                )
              else
                FilledButton.tonal(
                  onPressed: helper.connecting
                      ? null
                      : () => _scanAndPick(context),
                  child: Text(helper.connecting ? '连接中…' : '扫描蓝牙'),
                ),
            ],
          ),
          if (filterController != null) ...[
            const SizedBox(height: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: filterController,
              builder: (context, value, _) {
                return TextField(
                  key: const Key('ble_name_prefix_filter_field'),
                  controller: filterController,
                  onChanged: onNamePrefixFilterChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: '蓝牙名称前缀过滤（逗号分隔）',
                    hintText: '例如：z11, h100（不区分大小写，留空不过滤）',
                    helperText: '多个前缀用 , 分隔，不区分大小写；留空显示全部',
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.filter_alt_outlined, size: 18),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '清空过滤',
                            onPressed: () {
                              filterController.clear();
                              onNamePrefixFilterChanged?.call('');
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scanAndPick(BuildContext context) async {
    // 先创建弹窗，再开始扫描；设备通过 helper 的通知逐条加入列表。
    final selection = showModalBottomSheet<DemoBleDevice>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BleDevicePicker(
        helper: helper,
        family: family,
        namePrefixFilterController: namePrefixFilterController,
        onNamePrefixFilterChanged: onNamePrefixFilterChanged,
      ),
    );
    unawaited(helper.scanBle(family: family));
    final device = await selection;
    await helper.stopBleScan();
    if (device == null || !context.mounted) return;
    final connection = await helper.connectBle(family: family, device: device);
    if (!context.mounted) {
      await connection?.disconnect();
      return;
    }
    if (connection != null) {
      onConnected(connection);
    } else if (helper.lastError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(helper.lastError!)));
    }
  }
}

class _BleDevicePicker extends StatelessWidget {
  const _BleDevicePicker({
    required this.helper,
    required this.family,
    this.namePrefixFilterController,
    this.onNamePrefixFilterChanged,
  });
  final RealTransportHelper helper;
  final CloudPrinterFamily family;
  final TextEditingController? namePrefixFilterController;
  final ValueChanged<String>? onNamePrefixFilterChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.65,
    child: SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          helper,
          ?namePrefixFilterController,
        ]),
        builder: (context, _) {
          final allNamedDevices = helper.discoveredBleDevices
              .where((device) => device.hasDisplayName)
              .toList();
          final prefixes = parseBleNamePrefixes(
            namePrefixFilterController?.text ?? '',
          );
          final devices = allNamedDevices
              .where((device) => matchesBleNamePrefixes(device.name, prefixes))
              .toList();
          final statusText =
              helper.lastError ??
              (prefixes.isEmpty
                  ? (helper.scanning
                        ? '正在扫描… 已发现 ${devices.length} 台有名称的设备'
                        : devices.isEmpty
                        ? '未发现有名称的蓝牙设备，请确认打印机已开启'
                        : '已发现 ${devices.length} 台设备，点击即可连接')
                  : (helper.scanning
                        ? '正在扫描… 已匹配 ${devices.length} 台（共发现 ${allNamedDevices.length} 台）'
                        : devices.isEmpty
                        ? '未发现前缀匹配（${prefixes.join(" / ")}）的蓝牙设备（共发现 ${allNamedDevices.length} 台）'
                        : '已匹配 ${devices.length} 台设备（共发现 ${allNamedDevices.length} 台），点击即可连接'));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '选择蓝牙打印机',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭扫描',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (helper.scanning) const LinearProgressIndicator(),
              if (prefixes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '前缀过滤：${prefixes.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          namePrefixFilterController?.clear();
                          onNamePrefixFilterChanged?.call('');
                        },
                        child: const Text('清空过滤'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(statusText),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print_outlined),
                      title: Text(device.name!.trim()),
                      subtitle: Text(device.mac ?? '未知 MAC 地址'),
                      onTap: () => Navigator.of(context).pop(device),
                    );
                  },
                ),
              ),
              if (!helper.scanning)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.tonalIcon(
                    onPressed: () => unawaited(helper.scanBle(family: family)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新扫描'),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
