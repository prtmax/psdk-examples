import 'package:flutter/foundation.dart';
import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';
import 'package:psdk_network/psdk_network.dart';

import '../models/demo_feedback.dart';
import '../models/protocol_inspector.dart';
import '../protocol_registry.dart';
import '../utils/local_image_service.dart';
import 'esc_wan_controller.dart';
import 'inkjet_controller.dart';
import 'real_transport_helper.dart';
import 'sublimation_controller.dart';
import 'thermal_lan_controller.dart';

/// Top-level coordinator owning the active [CloudPrinterFamily] tab,
/// [ProtocolInspectorController], [CloudPrinterRegistry], [ColorCoreEngine],
/// and all 4 real-device protocol controllers.
class DemoCoordinator extends ChangeNotifier {
  DemoCoordinator({
    ColorCoreEngine? colorCore,
    LocalImagePickerService? localImagePicker,
    ProtocolInspectorController? inspector,
    DemoFeedbackCenter? feedback,
    PrinterWifiSession? printerWifiSession,
    RealTransportHelper? realTransportHelper,
    EscWanController? escWan,
    ThermalLanController? thermalLan,
    SublimationController? sublimation,
    InkjetController? inkjet,
    CloudPrinterRegistry? registry,
  }) : colorCore = colorCore ?? SublimationColorCoreResolver.resolve(),
       localImagePicker = localImagePicker ?? const LocalImagePickerService(),
       inspector = inspector ?? ProtocolInspectorController(),
       feedback = feedback ?? DemoFeedbackCenter(),
       registry = registry ?? CloudPrinterRegistry(),
       printerWifiSession = printerWifiSession ?? PrinterWifiSession() {
    this.realTransportHelper =
        realTransportHelper ?? RealTransportHelper(this.inspector);
    this.escWan =
        escWan ??
        EscWanController(
          inspector: this.inspector,
          feedback: this.feedback,
          localImagePicker: this.localImagePicker,
        );
    this.thermalLan =
        thermalLan ??
        ThermalLanController(
          inspector: this.inspector,
          feedback: this.feedback,
          localImagePicker: this.localImagePicker,
          realTransportHelper: this.realTransportHelper,
        );
    this.sublimation =
        sublimation ??
        SublimationController(
          inspector: this.inspector,
          feedback: this.feedback,
          registry: this.registry,
          colorCore: this.colorCore,
          printerWifiSession: this.printerWifiSession,
          localImagePicker: this.localImagePicker,
        );
    this.inkjet =
        inkjet ??
        InkjetController(
          inspector: this.inspector,
          feedback: this.feedback,
          registry: this.registry,
          colorCore: this.colorCore,
          printerWifiSession: this.printerWifiSession,
          localImagePicker: this.localImagePicker,
        );

    registerDemoProtocols(
      this.registry,
      colorCore: this.colorCore,
      allowInkjetLoopback: false,
    );
  }

  final ColorCoreEngine colorCore;
  final LocalImagePickerService localImagePicker;
  final ProtocolInspectorController inspector;
  final DemoFeedbackCenter feedback;
  final CloudPrinterRegistry registry;
  final PrinterWifiSession printerWifiSession;
  late final RealTransportHelper realTransportHelper;

  late final EscWanController escWan;
  late final ThermalLanController thermalLan;
  late final SublimationController sublimation;
  late final InkjetController inkjet;

  CloudPrinterFamily activeFamily = CloudPrinterFamily.escWanCloud;
  bool _disposed = false;

  void setActiveFamily(CloudPrinterFamily family) {
    if (activeFamily == family) return;
    activeFamily = family;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait([
      escWan.dispose(),
      thermalLan.dispose(),
      sublimation.dispose(),
      inkjet.dispose(),
    ]);
    await printerWifiSession.disconnectPrinterWifi().catchError((_) {});
    await realTransportHelper.dispose();
    inspector.dispose();
    feedback.dispose();
    super.dispose();
  }
}
