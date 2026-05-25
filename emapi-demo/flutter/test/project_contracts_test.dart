import 'dart:async';
import 'dart:io';

import 'package:emapi_demo/src/bluetooth_printer_connector.dart';
import 'package:emapi_demo/src/emapi_demo_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

String readProjectFile(String path) {
  return File(path).readAsStringSync();
}

String methodBody(String source, String methodName) {
  final declaration = RegExp(
    r'(?:Future<[^>]+>|Future|Uint8List|void|String|int|bool)\s+' +
        RegExp.escape(methodName) +
        r'\s*\(',
  ).firstMatch(source);
  final start = declaration?.start ?? source.indexOf(methodName);
  if (start == -1) {
    return '';
  }
  final parametersStart = source.indexOf('(', start);
  if (parametersStart == -1) {
    return '';
  }
  var parametersDepth = 0;
  var parametersEnd = -1;
  for (var index = parametersStart; index < source.length; index += 1) {
    final char = source[index];
    if (char == '(') {
      parametersDepth += 1;
    } else if (char == ')') {
      parametersDepth -= 1;
      if (parametersDepth == 0) {
        parametersEnd = index;
        break;
      }
    }
  }
  if (parametersEnd == -1) {
    return '';
  }
  final bodyStart = source.indexOf('{', parametersEnd);
  if (bodyStart == -1) {
    return '';
  }
  var depth = 0;
  for (var index = bodyStart; index < source.length; index += 1) {
    final char = source[index];
    if (char == '{') {
      depth += 1;
    } else if (char == '}') {
      depth -= 1;
      if (depth == 0) {
        return source.substring(bodyStart, index + 1);
      }
    }
  }
  return '';
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
    final settings = readProjectFile('lib/src/pages/settings_page.dart');

    expect(main, contains('Icons.tune'));
    expect(main, contains('SettingsPage'));
    expect(settings, contains('SwitchListTile'));
    expect(settings, contains('模拟模式'));
    expect(settings, contains('生成模拟蓝牙设备'));
  });

  test('main_exposesInlineWifiConfigSubmitAction', () {
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('提交配网信息'));
    expect(operationSheet, contains('Icons.send_to_mobile'));
    expect(operationSheet, contains('controller.setWifiConfig'));
  });

  test('main_exposesOtaFilePickerAndConfirmAction', () {
    final main = readProjectFile('lib/main.dart');
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );
    final pubspec = readProjectFile('pubspec.yaml');

    expect(pubspec, contains('file_picker:'));
    expect(main, contains('FilePicker.pickFiles'));
    expect(operationSheet, contains('选择 OTA 文件'));
    expect(operationSheet, contains('开始 OTA 升级'));
    expect(main, contains('未选择，模拟模式可直接开始'));
  });

  test('main_usesRecordsAsPrimaryViewAndMovesActionsToSheet', () {
    final functionPage = readProjectFile('lib/src/pages/function_page.dart');
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('DraggableScrollableSheet'));
    expect(functionPage, contains('_OperationSheet'));
    expect(functionPage, contains('_FunctionSheetMode'));
    expect(functionPage, contains('TabBarView'));
    expect(functionPage, contains('命令结果'));
    expect(functionPage, contains('上报解析'));
    expect(operationSheet, contains('功能区'));
    expect(operationSheet, contains('左右滑动选择操作，上拉切换为多行'));
    expect(operationSheet, contains('已展开，多行显示全部操作'));
    expect(operationSheet, contains('DraggableScrollableController'));
    expect(operationSheet, contains('LayoutBuilder'));
    expect(
      operationSheet,
      contains('(constraints.maxWidth - spacing * 2) / 3'),
    );
    expect(operationSheet, contains('size >= 0.42'));
    expect(operationSheet, contains('size <= 0.28'));
    expect(functionPage, contains('暂无命令结果'));
    expect(functionPage, contains('暂无上报解析'));
  });

  test('main_onlyShowsOtaProgressInsideOtaSheet', () {
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('_OtaSheetContent'));
    expect(
      operationSheet.split('_OtaProgressStrip(progressText').length - 1,
      1,
    );
  });

  test('main_opensWifiAndOtaFormsInsideOperationSheet', () {
    final functionPage = readProjectFile('lib/src/pages/function_page.dart');
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('_WifiSheetContent'));
    expect(operationSheet, contains('_OtaSheetContent'));
    expect(operationSheet, contains('返回功能区'));
    expect(functionPage, contains('onOpenWifi'));
    expect(functionPage, contains('onOpenOta'));
  });

  test('main_exposesSelfTestAndShutdownTimeFromOperationSheet', () {
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('打印自检页'));
    expect(operationSheet, contains('设置关机时间'));
    expect(operationSheet, contains('controller.printSelfTestPage'));
    expect(operationSheet, contains('controller.setShutdownTime'));
    expect(operationSheet, contains('TextEditingController'));
    expect(operationSheet, contains('关机时间'));
  });

  test('main_exposesWifiFileTransferFormAndControllerCall', () {
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('WiFi 文件传输'));
    expect(operationSheet, contains('0x0001'));
    expect(operationSheet, contains('WiFi主控升级文件'));
    expect(operationSheet, contains('0x0002'));
    expect(operationSheet, contains('日历图像文件'));
    expect(operationSheet, contains('0x0003'));
    expect(operationSheet, contains('待机图像文件'));
    expect(operationSheet, contains('controller.performWifiFileTransfer'));
  });

  test('main_exposesEscPrintFormAndControllerCall', () {
    final operationSheet = readProjectFile(
      'lib/src/widgets/operation_sheet.dart',
    );

    expect(operationSheet, contains('ESC 打印'));
    expect(operationSheet, contains('controller.performEscPrint'));
    expect(operationSheet, contains('paperType'));
    expect(operationSheet, contains('enableMode'));
    expect(operationSheet, contains('thickness'));
    expect(operationSheet, contains('连续纸'));
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

  test('controller_otaTransferStartsChunkIndexAtOne', () {
    final controller = readProjectFile('lib/src/emapi_demo_controller.dart');
    final body = methodBody(controller, '_transferOtaBytes');

    expect(body, contains('var index = 1;'));
  });

  test('controller_exposesDemoFeatureMethods', () {
    final controller = readProjectFile('lib/src/emapi_demo_controller.dart');

    expect(controller, contains('Future<void> printSelfTestPage('));
    expect(controller, contains('Future<void> setShutdownTime('));
    expect(controller, contains('Future<void> performWifiFileTransfer('));
    expect(controller, contains('Future<void> performEscPrint('));
  });

  test('controller_escPrintComposesEscAndSendsViaEmapiPrintEsc', () {
    final controller = readProjectFile('lib/src/emapi_demo_controller.dart');
    final printBody = methodBody(controller, 'performEscPrint');
    final buildBody = methodBody(controller, '_buildEscPrintBytes');

    expect(buildBody, contains('wakeup()'));
    expect(buildBody, contains('enable()'));
    expect(buildBody, contains('paperType('));
    expect(buildBody, contains('enableMode('));
    expect(buildBody, contains('thickness('));
    expect(buildBody, contains('image('));
    expect(buildBody, contains('position()'));
    expect(buildBody, contains('continuous'));
    expect(buildBody, contains('stopJob()'));
    expect(printBody, contains('printEsc('));
  });

  test('controller_wifiTransferUsesWifiDownloadProtocolOnly', () {
    final controller = readProjectFile('lib/src/emapi_demo_controller.dart');
    final transferBody = methodBody(controller, 'performWifiFileTransfer');
    final chunkBody = methodBody(controller, '_transferWifiFileBytes');

    expect(chunkBody, contains('var index = 1;'));
    expect(transferBody, contains('startWifiFileDownload'));
    expect(chunkBody, contains('transferWifiFileDownloadChunk'));
    expect(transferBody, contains('finishWifiFileDownload'));
    expect(transferBody, isNot(contains('upgradeMainController')));
    expect(chunkBody, isNot(contains('upgradeMainController')));
  });

  test('pubspec_dependsOnEscFruitFromLocalPsdkOrMatchingGitRef', () {
    final pubspec = readProjectFile('pubspec.yaml');

    expect(pubspec, contains('psdk_fruit_esc:'));
    expect(
      pubspec,
      anyOf(
        contains('path: ../../../psdk/dart/fruits/esc'),
        allOf(
          contains('path: dart/fruits/esc'),
          contains('ref: feat-emapi-protocol-sdk'),
        ),
      ),
    );
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
