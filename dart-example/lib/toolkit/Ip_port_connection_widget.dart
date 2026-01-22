import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:printer_demo/toolkit/printer.dart';

import 'package:psdk_network/psdk_network.dart';

class IpPortConnectionWidget extends StatefulWidget {
  final Widget? ipTextField;
  final Widget? portTextField;
  final Widget? connectButton;
  final Widget? disconnectButton;
  const IpPortConnectionWidget({
    super.key,
    this.ipTextField,
    this.portTextField,
    this.connectButton,
    this.disconnectButton,
  });

  @override
  State<IpPortConnectionWidget> createState() =>
      _IpPortConnectionWidgetState();
}

class _IpPortConnectionWidgetState extends State<IpPortConnectionWidget> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.73');
  final TextEditingController _portController = TextEditingController(text: '9100');
  String _statusMessage = '';

  Future<void> _connect() async {
    String ip = _ipController.text;
    String portStr = _portController.text;

    if (ip.isEmpty || portStr.isEmpty) {
      setState(() {
        _statusMessage = '请输入有效的 IP 地址和端口号';
      });
      return;
    }
    try {
      int port = int.parse(portStr);
      Network network = Network();
      SmartDialog.showLoading(msg: '正在连接');
      var connectedDevice = await network.connect(ip, port);
      Printer().init(connectedDevice: connectedDevice);
      setState(() {
        _statusMessage = '连接成功！';
        SmartDialog.dismiss();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '连接失败: $e';
        SmartDialog.dismiss();
      });
    }
  }

  void _disconnect() {
    Printer().disconnect();
    setState(() {
      _statusMessage = '连接已断开';
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.ipTextField ??
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
              ),
            ),
        const SizedBox(height: 16),
        widget.portTextField ??
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '端口号',
              ),
            ),
        const SizedBox(height: 32),
        widget.connectButton ??
            ElevatedButton(
              onPressed: _connect,
              child: const Text('连接'),
            ),
        const SizedBox(height: 16),
        widget.disconnectButton ??
            ElevatedButton(
              onPressed: _disconnect,
              child: const Text('断开连接'),
            ),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

