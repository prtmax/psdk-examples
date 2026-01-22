import 'dart:async';
import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:psdk_usb_android/psdk_usb_android.dart';
import 'package:psdk_usb_windows/psdk_usb_windows.dart';
import '../toolkit/printer.dart';
import 'state.dart';

class UsbLogic extends GetxController {
  final state = UsbState();

  @override
  Future<void> onInit() async {
    super.onInit();
    _initState();
  }

  Future<void> _initState() async {
    if (Platform.isAndroid) {
      state.usb = AndroidUsb();
      state.attachedSubscription = state.usb.onDeviceAttached.listen((device) {
        SmartDialog.showToast('插入');
      });
      state.detachedSubscription = state.usb.onDeviceDetached.listen((device) {
        SmartDialog.showToast('拔出');
      });
      state.grantedSubscription = state.usb.onDeviceGranted.listen((device) async {
        SmartDialog.showToast('授权成功');
        state.results = await state.usb.startDiscovery();
        super.update();
      });
    } else if (Platform.isWindows) {
      state.usb = WindowsUsb();
    } else {
      return;
    }
    state.results = await state.usb.startDiscovery();
    super.update();
  }

  @override
  void onClose() {
    super.onClose();
    state.attachedSubscription.cancel();
    state.detachedSubscription.cancel();
    state.grantedSubscription.cancel();
  }

  Future<void> connectDevice(var result) async {
    try {
      SmartDialog.showLoading(msg: '正在连接');
      var connectedDevice = await state.usb.connect(result);
      Printer().init(connectedDevice: connectedDevice);
      super.update();
      SmartDialog.dismiss();
      SmartDialog.showToast('连接成功');
    } catch (ex) {
      SmartDialog.dismiss();
      SmartDialog.showToast('连接失败');
    }
  }

  Future<void> disconnect() async {
    Printer().disconnect();
    super.update();
  }
}
