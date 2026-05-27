import 'dart:async';

import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

String formatDeviceInfo(EmapiPrinterInfo info) {
  return [
    '打印机基本参数',
    '设备类型：${_value(info.deviceType)}',
    '设备型号：${_value(info.deviceModel)}',
    '品牌：${_value(info.brand)}',
    '序列号：${_value(info.serialNumber)}',
    '硬件版本：${_value(info.hardwareVersion)}',
    '软件版本：${_value(info.softwareVersion)}',
    'Boot 版本：${_value(info.bootVersion)}',
    'EMAPI MTU：${_value(info.mtu)}',
  ].join('\n');
}

String formatRfidCardInfo(EmapiRfidCardInfo info) {
  return [
    'RFID 卡信息',
    '纸张型号：${_value(info.paperModel)}',
    '纸张长度：${_value(info.paperLength)}',
    '纸张宽度：${_value(info.paperWidth)}',
    '纸张颜色：${_value(info.paperColor)}',
    '纸张物料号：${_value(info.paperMaterialNumber)}',
  ].join('\n');
}

String formatWifiConnectionState(EmapiWifiConnectionState state) {
  final text = switch (state) {
    EmapiWifiConnectionState.notConnected => '未连接',
    EmapiWifiConnectionState.hotspotConnected => '已连接热点',
    EmapiWifiConnectionState.iotConnected => '已连接 IoT',
    EmapiWifiConnectionState.unknown => '未知',
  };
  return 'WIFI 连接状态：$text';
}

String formatWifiHotspotInfo(EmapiWifiHotspotInfo info) {
  return [
    'WIFI 模块热点相关信息',
    'SSID：${_value(info.ssid)}',
    'RSSI：${_value(info.rssi)}',
    'IP：${_value(info.ip)}',
    '端口：${_value(info.port)}',
  ].join('\n');
}

String formatPrintStatus(EmapiPrintStatus status) {
  // TODO(EMAPI hardware): print status may have tags beyond 0x01..0x07. Display only public SDK fields until those tags are confirmed.
  return [
    '打印状态',
    '纸张状态：${_value(status.paperStatus)}',
    '开盖状态：${_value(status.coverStatus)}',
    '低电量：${_value(status.lowBattery)}',
    '过热：${_value(status.overheat)}',
    '电量百分比：${_percent(status.batteryPercent)}',
    '电池电压：${_voltage(status.batteryVoltage)}',
    'TPH 温度：${_value(status.tphTemperature)}',
  ].join('\n');
}

String formatReport(EmapiReport report) {
  return switch (report) {
    EmapiPrintResultReport(:final result) => '打印结果上报：$result',
    EmapiPrinterStatusReport(
      :final paperStatus,
      :final coverStatus,
      :final batteryState,
      :final overheat,
      :final nfcPaperRecognition,
    ) =>
      [
        '打印机状态上报',
        '纸张状态：${_value(paperStatus)}',
        '开盖状态：${_value(coverStatus)}',
        '电池状态：${_value(batteryState)}',
        '过热：${_value(overheat)}',
        'NFC 纸张识别：${_value(nfcPaperRecognition)}',
      ].join('\n'),
    EmapiFlowControlReport(:final isBusy) => '流控上报：${isBusy ? '忙' : '空闲'}',
    EmapiUpgradeStatusReport(:final status) => '升级状态上报：$status',
    EmapiBluetoothConnectionReport(:final state) => '蓝牙连接上报：$state',
    EmapiWifiConfigStatusReport(:final ssid, :final state) =>
      'WIFI 配网上报：SSID=${_value(ssid)}，状态=${_value(state)}',
    EmapiUnknownReport() => '未知上报：${report.command}',
    _ => '未识别上报：${report.command}',
  };
}

String formatError(Object error) {
  if (error is EmapiProtocolException) {
    return 'EMAPI 协议错误：${error.message}';
  }
  if (error is TimeoutException) {
    return '请求超时：${error.message ?? '设备未在限定时间内响应'}';
  }
  return '连接或执行错误：$error';
}

String otaProgressText({
  required int sentBytes,
  required int totalBytes,
  required String? latestStatus,
}) {
  final percent = totalBytes <= 0 ? 0.0 : sentBytes / totalBytes * 100;
  final bounded = percent.clamp(0, 100).toStringAsFixed(1);
  return 'OTA 进度：$sentBytes / $totalBytes bytes ($bounded%)\n'
      '最新升级状态：${latestStatus ?? '暂无'}';
}

int calculateOtaChunkSize({int? mtu, int fallbackMtu = 512}) {
  return fileTransferPayloadCapacity(mtu: mtu ?? fallbackMtu);
}

String _value(Object? value) {
  if (value == null) {
    return '未知';
  }
  if (value is String && value.isEmpty) {
    return '未知';
  }
  return '$value';
}

String _percent(int? value) {
  return value == null ? '未知' : '$value%';
}

String _voltage(int? value) {
  return value == null ? '未知' : '$value mV';
}
