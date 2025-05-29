import 'dart:async';

class BluetoothState {
  bool isConnected = false;

  /// bluetooth state
  bool bluetoothState = false;
  var bluetooth;
  var notifiedDevices = [];
  var results = [];
  StreamSubscription? streamBluetoothState;
  StreamSubscription? streamBleDiscovered;

  BluetoothState() {}
}
