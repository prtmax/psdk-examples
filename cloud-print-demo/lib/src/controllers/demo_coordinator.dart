import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

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
      registry = CloudPrinterRegistry(),
      realTransportHelper = RealTransportHelper() {
    escWan = EscWanController(inspector: inspector, modeGetter: () => runMode);
    thermalLan = ThermalLanController(
      inspector: inspector,
      modeGetter: () => runMode,
      realTransportHelper: realTransportHelper,
    );
    sublimation = SublimationController(
      inspector: inspector,
      registry: registry,
      colorCore: this.colorCore,
      modeGetter: () => runMode,
    );
    inkjet = InkjetController(
      inspector: inspector,
      registry: registry,
      colorCore: this.colorCore,
      modeGetter: () => runMode,
    );

    registerDemoProtocols(
      registry,
      colorCore: this.colorCore,
      sublimationUdpTransport: sublimation.simUdpTransport,
      sublimationConnector: (printer, timeout) async =>
          sublimation.simTcpDevice,
      inkjetMdnsBrowser: inkjet.simMdnsBrowser.browse,
      inkjetSoftApProbe: inkjet.simSoftApProbe.call,
      inkjetNetworkBinder: inkjet.simNetworkBinder,
      inkjetBleGattHooks: inkjet.simBleDevice.buildGattHooks(),
    );
  }

  final ColorCoreEngine colorCore;
  final ProtocolInspectorController inspector;
  final CloudPrinterRegistry registry;
  final RealTransportHelper realTransportHelper;

  late final EscWanController escWan;
  late final ThermalLanController thermalLan;
  late final SublimationController sublimation;
  late final InkjetController inkjet;

  DemoRunMode runMode = DemoRunMode.simulation;
  CloudPrinterFamily activeFamily = CloudPrinterFamily.escWanCloud;

  void setRunMode(DemoRunMode next) {
    if (runMode == next) return;
    runMode = next;
    notifyListeners();
  }

  void setActiveFamily(CloudPrinterFamily family) {
    if (activeFamily == family) return;
    activeFamily = family;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await escWan.dispose();
    await thermalLan.dispose();
    await sublimation.dispose();
    await inkjet.dispose();
    await realTransportHelper.dispose();
    inspector.dispose();
    super.dispose();
  }
}
