import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

import '../models/demo_feedback.dart';
import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';
import '../protocol_registry.dart';
import 'esc_wan_controller.dart';
import 'inkjet_controller.dart';
import 'real_transport_helper.dart';
import 'sublimation_controller.dart';
import 'thermal_lan_controller.dart';

/// Top-level coordinator owning the global [DemoRunMode], active
/// [CloudPrinterFamily] tab, [ProtocolInspectorController],
/// [CloudPrinterRegistry], [ColorCoreEngine], and all 4 protocol controllers.
class DemoCoordinator extends ChangeNotifier {
  DemoCoordinator({ColorCoreEngine? colorCore})
    : colorCore = colorCore ?? SublimationColorCoreResolver.resolve(),
      inspector = ProtocolInspectorController(),
      feedback = DemoFeedbackCenter() {
    _createSession(runMode);
  }

  void _createSession(DemoRunMode mode) {
    registry = CloudPrinterRegistry();
    realTransportHelper = RealTransportHelper(inspector);
    escWan = EscWanController(
      inspector: inspector,
      feedback: feedback,
      modeGetter: () => mode,
    );
    thermalLan = ThermalLanController(
      inspector: inspector,
      feedback: feedback,
      modeGetter: () => mode,
      realTransportHelper: realTransportHelper,
    );
    sublimation = SublimationController(
      inspector: inspector,
      feedback: feedback,
      registry: registry,
      colorCore: colorCore,
      modeGetter: () => mode,
    );
    inkjet = InkjetController(
      inspector: inspector,
      feedback: feedback,
      registry: registry,
      colorCore: colorCore,
      modeGetter: () => mode,
    );

    final simulated = mode == DemoRunMode.simulation;
    registerDemoProtocols(
      registry,
      colorCore: colorCore,
      sublimationUdpTransport: simulated ? sublimation.simUdpTransport : null,
      sublimationConnector: simulated
          ? (printer, timeout) async => sublimation.simTcpDevice
          : null,
      allowInkjetLoopback: simulated,
      inkjetMdnsBrowser: simulated ? inkjet.simMdnsBrowser.browse : null,
      inkjetSoftApProbe: simulated ? inkjet.simSoftApProbe.call : null,
      inkjetNetworkBinder: simulated ? inkjet.simNetworkBinder : null,
      inkjetBleGattHooks: simulated
          ? inkjet.simBleDevice.buildGattHooks()
          : null,
    );
  }

  final ColorCoreEngine colorCore;
  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter feedback;
  late CloudPrinterRegistry registry;
  late RealTransportHelper realTransportHelper;

  late EscWanController escWan;
  late ThermalLanController thermalLan;
  late SublimationController sublimation;
  late InkjetController inkjet;

  DemoRunMode runMode = DemoRunMode.simulation;
  CloudPrinterFamily activeFamily = CloudPrinterFamily.escWanCloud;

  bool switching = false;
  bool _disposed = false;
  Future<void>? _closingSession;

  Future<void> setRunMode(DemoRunMode next) async {
    if (switching || _disposed || runMode == next) return;
    switching = true;
    notifyListeners();
    try {
      await (_closingSession = _closeSession());
      if (_disposed) return;
      _createSession(next);
      runMode = next;
      feedback.emitInfo('已切换至${next.label}');
    } finally {
      switching = false;
      _closingSession = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _closeSession() async {
    await Future.wait([
      escWan.dispose(),
      thermalLan.dispose(),
      sublimation.dispose(),
      inkjet.dispose(),
    ]);
    await realTransportHelper.dispose();
  }

  void setActiveFamily(CloudPrinterFamily family) {
    if (activeFamily == family) return;
    activeFamily = family;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await (_closingSession ?? _closeSession());
    inspector.dispose();
    feedback.dispose();
    super.dispose();
  }
}
