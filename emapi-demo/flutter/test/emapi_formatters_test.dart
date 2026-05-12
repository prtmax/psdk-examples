import 'package:emapi_demo/src/emapi_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psdk_fruit_emapi/psdk_fruit_emapi.dart';

void main() {
  test('formatWifiConnectionState_returnsReadableChineseText', () {
    expect(
      formatWifiConnectionState(EmapiWifiConnectionState.iotConnected),
      'WIFI 连接状态：已连接 IoT',
    );
    expect(
      formatWifiConnectionState(EmapiWifiConnectionState.unknown),
      'WIFI 连接状态：未知',
    );
  });

  test('formatPrintStatus_displaysPublicSdkFieldsOnly', () {
    const status = EmapiPrintStatus(
      paperStatus: 1,
      coverStatus: 0,
      lowBattery: 0,
      overheat: 1,
      batteryPercent: 86,
      batteryVoltage: 7400,
      tphTemperature: -3,
    );

    expect(formatPrintStatus(status), contains('纸张状态：1'));
    expect(formatPrintStatus(status), contains('电量百分比：86%'));
    expect(formatPrintStatus(status), contains('TPH 温度：-3'));
  });

  test('otaProgressText_displaysBytesTotalPercentAndLatestStatus', () {
    expect(
      otaProgressText(sentBytes: 128, totalBytes: 512, latestStatus: '升级中'),
      'OTA 进度：128 / 512 bytes (25.0%)\n最新升级状态：升级中',
    );
  });

  test('calculateOtaChunkSize_usesConservativeFrameMtuCapacity', () {
    expect(calculateOtaChunkSize(mtu: 512), 492);
    expect(calculateOtaChunkSize(mtu: 20), 1);
  });
}
