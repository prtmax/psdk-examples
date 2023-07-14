import 'dart:async';

class BleState {

  late bool isConnected;

  /// bluetooth state
  late bool bluetoothState;
  late bool isEnabledLocation;

  late var results = [];
  StreamSubscription? streamBluetoothState;
  StreamSubscription? streamBleDiscovered;

  BleState() {
    bluetoothState = false;
    isEnabledLocation = false;
    isConnected = false;
  }
}
