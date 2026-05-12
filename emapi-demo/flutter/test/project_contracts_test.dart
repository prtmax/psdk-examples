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
    expect(controller.commandLogs.first, contains('permissions denied'));
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
