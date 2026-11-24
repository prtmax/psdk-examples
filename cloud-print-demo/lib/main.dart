import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import 'src/controllers/demo_coordinator.dart';
import 'src/models/demo_mode.dart';
import 'src/widgets/common_widgets.dart';
import 'src/widgets/esc_wan_tab.dart';
import 'src/widgets/inkjet_tab.dart';
import 'src/widgets/protocol_inspector_drawer.dart';
import 'src/widgets/sublimation_tab.dart';
import 'src/widgets/thermal_lan_tab.dart';

void main() {
  runApp(const CloudPrintDemoApp());
}

class CloudPrintDemoApp extends StatelessWidget {
  const CloudPrintDemoApp({
    super.key,
    this.coordinator,
    @visibleForTesting this.disposeCoordinatorOnUnmount = false,
  });

  final DemoCoordinator? coordinator;
  final bool disposeCoordinatorOnUnmount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: '云打印测试',
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
      home: CloudPrintDemoPage(
        coordinator: coordinator,
        disposeCoordinatorOnUnmount: disposeCoordinatorOnUnmount,
      ),
    );
  }
}

class CloudPrintDemoPage extends StatefulWidget {
  const CloudPrintDemoPage({
    super.key,
    this.coordinator,
    @visibleForTesting this.disposeCoordinatorOnUnmount = false,
  });

  final DemoCoordinator? coordinator;
  final bool disposeCoordinatorOnUnmount;

  @override
  State<CloudPrintDemoPage> createState() => _CloudPrintDemoPageState();
}

class _CloudPrintDemoPageState extends State<CloudPrintDemoPage>
    with SingleTickerProviderStateMixin {
  late final DemoCoordinator _coordinator;
  late final bool _ownsCoordinator;
  late final TabController _tabController;
  int _lastFeedbackId = 0;

  void _onFeedbackChanged() {
    final event = _coordinator.feedback.latest;
    if (event == null || event.id <= _lastFeedbackId) return;
    _lastFeedbackId = event.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDemoFeedbackSnackBar(
        context,
        kind: event.kind,
        message: event.message,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _ownsCoordinator = widget.coordinator == null;
    _coordinator = widget.coordinator ?? DemoCoordinator();
    _lastFeedbackId = _coordinator.feedback.latest?.id ?? 0;
    _coordinator.feedback.addListener(_onFeedbackChanged);
    _tabController = TabController(
      length: CloudPrinterFamily.values.length,
      vsync: this,
      initialIndex: CloudPrinterFamily.values.indexOf(
        _coordinator.activeFamily,
      ),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _coordinator.setActiveFamily(
          CloudPrinterFamily.values[_tabController.index],
        );
      }
    });
  }

  @override
  void dispose() {
    _coordinator.feedback.removeListener(_onFeedbackChanged);
    _tabController.dispose();
    if (_ownsCoordinator || widget.disposeCoordinatorOnUnmount) {
      _coordinator.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _coordinator,
        _coordinator.inspector,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('打印测试'),
            actions: [
              IconButton(
                key: const Key('open_protocol_inspector'),
                tooltip: '协议日志',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProtocolInspectorPage(
                        inspector: _coordinator.inspector,
                      ),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: _coordinator.inspector.count > 0,
                  label: Text('${_coordinator.inspector.count}'),
                  child: const Icon(Icons.terminal_outlined),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                for (final family in CloudPrinterFamily.values)
                  Tab(
                    key: Key('tab_${family.name}'),
                    icon: Icon(family.icon, size: 18),
                    text: family.tabLabel,
                  ),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                EscWanTab(
                  controller: _coordinator.escWan,
                  realTransportHelper: _coordinator.realTransportHelper,
                ),
                ThermalLanTab(
                  controller: _coordinator.thermalLan,
                  realTransportHelper: _coordinator.realTransportHelper,
                ),
                SublimationTab(
                  controller: _coordinator.sublimation,
                  realTransportHelper: _coordinator.realTransportHelper,
                ),
                InkjetTab(
                  controller: _coordinator.inkjet,
                  realTransportHelper: _coordinator.realTransportHelper,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
