import 'package:flutter/material.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

/// Global operating mode for the unified 4-in-1 demo.
enum DemoRunMode { simulation, realDevice }

extension DemoRunModeUi on DemoRunMode {
  String get label {
    switch (this) {
      case DemoRunMode.simulation:
        return '模拟模式';
      case DemoRunMode.realDevice:
        return '真机模式';
    }
  }

  String get description {
    switch (this) {
      case DemoRunMode.simulation:
        return '进程内协议模拟，可离线运行';
      case DemoRunMode.realDevice:
        return '真机蓝牙、局域网及云端连接';
    }
  }
}

extension CloudPrinterFamilyUi on CloudPrinterFamily {
  String get tabLabel {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'ESC 云端';
      case CloudPrinterFamily.thermalLanStream:
        return '热敏局域网';
      case CloudPrinterFamily.sublimationRpc:
        return '热升华';
      case CloudPrinterFamily.colorInkjetPjl:
        return '彩色喷墨';
    }
  }

  String get title {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'ESC 云打印';
      case CloudPrinterFamily.thermalLanStream:
        return '热敏局域网打印';
      case CloudPrinterFamily.sublimationRpc:
        return '热升华 RPC';
      case CloudPrinterFamily.colorInkjetPjl:
        return '彩色喷墨 PJL';
    }
  }

  String get subtitle {
    switch (this) {
      case CloudPrinterFamily.escWanCloud:
        return 'psdk_fruit_esc TLV + psdk_cloud_wan REST/MQTT v5/OSS';
      case CloudPrinterFamily.thermalLanStream:
        return '共用蓝牙 Wi-Fi 配网、UDP 22368 发现；TCP 9100 打印';
      case CloudPrinterFamily.sublimationRpc:
        return '共用蓝牙 Wi-Fi 配网、UDP 22368 发现；RPC 卡片打印';
      case CloudPrinterFamily.colorInkjetPjl:
        return 'psdk_fruit_inkjet ACL, UDP 22368 / 4201 / mDNS, XSL & XPL JBIG-1';
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
