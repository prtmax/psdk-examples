import 'dart:async';
import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart';
import 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';
import 'package:psdk_bluetooth_windows/psdk_bluetooth_windows.dart';
import '../toolkit/printer.dart';
import 'state.dart';

class BluetoothLogic extends GetxController {
  final state = BluetoothState();
  @override
  void onInit() {
    super.onInit();
    _initState();
  }

  Future<void> _initState() async {
    if (Platform.isAndroid) {
      state.bluetooth = ClassicBluetooth();
    } else if (Platform.isIOS||Platform.isMacOS){
      state.bluetooth = BLEBluetooth();
    }else if(Platform.isWindows){
      state.bluetooth = WindowsBluetooth();
    }
    var discovered = await state.bluetooth.isDiscovery();
    if(discovered){
      await state.bluetooth.stopDiscovery();
    }
    var connected = await state.bluetooth.isConnected();
    if (connected) {
      state.isConnected = true;
      state.bluetoothState = await state.bluetooth.bluetoothIsEnabled();
    } else {
      var _state = await state.bluetooth.bluetoothIsEnabled();
      state.bluetoothState = _state;
    }

    state.streamBluetoothState =
        state.bluetooth.listenBluetoothState.stream.listen((_state) {
          state.bluetoothState = _state;
          super.update();
        });

    state.streamBleDiscovered = state.bluetooth.discovered().listen((device) {
      String deviceName = device.name ?? '';
      if (deviceName.isEmpty) return;
      var notifiedDevice = state.notifiedDevices.firstWhereOrNull((element) => element.mac == device.mac);
      if (notifiedDevice != null) return;
      state.results.add(device);
      super.update();
    });
    super.update();

  }


  @override
  void onClose() {
    super.onClose();
    state.bluetooth.stopDiscovery();
    state.streamBluetoothState?.cancel();
    state.streamBleDiscovered?.cancel();
  }

  Future<void> restartDiscovery() async {
    state.notifiedDevices.clear();
    state.results.clear();
    super.update();
    await state.bluetooth.startDiscovery(disconnectConnectedDevice: false);
  }

  Future<void> connectDevice(var result) async {
    try {
      SmartDialog.showLoading(msg: '正在连接');
      var connectedDevice=await state.bluetooth.connect(result);
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

}

