part of '../../main.dart';

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
      length: 3,
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
                  Tab(text: '发送指令 ${controller.requestLogs.length}'),
                  Tab(text: '命令结果 ${controller.commandLogs.length}'),
                  Tab(text: '上报解析 ${controller.reportLogs.length}'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _LogList(
                      emptyText: '暂无发送指令',
                      entries: controller.requestLogs,
                      bottomPadding: 210,
                    ),
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
