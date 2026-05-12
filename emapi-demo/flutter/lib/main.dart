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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6C8C)),
        useMaterial3: true,
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
}

class _ScanPage extends StatelessWidget {
  const _ScanPage(this.controller);

  final EmapiDemoController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusTile(
          title: controller.bluetoothEnabled ? '蓝牙已开启' : '蓝牙未开启或未授权',
          subtitle: controller.scanning ? '正在扫描设备' : '点击刷新开始扫描',
          icon: controller.bluetoothEnabled
              ? Icons.bluetooth
              : Icons.bluetooth_disabled,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: controller.devices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final device = controller.devices[index];
              return _DeviceTile(
                device: device,
                enabled: !controller.busy,
                onTap: () => controller.connect(device),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: controller.busy ? null : controller.startScan,
            icon: controller.scanning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(controller.scanning ? '扫描中' : '刷新'),
          ),
        ),
        _LogPanel(title: '命令结果', entries: controller.commandLogs),
      ],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusTile(
          title: '已连接 ${controller.connectedDeviceName ?? ''}',
          subtitle: controller.pendingActionLabel == null
              ? '可执行 EMAPI 功能'
              : '正在执行：${controller.pendingActionLabel}',
          icon: Icons.print,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ssidController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'WiFi SSID',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'WiFi 密码',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: otaPathController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'OTA 文件路径',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          controller.otaProgress,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _ActionGrid(
          busy: controller.busy,
          pendingActionLabel: controller.pendingActionLabel,
          actions: [
            _DemoAction('打印机休眠关机', controller.sleepShutdown),
            _DemoAction('查询 RFID 卡 UID', controller.queryRfidUid),
            _DemoAction('查询 RFID 卡信息', controller.queryRfidCardInfo),
            _DemoAction('查询卡内纸张长度', controller.queryRfidPaperLength),
            _DemoAction(
              '设置 RFID 认证失败处理',
              () => controller.setRfidAuthFailureHandling(
                EmapiRfidAuthFailurePolicy.forbidPrint,
              ),
            ),
            _DemoAction(
              '设置配网信息',
              () => controller.setWifiConfig(
                ssid: ssidController.text,
                password: passwordController.text,
              ),
            ),
            _DemoAction('查询 WIFI 模块连接状态', controller.queryWifiConnectionState),
            _DemoAction('查询 WIFI 模块热点相关信息', controller.queryWifiHotspotInfo),
            _DemoAction('查询打印机基本参数', controller.queryDeviceInfo),
            _DemoAction('查询打印状态', controller.queryPrintStatus),
            _DemoAction(
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
        return FilledButton.tonal(
          onPressed: busy ? null : action.onPressed,
          child: pending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(action.label, textAlign: TextAlign.center),
        );
      },
    );
  }
}

class _DemoAction {
  const _DemoAction(this.label, this.onPressed);

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
      leading: const Icon(Icons.bluetooth_searching),
      title: Text(device.name),
      subtitle: Text(
        '${device.protocolLabel}  ${device.mac.isEmpty ? '无 MAC' : device.mac}',
      ),
      trailing: Text(device.rssi == null ? '' : '${device.rssi} dBm'),
      onTap: enabled ? onTap : null,
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text('暂无')
            else
              for (final entry in entries.take(20)) ...[
                SelectableText(entry),
                const Divider(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}
