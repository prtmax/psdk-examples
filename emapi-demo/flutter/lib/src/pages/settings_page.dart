part of '../../main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final EmapiDemoController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('测试模式', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '没有真实蓝牙和打印机时，开启模拟模式进行完整流程验证。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('模拟模式'),
                      subtitle: const Text('生成模拟蓝牙设备，所有 EMAPI 操作返回模拟结果'),
                      value: controller.simulationMode,
                      onChanged: controller.busy
                          ? null
                          : (value) => controller.setSimulationMode(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('链路日志', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '开启后，「链路日志」页会按时间顺序交错显示每一包发送(TX)与接收(RX)，'
                      '含帧解析、字节数和间隔，便于判断"发出去了但设备没收到/没回"。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('原始接收 RX 日志'),
                      subtitle: const Text('把底层收到的每一包写入「链路日志」，与发送交错显示'),
                      value: controller.rawReceiveLoggingEnabled,
                      onChanged: controller.setRawReceiveLogging,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('原始发送 TX 日志'),
                      subtitle: const Text('把底层写出的每一包写入「链路日志」，含耗时与帧解析'),
                      value: controller.rawSendLoggingEnabled,
                      onChanged: controller.setRawSendLogging,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('协议 MTU', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'EMAPI 每帧的字节数（打印/文件传输分片）。帧越大，单次写出的突发越大，'
                      '设备侧串口接收缓冲越容易在忙时溢出丢字节。调小可缩短每次突发、'
                      '增加 ACK 次数，用于验证“是不是设备没来得及收”。重新连接后生效。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in const <int?>[null, 256, 512, 784])
                          ChoiceChip(
                            label: Text(
                              option == null ? '自动' : '$option',
                            ),
                            selected: controller.mtuOverride == option,
                            onSelected: (_) => controller.setMtuOverride(option),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前：${controller.mtuOverride == null ? '自动（设备上报）' : '${controller.mtuOverride}'}'
                      '${controller.knownMtu == null ? '' : '，已查询：${controller.knownMtu}'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
