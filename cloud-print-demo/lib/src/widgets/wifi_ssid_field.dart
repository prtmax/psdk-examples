import 'package:flutter/material.dart';

import '../controllers/real_transport_helper.dart';
import '../models/demo_mode.dart';

/// 真机自动读取 SSID，模拟模式保留示例，允许用户手动修改和重新读取。
class WifiSsidField extends StatefulWidget {
  const WifiSsidField({
    super.key,
    required this.controller,
    required this.helper,
    required this.mode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final RealTransportHelper helper;
  final DemoRunMode mode;
  final bool enabled;

  @override
  State<WifiSsidField> createState() => _WifiSsidFieldState();
}

class _WifiSsidFieldState extends State<WifiSsidField> {
  bool _loading = false;
  int _editRevision = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.mode == DemoRunMode.realDevice) _load();
  }

  Future<void> _load({bool replace = false}) async {
    if (_loading) return;
    final revision = _editRevision;
    setState(() {
      _loading = true;
      _message = null;
    });
    final name = await widget.helper.readCurrentWifiName();
    if (!mounted) return;
    if (name != null &&
        revision == _editRevision &&
        (replace || widget.controller.text.isEmpty)) {
      widget.controller.value = TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
      );
    }
    setState(() {
      _loading = false;
      _message = name == null ? widget.helper.wifiNameError : null;
    });
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    enabled: widget.enabled,
    onChanged: (_) => _editRevision++,
    decoration: InputDecoration(
      labelText: 'Wi-Fi 名称（SSID）',
      helperText: _message,
      helperMaxLines: 3,
      suffixIcon: widget.mode == DemoRunMode.simulation
          ? null
          : _loading
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              tooltip: '读取当前 Wi-Fi 名称',
              onPressed: widget.enabled ? () => _load(replace: true) : null,
              icon: const Icon(Icons.wifi_find),
            ),
    ),
  );
}
