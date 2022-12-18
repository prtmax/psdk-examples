import 'dart:async';

import 'package:location/location.dart';

class ClassicState {
  final Location location = Location();

  /// bluetooth state
  late bool bluetoothState;

  /// default pin value
  late String pinValue;

  /// The location service is enabled
  late bool isEnabledLocation;
  late bool autoAcceptPairingRequests;
  late bool isConnected;

  late var results= [];
  StreamSubscription? streamBluetoothState;
  StreamSubscription? streamClassicDiscovered;

  ClassicState() {
    bluetoothState = false;
    pinValue = '0000';
    isEnabledLocation = false;
    autoAcceptPairingRequests = true;
    isConnected = false;

  }
}
