import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

/// Global operating mode for the unified 4-in-1 demo.
enum DemoRunMode { simulation, realDevice }

extension DemoRunModeUi on DemoRunMode {
  String get label {
    switch (this) {
      case DemoRunMode.simulation:
        return 'Simulation';
      case DemoRunMode.realDevice:
        return 'Real Device';
    }
  }

  String get description {
    switch (this) {
      case DemoRunMode.simulation:
        return 'In-process protocol loopback stubs (offline runnable)';
      case DemoRunMode.realDevice:
        return 'Physical BLE GATT, LAN UDP/mDNS/TCP, and WAN Cloud';
    }
  }
}

extension CloudPrinterFamilyUi on CloudPrinterFamily {
  String get tabLabel {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'ESC WAN';
      case CloudPrinterFamily.thermalLanStream:
        return 'Thermal LAN';
      case CloudPrinterFamily.sublimationRpc:
        return 'Sublimation';
      case CloudPrinterFamily.colorInkjetPjl:
        return 'Color Inkjet';
    }
  }

  String get title {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'ESC WAN Cloud';
      case CloudPrinterFamily.thermalLanStream:
        return 'Thermal LAN Stream';
      case CloudPrinterFamily.sublimationRpc:
        return 'Sublimation RPC';
      case CloudPrinterFamily.colorInkjetPjl:
        return 'Color Inkjet PJL';
    }
  }

  String get subtitle {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'psdk_fruit_esc TLV + psdk_cloud_wan REST/MQTT v5/OSS';
      case CloudPrinterFamily.thermalLanStream:
        return 'psdk_fruit_wifi AT/WLAN + psdk_network UDP 22368 & TCP :9100';
      case CloudPrinterFamily.sublimationRpc:
        return 'psdk_fruit_sublimation AT/Mesh, UDP 22368/1901 & 1B 44 RPC';
      case CloudPrinterFamily.colorInkjetPjl:
        return 'psdk_fruit_inkjet ACL, mDNS/SoftAP, XSL & XPL JBIG-1';
    }
  }

  IconData get icon {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return Icons.cloud_upload_outlined;
      case CloudPrinterFamily.thermalLanStream:
        return Icons.router_outlined;
      case CloudPrinterFamily.sublimationRpc:
        return Icons.badge_outlined;
      case CloudPrinterFamily.colorInkjetPjl:
        return Icons.palette_outlined;
    }
  }
}
