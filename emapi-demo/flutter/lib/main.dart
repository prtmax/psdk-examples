import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

import 'src/bluetooth_printer_connector.dart';
import 'src/emapi_demo_controller.dart';
import 'src/entities/emapi_demo_log_entry.dart';

part 'src/pages/function_page.dart';
part 'src/pages/scan_page.dart';
part 'src/pages/settings_page.dart';
part 'src/widgets/common_widgets.dart';
part 'src/widgets/log_widgets.dart';
part 'src/widgets/operation_sheet.dart';

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
