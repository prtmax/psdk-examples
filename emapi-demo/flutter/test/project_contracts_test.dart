import 'dart:async';
import 'dart:io';

import 'package:emapi_demo/src/bluetooth_printer_connector.dart';
import 'package:emapi_demo/src/emapi_demo_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

String readProjectFile(String path) {
  return File(path).readAsStringSync();
}

void main() {
  test('readme_documentsLocalPsdkBootstrapContract', () {
    final readme = readProjectFile('README.md');

    expect(readme, contains('/same-parent/psdk'));
    expect(readme, contains('../../../psdk'));
    expect(readme, contains('adjust the path dependencies'));
  });

  test('androidManifest_scopesBluetoothPermissionsByApiLevel', () {
    final manifest = readProjectFile(
      'android/app/src/main/AndroidManifest.xml',
    );

    expect(
      manifest,
      contains(
        'android:name="android.permission.ACCESS_FINE_LOCATION"\n'
        '        android:maxSdkVersion="30"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="android.permission.BLUETOOTH"\n'
        '        android:maxSdkVersion="30"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="android.permission.BLUETOOTH_ADMIN"\n'
        '        android:maxSdkVersion="30"',
      ),
    );
    expect(manifest, contains('android.permission.BLUETOOTH_SCAN'));
    expect(
      manifest,
      contains('android:usesPermissionFlags="neverForLocation"'),
    );
    expect(manifest, contains('android.permission.BLUETOOTH_CONNECT'));
  });

  test('androidBuild_usesProjectOwnedIdentifierAndNoDebugReleaseSigning', () {
    final gradle = readProjectFile('android/app/build.gradle.kts');

    expect(gradle, contains('namespace = "com.psdk.examples.emapi_demo"'));
    expect(gradle, contains('applicationId = "com.psdk.examples.emapi_demo"'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(
      gradle,
      contains('Release publishing signing is intentionally not configured'),
    );
  });

  test('androidManifest_omitsBinaryLauncherIcon', () {
    final manifest = readProjectFile(
      'android/app/src/main/AndroidManifest.xml',
    );

    expect(manifest, isNot(contains('@mipmap/ic_launcher')));
    expect(manifest, isNot(contains('android:icon')));
  });

  test('main_passesControllersAndHandlesAsyncInitErrors', () {
    final main = readProjectFile('lib/main.dart');
    final controller = readProjectFile('lib/src/emapi_demo_controller.dart');

    expect(main, isNot(contains('findAncestorStateOfType')));
    expect(main, contains('ssidController: ssidController'));
    expect(main, contains('passwordController: passwordController'));
    expect(main, contains('otaPathController: otaPathController'));
    expect(controller, contains('初始化失败'));
  });

  test('main_exposesSettingsAndSimulationModeUi', () {
    final main = readProjectFile('lib/main.dart');

    expect(main, contains('Icons.tune'));
    expect(main, contains('SettingsPage'));
    expect(main, contains('SwitchListTile'));
    expect(main, contains('模拟模式'));
    expect(main, contains('生成模拟蓝牙设备'));
  });

  test('main_exposesInlineWifiConfigSubmitAction', () {
    final main = readProjectFile('lib/main.dart');

    expect(main, contains('提交配网信息'));
    expect(main, contains('Icons.send_to_mobile'));
    expect(main, contains('controller.setWifiConfig'));
  });

  test('main_exposesOtaFilePickerAndConfirmAction', () {
    final main = readProjectFile('lib/main.dart');
    final pubspec = readProjectFile('pubspec.yaml');

    expect(pubspec, contains('file_picker:'));
    expect(main, contains('FilePicker.pickFiles'));
    expect(main, contains('选择 OTA 文件'));
    expect(main, contains('开始 OTA 升级'));
    expect(main, contains('未选择，模拟模式可直接开始'));
  });

  test('main_usesRecordsAsPrimaryViewAndMovesActionsToSheet', () {
    final main = readProjectFile('lib/main.dart');

    expect(main, contains('DraggableScrollableSheet'));
    expect(main, contains('_OperationSheet'));
    expect(main, contains('_FunctionSheetMode'));
    expect(main, contains('TabBarView'));
    expect(main, contains('命令结果'));
    expect(main, contains('上报解析'));
    expect(main, contains('功能区'));
    expect(main, contains('左右滑动选择操作，上拉切换为多行'));
    expect(main, contains('已展开，多行显示全部操作'));
    expect(main, contains('DraggableScrollableController'));
    expect(main, contains('LayoutBuilder'));
    expect(main, contains('(constraints.maxWidth - spacing * 2) / 3'));
    expect(main, contains('size >= 0.42'));
    expect(main, contains('size <= 0.28'));
    expect(main, contains('暂无命令结果'));
    expect(main, contains('暂无上报解析'));
  });

  test('main_onlyShowsOtaProgressInsideOtaSheet', () {
    final main = readProjectFile('lib/main.dart');

    expect(main, contains('_OtaSheetContent'));
    expect(main.split('_OtaProgressStrip(progressText').length - 1, 1);
  });

  test('main_opensWifiAndOtaFormsInsideOperationSheet', () {
    final main = readProjectFile('lib/main.dart');

    expect(main, contains('_WifiSheetContent'));
    expect(main, contains('_OtaSheetContent'));
    expect(main, contains('返回功能区'));
    expect(main, contains('onOpenWifi'));
    expect(main, contains('onOpenOta'));
  });

  test('bluetoothConnector_checksPermissionStatusesBeforeDiscovery', () {
    final connector = readProjectFile(
      'lib/src/bluetooth_printer_connector.dart',
    );

    expect(connector, contains('Map<Permission, PermissionStatus>'));
    expect(connector, contains('permissionLabel'));
    expect(connector, contains('isPermanentlyDenied'));
    expect(connector, contains('startDiscovery'));
  });

  test('bluetoothConnector_selectsAndroidPermissionsBySdkLevel', () {
    expect(androidBluetoothPermissionsForSdk(31), [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ]);
    expect(androidBluetoothPermissionsForSdk(30), [
      Permission.location,
      Permission.bluetooth,
    ]);
  });

  test('controller_startScanFailureResetsScanning', () async {
    final controller = EmapiDemoController(
      connector: _FailingScanConnector(StateError('permissions denied')),
    );

    await controller.init();
    await controller.startScan();

    expect(controller.scanning, isFalse);
    expect(
      controller.commandLogs.first.message,
      contains('permissions denied'),
    );
  });

  test(
    'controller_simulationModeGeneratesAndConnectsSimulatedDevice',
    () async {
      final controller = EmapiDemoController(
        connector: _FailingScanConnector(StateError('unexpected real scan')),
      );
      addTearDown(controller.dispose);

      await controller.init();
      await controller.setSimulationMode(true);
      await controller.startScan();

      expect(controller.bluetoothEnabled, isTrue);
      expect(controller.scanning, isFalse);
      expect(controller.devices, hasLength(1));
      expect(controller.devices.single.simulated, isTrue);

      await controller.connect(controller.devices.single);

      expect(controller.connected, isTrue);
      expect(controller.connectedDeviceName, 'EMAPI 模拟打印机');
      expect(controller.reportLogs.first.message, contains('蓝牙连接上报'));
      expect(controller.reportLogs.first.bytes, isNotNull);
    },
  );

  test('controller_simulationModeReturnsQueryAndOtaResults', () async {
    final controller = EmapiDemoController(
      connector: _FailingScanConnector(StateError('unexpected real scan')),
    );
    addTearDown(controller.dispose);

    await controller.init();
    await controller.setSimulationMode(true);
    await controller.startScan();
    await controller.connect(controller.devices.single);

    await controller.queryDeviceInfo();

    expect(controller.commandLogs.first.message, contains('EMAPI-SIM-01'));
    expect(controller.requestLogs.first.title, '查询打印机基本参数');
    expect(controller.requestLogs.first.bytes, isNotNull);
    expect(controller.knownMtu, 512);

    await controller.performOta('');

    expect(controller.otaTotalBytes, 2048);
    expect(controller.otaSentBytes, 2048);
    expect(controller.commandLogs.first.message, contains('模拟模式：OTA 升级命令已完成'));
    expect(controller.reportLogs.first.message, contains('升级状态上报'));
    expect(controller.requestLogs.first.title, 'OTA 升级文件');
    expect(controller.requestLogs.first.bytes, hasLength(2048));
  });
}

class _FailingScanConnector extends BluetoothPrinterConnector {
  _FailingScanConnector(this.error);

  final Object error;
  final _devicesController =
      StreamController<DiscoveredPrinterDevice>.broadcast();

  @override
  Stream<DiscoveredPrinterDevice> get discoveredDevices {
    return _devicesController.stream;
  }

  @override
  Future<bool> bluetoothIsEnabled() async {
    return true;
  }

  @override
  Future<void> startScan() async {
    throw error;
  }

  @override
  Future<void> dispose() async {
    await _devicesController.close();
  }
}
