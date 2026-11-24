import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart' as adapter;
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_network/psdk_network.dart';

import '../controllers/real_transport_helper.dart';
import '../models/demo_feedback.dart';
import '../models/demo_mode.dart';
import '../utils/local_image_service.dart';

void showDemoFeedbackSnackBar(
  BuildContext context, {
  required DemoFeedbackKind kind,
  required String message,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final clean = DemoFeedbackCenter.formatMessage(message);
  final Color bgColor;
  final IconData icon;
  final Duration duration;
  switch (kind) {
    case DemoFeedbackKind.success:
      bgColor = const Color(0xFF1E5E36);
      icon = Icons.check_circle_outline;
      duration = const Duration(seconds: 3);
    case DemoFeedbackKind.error:
      bgColor = const Color(0xFFB4473D);
      icon = Icons.error_outline;
      duration = const Duration(seconds: 4);
    case DemoFeedbackKind.info:
      bgColor = const Color(0xFF254B52);
      icon = Icons.info_outline;
      duration = const Duration(seconds: 3);
  }
  messenger
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor,
        duration: duration,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        content: Row(
          key: const Key('demo_feedback_snackbar'),
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                clean,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

class ActionStatusBanner extends StatelessWidget {
  const ActionStatusBanner({
    super.key,
    required this.message,
    this.busy = false,
    this.isError = false,
  });

  final String message;
  final bool busy;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bgColor;
    final Color borderColor;
    final Color fgColor;
    if (isError) {
      bgColor = scheme.errorContainer.withValues(alpha: 0.45);
      borderColor = scheme.error.withValues(alpha: 0.45);
      fgColor = scheme.error;
    } else if (busy) {
      bgColor = scheme.secondaryContainer.withValues(alpha: 0.5);
      borderColor = scheme.primary.withValues(alpha: 0.35);
      fgColor = scheme.primary;
    } else {
      bgColor = const Color(0xFFEAF4EE);
      borderColor = const Color(0xFF2E7D32).withValues(alpha: 0.35);
      fgColor = const Color(0xFF1E5E36);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 16,
                color: fgColor,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    required this.statusMessage,
    this.busy = false,
  });

  final CloudPrinterFamily family;
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
                          if (context.mounted) {
                            showDemoFeedbackSnackBar(
                              context,
                              kind: DemoFeedbackKind.info,
                              message: '已断开蓝牙连接',
                            );
                            onDisconnected();
                          }
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
      final bleName =
          connection.deviceName() ?? connection.deviceMac() ?? '蓝牙打印机';
      showDemoFeedbackSnackBar(
        context,
        kind: DemoFeedbackKind.success,
        message: '已连接蓝牙：$bleName',
      );
      onConnected(connection);
    } else if (helper.lastError != null) {
      showDemoFeedbackSnackBar(
        context,
        kind: DemoFeedbackKind.error,
        message: helper.lastError!,
      );
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

class DirectApWifiPanel extends StatefulWidget {
  const DirectApWifiPanel({
    super.key,
    required this.title,
    required this.ssid,
    required this.password,
    required this.hostOverride,
    required this.formRevision,
    required this.connectedInfo,
    required this.busy,
    required this.onQueryBle,
    required this.onConnectDirect,
    required this.onQueryBleAndConnect,
    required this.onDisconnectDirect,
  });

  final String title;
  final String ssid;
  final String password;
  final String hostOverride;
  final int formRevision;
  final PrinterWifiConnectionInfo? connectedInfo;
  final bool busy;
  final Future<Object?> Function() onQueryBle;
  final Future<void> Function(String ssid, String password, String host)
  onConnectDirect;
  final Future<void> Function(String host) onQueryBleAndConnect;
  final Future<void> Function() onDisconnectDirect;

  @override
  State<DirectApWifiPanel> createState() => _DirectApWifiPanelState();
}

class _DirectApWifiPanelState extends State<DirectApWifiPanel> {
  late final TextEditingController _ssidCtrl = TextEditingController(
    text: widget.ssid,
  );
  late final TextEditingController _passwordCtrl = TextEditingController(
    text: widget.password,
  );
  late final TextEditingController _hostCtrl = TextEditingController(
    text: widget.hostOverride,
  );
  bool _obscurePassword = true;

  @override
  void didUpdateWidget(covariant DirectApWifiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formRevision != widget.formRevision) {
      if (_ssidCtrl.text != widget.ssid) {
        _ssidCtrl.text = widget.ssid;
      }
      if (_passwordCtrl.text != widget.password) {
        _passwordCtrl.text = widget.password;
      }
      if (_hostCtrl.text != widget.hostOverride) {
        _hostCtrl.text = widget.hostOverride;
      }
    }
  }

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passwordCtrl.dispose();
    _hostCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.connectedInfo;
    final connected = info != null;
    final scheme = Theme.of(context).colorScheme;
    return DemoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: widget.title,
            trailing: StatusPill(
              label: connected ? '已连热点: ${info.ssid}' : '未直连',
              color: connected ? const Color(0xFF2E7D32) : scheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '将手机直接连接到打印机自带 Wi-Fi 后下发打印。可手动输入热点名/密码，或先连接蓝牙读取设备热点信息。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('ap_ssid_field'),
            controller: _ssidCtrl,
            enabled: !widget.busy,
            decoration: const InputDecoration(
              labelText: '打印机热点 Wi-Fi 名称（SSID）',
              hintText: '例如 Z11_FAF8 或 H100-84D242',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('ap_password_field'),
            controller: _passwordCtrl,
            enabled: !widget.busy,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '打印机热点密码（开放热点可留空）',
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('ap_host_field'),
            controller: _hostCtrl,
            enabled: !widget.busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '热点打印机 IP（可选，默认自动探测网关/192.168.4.1）',
              hintText: '如 192.168.4.1',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('ap_query_ble_btn'),
                onPressed: widget.busy ? null : () => widget.onQueryBle(),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('蓝牙读取热点'),
              ),
              FilledButton.icon(
                key: const Key('ap_connect_wifi_btn'),
                onPressed: widget.busy
                    ? null
                    : () => widget.onConnectDirect(
                        _ssidCtrl.text,
                        _passwordCtrl.text,
                        _hostCtrl.text,
                      ),
                icon: const Icon(Icons.wifi),
                label: const Text('连接打印机 Wi-Fi'),
              ),
              FilledButton.tonalIcon(
                key: const Key('ap_query_and_connect_btn'),
                onPressed: widget.busy
                    ? null
                    : () => widget.onQueryBleAndConnect(_hostCtrl.text),
                icon: const Icon(Icons.flash_on),
                label: const Text('蓝牙查热点并直连'),
              ),
              if (connected)
                OutlinedButton.icon(
                  key: const Key('ap_disconnect_btn'),
                  onPressed: widget.busy
                      ? null
                      : () => widget.onDisconnectDirect(),
                  icon: const Icon(Icons.link_off),
                  label: const Text('断开热点'),
                ),
            ],
          ),
          if (connected && (info.address != null || info.gateway != null)) ...[
            const SizedBox(height: 8),
            Text(
              '本机 IP：${info.address ?? "-"} · 网关：${info.gateway ?? "-"} · 网卡：${info.interfaceName ?? "-"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class LocalImagePrintCard extends StatelessWidget {
  const LocalImagePrintCard({
    super.key,
    required this.keyPrefix,
    required this.selectedImage,
    required this.busy,
    required this.canPrint,
    required this.hintText,
    required this.printButtonLabel,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPrintImage,
  });

  final String keyPrefix;
  final PickedLocalImage? selectedImage;
  final bool busy;
  final bool canPrint;
  final String hintText;
  final String printButtonLabel;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPrintImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final img = selectedImage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '本地图片打印',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (img != null)
                const StatusPill(label: '已选', color: Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 8),
          if (img != null)
            Container(
              key: Key('${keyPrefix}_local_image_preview'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.memory(
                        img.previewBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          img.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${img.width} × ${img.height} px',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('${keyPrefix}_clear_local_image_btn'),
                    tooltip: '清除图片',
                    onPressed: busy ? null : onClearImage,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            )
          else
            Text(hintText, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: Key('${keyPrefix}_pick_local_image_btn'),
                onPressed: busy ? null : onPickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(img == null ? '选择本地图片' : '更换图片'),
              ),
              FilledButton.tonalIcon(
                key: Key('${keyPrefix}_print_local_image_btn'),
                onPressed: (busy || !canPrint || img == null)
                    ? null
                    : onPrintImage,
                icon: const Icon(Icons.print_outlined),
                label: Text(printButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
