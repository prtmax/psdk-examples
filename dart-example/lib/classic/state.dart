import 'dart:async';

class ClassicState {

  /// bluetooth state
  bool bluetoothState = false;

  /// default pin value
  String pinValue = '0000';

  /// The location service is enabled
  bool isEnabledLocation = false;
  bool autoAcceptPairingRequests = true;
  bool isConnected=false;

  var results = [];
  StreamSubscription? streamBluetoothState;
  StreamSubscription? streamClassicDiscovered;

  ClassicState() {}
}
