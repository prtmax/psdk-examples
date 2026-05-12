part of '../../main.dart';

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
    final size = sheetController.size;
    if (!expanded && size >= 0.42) {
      setState(() {
        expanded = true;
      });
    } else if (expanded && size <= 0.28) {
      setState(() {
        expanded = false;
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
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final action in _mainActions)
                    _ActionButtonTile(
                      width: tileWidth,
                      compact: true,
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
              );
            },
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
                  width: 134,
                  compact: false,
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
    required this.width,
    required this.compact,
    required this.icon,
    required this.label,
    required this.busy,
    required this.pending,
    required this.onPressed,
  });

  final double width;
  final bool compact;
  final IconData icon;
  final String label;
  final bool busy;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: compact ? 78 : 104,
      child: FilledButton.tonal(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pending)
              SizedBox.square(
                dimension: compact ? 18 : 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: compact ? 19 : 22),
            SizedBox(height: compact ? 6 : 8),
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
