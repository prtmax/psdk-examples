part of '../../main.dart';

class _ScanPage extends StatelessWidget {
  const _ScanPage(this.controller);

  final EmapiDemoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroPanel(
          title: controller.simulationMode ? '模拟测试台' : '蓝牙设备',
          subtitle: controller.simulationMode
              ? '无需真实硬件，使用模拟设备验证 EMAPI 流程'
              : controller.scanning
              ? '正在扫描附近打印机'
              : '扫描并连接支持 EMAPI 的打印机',
          icon: controller.simulationMode
              ? Icons.science_outlined
              : Icons.bluetooth_searching,
          trailing: _ModePill(
            label: controller.simulationMode ? '模拟模式' : '真实设备',
            active: controller.simulationMode,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.busy ? null : controller.startScan,
                icon: controller.scanning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar),
                label: Text(controller.scanning ? '扫描中' : '开始扫描'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: controller.scanning && !controller.busy
                  ? controller.stopScan
                  : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('停止'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: '设备列表',
          subtitle: controller.devices.isEmpty
              ? '暂无设备'
              : '${controller.devices.length} 台可连接设备',
        ),
        const SizedBox(height: 8),
        if (controller.devices.isEmpty)
          _EmptyState(
            icon: controller.simulationMode
                ? Icons.science_outlined
                : Icons.bluetooth_disabled,
            text: controller.simulationMode ? '点击开始扫描生成模拟打印机' : '点击开始扫描查找蓝牙打印机',
          )
        else
          _Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < controller.devices.length; index++)
                  Column(
                    children: [
                      _DeviceTile(
                        device: controller.devices[index],
                        enabled: !controller.busy,
                        onTap: () =>
                            controller.connect(controller.devices[index]),
                      ),
                      if (index != controller.devices.length - 1)
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _LogPanel(title: '命令结果', entries: controller.commandLogs),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.enabled,
    required this.onTap,
  });

  final DiscoveredPrinterDevice device;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          device.simulated ? Icons.science_outlined : Icons.bluetooth,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(device.name),
      subtitle: Text(
        '${device.protocolLabel}  ${device.mac.isEmpty ? '无 MAC' : device.mac}',
      ),
      trailing: FilledButton.tonal(
        onPressed: enabled ? onTap : null,
        child: const Text('连接'),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
