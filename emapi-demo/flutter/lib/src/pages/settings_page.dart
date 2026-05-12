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
            ],
          );
        },
      ),
    );
  }
}
