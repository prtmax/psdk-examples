import 'dart:async';
import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart';
import '../toolkit/printer.dart';
import 'state.dart';

class BleLogic extends GetxController {
  final state = BleState();
  var keyword = '';

  @override
  void onInit() {
    super.onInit();
    _initState();
  }

  Future<void> _initState() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    var discovered = await BLEBluetooth().isDiscovery();
    if(discovered){
      await BLEBluetooth().stopDiscovery();
    }
    var connected = await BLEBluetooth().isConnected();
    if (connected) {
      state.isConnected = true;
      state.bluetoothState = await BLEBluetooth().bluetoothIsEnabled();
    } else {
      var _state = await BLEBluetooth().availableBluetooth();
      state.bluetoothState = _state;
    }

    state.streamBluetoothState =
         BLEBluetooth().listenBluetoothState.stream.listen((_state) {
      state.bluetoothState = _state;
      super.update();
    });

    state.streamBleDiscovered = BLEBluetooth().discovered().listen((event) {
      state.results.addAll(event);
      super.update();
    });
      state.isEnabledLocation = await Geolocator.isLocationServiceEnabled();
      super.update();
  }


  @override
  void onClose() {
    super.onClose();
    BLEBluetooth().stopDiscovery();
    state.streamBluetoothState?.cancel();
    state.streamBleDiscovered?.cancel();
  }

  Future<void> restartDiscovery() async {
    state.results.clear();
    super.update();
    await BLEBluetooth().startDiscovery(disconnectConnectedDevice: false);
  }

  Future<void> connectDevice(var result) async {
    try {
      SmartDialog.showLoading(msg: '正在连接');
      var connectedDevice=await BLEBluetooth().connect(result);
      Printer().init(connectedDevice: connectedDevice);
      state.isConnected = true;
      super.update();
      SmartDialog.dismiss();
      SmartDialog.showToast('连接成功');
    } catch (ex) {
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

}
