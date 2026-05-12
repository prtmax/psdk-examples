import 'dart:async';

import 'package:file_picker/file_picker.dart';
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
                otaFileLabel: _otaFileLabel,
                onPickOtaFile: _pickOtaFile,
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

  String get _otaFileLabel {
    final path = otaPathController.text.trim();
    if (path.isEmpty) {
      return controller.simulationMode ? '未选择，模拟模式可直接开始' : '未选择 OTA 文件';
    }
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isEmpty ? path : parts.last;
  }

  Future<void> _pickOtaFile() async {
    if (controller.busy) {
      return;
    }
    final result = await FilePicker.pickFiles(allowMultiple: false);
    if (!mounted || result == null) {
      return;
    }
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未获取到 OTA 文件路径，请重新选择文件')));
      return;
    }
    setState(() {
      otaPathController.text = path;
    });
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
    required this.otaFileLabel,
    required this.onPickOtaFile,
  });

  final EmapiDemoController controller;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final TextEditingController otaPathController;
  final String otaFileLabel;
  final Future<void> Function() onPickOtaFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    const _SectionHeader(
                      title: '输入参数',
                      subtitle: '配网和 OTA 流程使用',
                    ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: controller.busy
                            ? null
                            : () => controller.setWifiConfig(
                                ssid: ssidController.text,
                                password: passwordController.text,
                              ),
                        icon: const Icon(Icons.send_to_mobile),
                        label: const Text('提交配网信息'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'OTA 文件',
                      subtitle: controller.simulationMode
                          ? '模拟模式可不选文件，直接使用内置模拟包'
                          : '选择升级文件后，再确认开始升级',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            otaFileLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: controller.busy ? null : onPickOtaFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('选择 OTA 文件'),
                        ),
                        FilledButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => controller.performOta(
                                  otaPathController.text,
                                ),
                          icon: const Icon(Icons.system_update_alt),
                          label: const Text('开始 OTA 升级'),
                        ),
                      ],
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
              const _SectionHeader(
                title: 'EMAPI 操作',
                subtitle: '执行后结果会显示在底部反馈栏',
              ),
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
                  _DemoAction(
                    Icons.nfc,
                    '查询 RFID 卡 UID',
                    controller.queryRfidUid,
                  ),
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
            ],
          ),
        ),
        _ActivityDock(
          commandLogs: controller.commandLogs,
          reportLogs: controller.reportLogs,
          onOpenAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ActivityLogPage(controller: controller),
            ),
          ),
        ),
      ],
    );
  }
}

class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key, required this.controller});

  final EmapiDemoController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('全部记录'),
          bottom: TabBar(
            tabs: [
              Tab(text: '命令结果 ${controller.commandLogs.length}'),
              Tab(text: '上报解析 ${controller.reportLogs.length}'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return TabBarView(
              children: [
                _LogList(emptyText: '暂无命令结果', entries: controller.commandLogs),
                _LogList(emptyText: '暂无上报解析', entries: controller.reportLogs),
              ],
            );
          },
        ),
      ),
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

class _ActivityDock extends StatelessWidget {
  const _ActivityDock({
    required this.commandLogs,
    required this.reportLogs,
    required this.onOpenAll,
  });

  final List<String> commandLogs;
  final List<String> reportLogs;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('最近反馈', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: onOpenAll,
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('全部记录'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _LatestActivityTile(
                    icon: Icons.terminal,
                    label: '命令',
                    count: commandLogs.length,
                    text: commandLogs.isEmpty ? '暂无命令结果' : commandLogs.first,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LatestActivityTile(
                    icon: Icons.sensors,
                    label: '上报',
                    count: reportLogs.length,
                    text: reportLogs.isEmpty ? '暂无上报解析' : reportLogs.first,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestActivityTile extends StatelessWidget {
  const _LatestActivityTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.text,
  });

  final IconData icon;
  final String label;
  final int count;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(label, style: theme.textTheme.labelMedium),
                const Spacer(),
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.emptyText, required this.entries});

  final String emptyText;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _Panel(child: SelectableText(entries[index]));
      },
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
