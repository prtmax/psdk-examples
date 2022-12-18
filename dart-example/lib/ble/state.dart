import 'dart:async';

import 'package:location/location.dart';
class BleState {

  final Location location = Location();
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
