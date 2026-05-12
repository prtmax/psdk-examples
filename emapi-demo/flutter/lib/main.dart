import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

import 'src/bluetooth_printer_connector.dart';
import 'src/emapi_demo_controller.dart';

void main() {
  runApp(const EmapiDemoApp());
}

class EmapiDemoApp extends StatelessWidget {
  const EmapiDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMAPI Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF256B75),
          onPrimary: Color(0xFFF7FBFA),
          primaryContainer: Color(0xFFD7EEF0),
          onPrimaryContainer: Color(0xFF153F46),
          secondary: Color(0xFF6B6558),
          onSecondary: Color(0xFFF8F5EF),
          secondaryContainer: Color(0xFFEDE4D4),
          onSecondaryContainer: Color(0xFF403A2F),
          surface: Color(0xFFF6F8F6),
          onSurface: Color(0xFF1D2424),
          surfaceContainerHighest: Color(0xFFE3E9E7),
          outline: Color(0xFF74817E),
          outlineVariant: Color(0xFFC8D2CF),
          error: Color(0xFFB4473D),
          onError: Color(0xFFFDF8F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFBFCFA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC8D2CF)),
          ),
        ),
      ),
      home: const EmapiDemoPage(),
    );
  }
}

class EmapiDemoPage extends StatefulWidget {
  const EmapiDemoPage({super.key});

  @override
  State<EmapiDemoPage> createState() => _EmapiDemoPageState();
}

class _EmapiDemoPageState extends State<EmapiDemoPage> {
  late final EmapiDemoController controller;
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  final otaPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = EmapiDemoController();
    controller.addListener(_onControllerChanged);
    unawaited(controller.init());
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    ssidController.dispose();
    passwordController.dispose();
    otaPathController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMAPI Flutter Demo'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: controller.busy ? null : _openSettings,
            icon: const Icon(Icons.tune),
          ),
          if (controller.connected)
            IconButton(
              tooltip: '断开连接',
              onPressed: controller.busy ? null : controller.disconnect,
              icon: const Icon(Icons.link_off),
            ),
        ],
      ),
      body: SafeArea(
        child: controller.connected
            ? _FunctionPage(
                controller: controller,
                ssidController: ssidController,
                passwordController: passwordController,
                otaPathController: otaPathController,
              )
            : _ScanPage(controller),
      ),
    );
  }

  Future<void> _openSettings() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(controller: controller),
      ),
    );
  }
}

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

class _FunctionPage extends StatelessWidget {
  const _FunctionPage({
    required this.controller,
    required this.ssidController,
    required this.passwordController,
    required this.otaPathController,
  });

  final EmapiDemoController controller;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final TextEditingController otaPathController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroPanel(
          title: controller.connectedDeviceName ?? 'EMAPI 打印机',
          subtitle: controller.pendingActionLabel == null
              ? '连接已建立，可执行 EMAPI 功能'
              : '正在执行：${controller.pendingActionLabel}',
          icon: controller.simulationMode
              ? Icons.science_outlined
              : Icons.print,
          trailing: _ModePill(
            label: controller.simulationMode ? '模拟模式' : '真实设备',
            active: controller.simulationMode,
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: '输入参数', subtitle: '配网和 OTA 流程使用'),
              const SizedBox(height: 12),
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.wifi),
                  labelText: 'WiFi SSID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.key),
                  labelText: 'WiFi 密码',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: otaPathController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.upload_file),
                  labelText: controller.simulationMode
                      ? 'OTA 文件路径（模拟模式可留空）'
                      : 'OTA 文件路径',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          tone: _PanelTone.subtle,
          child: Row(
            children: [
              Icon(Icons.speed, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.otaProgress,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'EMAPI 操作', subtitle: '请求执行时会暂时禁用其它操作'),
        const SizedBox(height: 8),
        _ActionGrid(
          busy: controller.busy,
          pendingActionLabel: controller.pendingActionLabel,
          actions: [
            _DemoAction(
              Icons.power_settings_new,
              '打印机休眠关机',
              controller.sleepShutdown,
            ),
            _DemoAction(Icons.nfc, '查询 RFID 卡 UID', controller.queryRfidUid),
            _DemoAction(
              Icons.badge_outlined,
              '查询 RFID 卡信息',
              controller.queryRfidCardInfo,
            ),
            _DemoAction(
              Icons.straighten,
              '查询卡内纸张长度',
              controller.queryRfidPaperLength,
            ),
            _DemoAction(
              Icons.verified_user_outlined,
              '设置 RFID 认证失败处理',
              () => controller.setRfidAuthFailureHandling(
                EmapiRfidAuthFailurePolicy.forbidPrint,
              ),
            ),
            _DemoAction(
              Icons.router_outlined,
              '设置配网信息',
              () => controller.setWifiConfig(
                ssid: ssidController.text,
                password: passwordController.text,
              ),
            ),
            _DemoAction(
              Icons.wifi_tethering,
              '查询 WIFI 模块连接状态',
              controller.queryWifiConnectionState,
            ),
            _DemoAction(
              Icons.network_wifi,
              '查询 WIFI 模块热点相关信息',
              controller.queryWifiHotspotInfo,
            ),
            _DemoAction(
              Icons.info_outline,
              '查询打印机基本参数',
              controller.queryDeviceInfo,
            ),
            _DemoAction(
              Icons.receipt_long,
              '查询打印状态',
              controller.queryPrintStatus,
            ),
            _DemoAction(
              Icons.system_update_alt,
              'OTA 升级',
              () => controller.performOta(otaPathController.text),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LogPanel(title: '命令结果', entries: controller.commandLogs),
        const SizedBox(height: 16),
        _LogPanel(title: '上报解析', entries: controller.reportLogs),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.actions,
    required this.busy,
    required this.pendingActionLabel,
  });

  final List<_DemoAction> actions;
  final bool busy;
  final String? pendingActionLabel;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 56,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        final pending = pendingActionLabel == action.label;
        return FilledButton.tonalIcon(
          onPressed: busy ? null : action.onPressed,
          icon: pending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(action.icon, size: 18),
          label: Text(action.label, textAlign: TextAlign.center),
        );
      },
    );
  }
}

class _DemoAction {
  const _DemoAction(this.icon, this.label, this.onPressed);

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      tone: _PanelTone.emphasis,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = active
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.onPrimary.withValues(alpha: 0.14);
    final foreground = active
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

enum _PanelTone { normal, subtle, emphasis }

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.tone = _PanelTone.normal,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final _PanelTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = switch (tone) {
      _PanelTone.emphasis => theme.colorScheme.primary,
      _PanelTone.subtle => theme.colorScheme.primaryContainer.withValues(
        alpha: 0.45,
      ),
      _PanelTone.normal => const Color(0xFFFBFCFA),
    };
    final border = tone == _PanelTone.emphasis
        ? Colors.transparent
        : theme.colorScheme.outlineVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      tone: _PanelTone.subtle,
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.title, required this.entries});

  final String title;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: '${entries.length} 条记录'),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              '暂无',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final entry in entries.take(20)) ...[
              SelectableText(entry),
              const Divider(height: 16),
            ],
        ],
      ),
    );
  }
}
