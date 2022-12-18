import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_fruit_cpcl/psdk_fruit_cpcl.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_fruit_tspl/psdk_fruit_tspl.dart';

class Printer {
  static Printer? _instance;

  factory Printer() => _instance ??= Printer._();

  Printer._();

  ConnectedDevice? _connectedDevice;
  GenericTSPL? _tspl;
  GenericCPCL? _cpcl;
  GenericESC? _esc;

  void init({required ConnectedDevice connectedDevice}) {
    _connectedDevice = connectedDevice;
    _tspl = TSPL.genericWithConnectedDevice(connectedDevice);
    _cpcl = CPCL.genericWithConnectedDevice(connectedDevice);
    _esc = ESC.genericWithConnectedDevice(connectedDevice);
  }

  bool isConnected() {
    return _connectedDevice?.connectionState()==ConnectionState.connected;
  }

  void disconnect() {
     _connectedDevice?.disconnect();
  }

  ConnectedDevice? connectedDevice() {
    return _connectedDevice;
  }

  GenericTSPL tspl() {
    if (_connectedDevice == null) {
      throw Exception('The device is not connected');
    }
    return _tspl!;
  }

  GenericCPCL cpcl() {
    if (_connectedDevice == null) {
      throw Exception('The device is not connected');
    }
    return _cpcl!;
  }

  GenericESC esc() {
    if (_connectedDevice == null) {
      throw Exception('The device is not connected');
    }
    return _esc!;
  }
}
