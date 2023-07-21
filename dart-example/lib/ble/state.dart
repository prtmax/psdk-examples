import 'dart:async';

class BleState {
  bool isConnected = false;

  /// bluetooth state
  bool bluetoothState = false;
  bool isEnabledLocation = false;

  var results = [];
  StreamSubscription? streamBluetoothState;
  StreamSubscription? streamBleDiscovered;

  BleState() {}
}
