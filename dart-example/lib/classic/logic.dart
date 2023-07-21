import 'dart:async';
import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';
import '../toolkit/printer.dart';
import 'state.dart';

class ClassicLogic extends GetxController {
  final state = ClassicState();
  var keyword = '';

  @override
  void onInit() {
    super.onInit();
    _initState();
  }

  Future<void> _initState() async {
    if (!Platform.isAndroid) {
      return;
    }
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    var discovered = await ClassicBluetooth().isDiscovery();
    if(discovered){
      await ClassicBluetooth().stopDiscovery();
    }
    var connected = await ClassicBluetooth().isConnected();
    if (connected) {
      state.isConnected = true;
      state.bluetoothState = await ClassicBluetooth().bluetoothIsEnabled();
    } else {
      var _state = await ClassicBluetooth().availableBluetooth();
      state.bluetoothState = _state;
    }

    state.streamBluetoothState =
        ClassicBluetooth().listenBluetoothState.stream.listen((_state) {
      state.bluetoothState = _state;
      super.update();
    });
    state.streamClassicDiscovered?.cancel();
    state.streamClassicDiscovered = ClassicBluetooth().discovered().listen((event) {
      state.results.addAll(event);

      super.update();
    });
    state.isEnabledLocation =await Geolocator.isLocationServiceEnabled();
    super.update();

    // _setAutoTryPin();
  }

  @override
  void onClose() {
    super.onClose();
    ClassicBluetooth().origin().setPairingRequestHandler(null);
    ClassicBluetooth().stopDiscovery();
    state.streamBluetoothState?.cancel();
    state.streamClassicDiscovered?.cancel();
  }

  void requestOperateBluetooth(bool state) {
    // Do the request and update with the true value then
    future() async {
      // async lambda seems to not working
      if (state) {
        await ClassicBluetooth().origin().requestEnable();
      } else {
        await ClassicBluetooth().origin().requestDisable();
      }
    }

    future().then((_) {
      super.update();
    });
  }

  void openSettings() {
    ClassicBluetooth().origin().openSettings();
  }

  void updateAutoAcceptPairingRequests(bool value) {
    state.autoAcceptPairingRequests = value;
    // _setAutoTryPin();
    super.update();
  }

  void updatePinValue(String value) {
    state.pinValue = value;
    super.update();
  }

  Future<void> restartDiscovery() async {
    state.results.clear();
    super.update();
    await ClassicBluetooth().startDiscovery(disconnectConnectedDevice: false);
  }

  /// connect device
  Future<void> connectDevice(var result) async {
    try {
      SmartDialog.showLoading(msg: '正在连接');
      var connectedDevice = await ClassicBluetooth().connect(result);
      Printer().init(connectedDevice: connectedDevice);
      state.isConnected = true;
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
    state.isConnected = false;
    super.update();
  }

  Future<void> checkLocationService() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      return;
    }
    state.isEnabledLocation = true;
    super.update();
  }

  /// set auto try pin
  // void _setAutoTryPin() {
  //   if (!state.autoAcceptPairingRequests) {
  //     ClassicBluetooth().setPin(null);
  //     return;
  //   }
  //   ClassicBluetooth().setPin(state.pinValue);
  // }

}
