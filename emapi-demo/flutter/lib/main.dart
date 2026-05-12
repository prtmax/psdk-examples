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

enum _FunctionSheetMode { actions, wifi, ota }

class _FunctionPage extends StatefulWidget {
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
  State<_FunctionPage> createState() => _FunctionPageState();
}

class _FunctionPageState extends State<_FunctionPage> {
  _FunctionSheetMode sheetMode = _FunctionSheetMode.actions;

  EmapiDemoController get controller {
    return widget.controller;
  }

  void _showActions() {
    setState(() {
      sheetMode = _FunctionSheetMode.actions;
    });
  }

  void _showWifiForm() {
    setState(() {
      sheetMode = _FunctionSheetMode.wifi;
    });
  }

  void _showOtaForm() {
    setState(() {
      sheetMode = _FunctionSheetMode.ota;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _HeroPanel(
                  title: controller.connectedDeviceName ?? 'EMAPI 打印机',
                  subtitle: controller.pendingActionLabel == null
                      ? '记录实时显示，操作从底部面板执行'
                      : '正在执行：${controller.pendingActionLabel}',
                  icon: controller.simulationMode
                      ? Icons.science_outlined
                      : Icons.print,
                  trailing: _ModePill(
                    label: controller.simulationMode ? '模拟模式' : '真实设备',
                    active: controller.simulationMode,
                  ),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: '命令结果 ${controller.commandLogs.length}'),
                  Tab(text: '上报解析 ${controller.reportLogs.length}'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _LogList(
                      emptyText: '暂无命令结果',
                      entries: controller.commandLogs,
                      bottomPadding: 210,
                    ),
                    _LogList(
                      emptyText: '暂无上报解析',
                      entries: controller.reportLogs,
                      bottomPadding: 210,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _OperationSheet(
            mode: sheetMode,
            controller: controller,
            ssidController: widget.ssidController,
            passwordController: widget.passwordController,
            otaPathController: widget.otaPathController,
            otaFileLabel: widget.otaFileLabel,
            onPickOtaFile: widget.onPickOtaFile,
            onBack: _showActions,
            onOpenWifi: _showWifiForm,
            onOpenOta: _showOtaForm,
          ),
        ],
      ),
    );
  }
}

class _OperationSheet extends StatefulWidget {
  const _OperationSheet({
    required this.mode,
    required this.controller,
    required this.ssidController,
    required this.passwordController,
    required this.otaPathController,
    required this.otaFileLabel,
    required this.onPickOtaFile,
    required this.onBack,
    required this.onOpenWifi,
    required this.onOpenOta,
  });

  final _FunctionSheetMode mode;
  final EmapiDemoController controller;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final TextEditingController otaPathController;
  final String otaFileLabel;
  final Future<void> Function() onPickOtaFile;
  final VoidCallback onBack;
  final VoidCallback onOpenWifi;
  final VoidCallback onOpenOta;

  @override
  State<_OperationSheet> createState() => _OperationSheetState();
}

class _OperationSheetState extends State<_OperationSheet> {
  final sheetController = DraggableScrollableController();
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    sheetController.addListener(_handleSheetSizeChanged);
  }

  @override
  void dispose() {
    sheetController.removeListener(_handleSheetSizeChanged);
    sheetController.dispose();
    super.dispose();
  }

  void _handleSheetSizeChanged() {
    final nextExpanded = sheetController.size >= 0.34;
    if (nextExpanded != expanded) {
      setState(() {
        expanded = nextExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.26,
      minChildSize: 0.18,
      maxChildSize: 0.64,
      snap: true,
      snapSizes: const [0.18, 0.36, 0.64],
      builder: (context, scrollController) {
        return _SheetSurface(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            children: [
              const _SheetHandle(),
              if (widget.mode == _FunctionSheetMode.actions)
                _ActionSheetContent(
                  controller: widget.controller,
                  expanded: expanded,
                  onOpenWifi: widget.onOpenWifi,
                  onOpenOta: widget.onOpenOta,
                )
              else if (widget.mode == _FunctionSheetMode.wifi)
                _WifiSheetContent(
                  controller: widget.controller,
                  ssidController: widget.ssidController,
                  passwordController: widget.passwordController,
                  onBack: widget.onBack,
                )
              else
                _OtaSheetContent(
                  controller: widget.controller,
                  otaPathController: widget.otaPathController,
                  otaFileLabel: widget.otaFileLabel,
                  onPickOtaFile: widget.onPickOtaFile,
                  onBack: widget.onBack,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ActionSheetContent extends StatelessWidget {
  const _ActionSheetContent({
    required this.controller,
    required this.expanded,
    required this.onOpenWifi,
    required this.onOpenOta,
  });

  final EmapiDemoController controller;
  final bool expanded;
  final VoidCallback onOpenWifi;
  final VoidCallback onOpenOta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(
          title: '功能区',
          subtitle: controller.pendingActionLabel == null
              ? expanded
                    ? '已展开，多行显示全部操作'
                    : '左右滑动选择操作，上拉切换为多行'
              : '正在执行：${controller.pendingActionLabel}',
        ),
        const SizedBox(height: 10),
        if (expanded)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in _mainActions)
                _ActionButtonTile(
                  icon: action.icon,
                  label: action.label,
                  busy: controller.busy,
                  pending: controller.pendingActionLabel == action.label,
                  onPressed: () => action.invoke(
                    controller: controller,
                    onOpenWifi: onOpenWifi,
                    onOpenOta: onOpenOta,
                  ),
                ),
            ],
          )
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mainActions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final action = _mainActions[index];
                return _ActionButtonTile(
                  icon: action.icon,
                  label: action.label,
                  busy: controller.busy,
                  pending: controller.pendingActionLabel == action.label,
                  onPressed: () => action.invoke(
                    controller: controller,
                    onOpenWifi: onOpenWifi,
                    onOpenOta: onOpenOta,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _WifiSheetContent extends StatelessWidget {
  const _WifiSheetContent({
    required this.controller,
    required this.ssidController,
    required this.passwordController,
    required this.onBack,
  });

  final EmapiDemoController controller;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(title: '配网信息', subtitle: '输入 WiFi 后提交到打印机', onBack: onBack),
        const SizedBox(height: 10),
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
      ],
    );
  }
}

class _OtaSheetContent extends StatelessWidget {
  const _OtaSheetContent({
    required this.controller,
    required this.otaPathController,
    required this.otaFileLabel,
    required this.onPickOtaFile,
    required this.onBack,
  });

  final EmapiDemoController controller;
  final TextEditingController otaPathController;
  final String otaFileLabel;
  final Future<void> Function() onPickOtaFile;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle(
          title: 'OTA 升级',
          subtitle: controller.simulationMode
              ? '模拟模式可不选文件，直接使用内置模拟包'
              : '选择升级文件后再开始',
          onBack: onBack,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.description_outlined, color: theme.colorScheme.primary),
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
                  : () => controller.performOta(otaPathController.text),
              icon: const Icon(Icons.system_update_alt),
              label: const Text('开始 OTA 升级'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OtaProgressStrip(progressText: controller.otaProgress),
      ],
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.subtitle, this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            tooltip: '返回功能区',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class _ActionButtonTile extends StatelessWidget {
  const _ActionButtonTile({
    required this.icon,
    required this.label,
    required this.busy,
    required this.pending,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 134,
      child: FilledButton.tonal(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pending)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtaProgressStrip extends StatelessWidget {
  const _OtaProgressStrip({required this.progressText});

  final String progressText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.speed, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(progressText, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction(this.icon, this.label, this.invoke);

  final IconData icon;
  final String label;
  final void Function({
    required EmapiDemoController controller,
    required VoidCallback onOpenWifi,
    required VoidCallback onOpenOta,
  })
  invoke;
}

final _mainActions = [
  _SheetAction(Icons.power_settings_new, '休眠关机', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.sleepShutdown();
  }),
  _SheetAction(Icons.nfc, 'RFID UID', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryRfidUid();
  }),
  _SheetAction(Icons.badge_outlined, 'RFID 信息', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryRfidCardInfo();
  }),
  _SheetAction(Icons.straighten, '纸张长度', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryRfidPaperLength();
  }),
  _SheetAction(Icons.verified_user_outlined, 'RFID 失败处理', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.setRfidAuthFailureHandling(
      EmapiRfidAuthFailurePolicy.forbidPrint,
    );
  }),
  _SheetAction(Icons.router_outlined, '配网信息', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    onOpenWifi();
  }),
  _SheetAction(Icons.wifi_tethering, 'WIFI 状态', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryWifiConnectionState();
  }),
  _SheetAction(Icons.network_wifi, '热点信息', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryWifiHotspotInfo();
  }),
  _SheetAction(Icons.info_outline, '基本参数', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryDeviceInfo();
  }),
  _SheetAction(Icons.receipt_long, '打印状态', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    controller.queryPrintStatus();
  }),
  _SheetAction(Icons.system_update_alt, 'OTA 升级', ({
    required controller,
    required onOpenWifi,
    required onOpenOta,
  }) {
    onOpenOta();
  }),
];

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

class _LogList extends StatelessWidget {
  const _LogList({
    required this.emptyText,
    required this.entries,
    this.bottomPadding = 16,
  });

  final String emptyText;
  final List<String> entries;
  final double bottomPadding;

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
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
