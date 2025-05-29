import 'dart:async';

import 'package:psdk_usb_android/psdk_usb_android.dart';

class UsbState {
  var usb;
  var notifiedDevices = [];
  var results = [];
  late final StreamSubscription<AndroidUsbDevice> attachedSubscription;
  late final StreamSubscription<AndroidUsbDevice> detachedSubscription;
  late final StreamSubscription<AndroidUsbDevice> grantedSubscription;
  BluetoothState() {}
}
