import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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
  StreamSubscription? streamRead;
  static ReadMark readMark = ReadMark.NONE;

  //当前选择的指令0：tspl 1:cpcl 2:esc
  static int curCmd = 0;

  void init({required ConnectedDevice connectedDevice}) {
    _connectedDevice = connectedDevice;
    _tspl = TSPL.genericWithConnectedDevice(connectedDevice);
    _cpcl = CPCL.genericWithConnectedDevice(connectedDevice);
    _esc = ESC.genericWithConnectedDevice(connectedDevice);
    startRead();
  }

  startRead() {
    streamRead?.cancel();
    streamRead = tspl().read(options: ReadOptions(timeout: 2)).listen((event) {
      switch (readMark) {
        case ReadMark.OPERATE_PRINTERVER:
          readMark = ReadMark.NONE;
          String printerVersion = String.fromCharCodes(event);
          SmartDialog.showToast(printerVersion);
          break;
        case ReadMark.OPERATE_SN:
          readMark = ReadMark.NONE;
          String printerSN = String.fromCharCodes(event);
          SmartDialog.showToast(printerSN);
          break;
        case ReadMark.OPERATE_MODEL:
          readMark = ReadMark.NONE;
          String printerModel = String.fromCharCodes(event);
          SmartDialog.showToast(printerModel);
          break;
        case ReadMark.OPERATE_STATUS:
          readMark = ReadMark.NONE;
          switch (Printer.curCmd) {
            case 0:
              doTSPLStatus(event);
              break;
            case 1:
              doCPCLStatus(event);
              break;
            case 2:
              doESCStatus(event);
              break;
          }
          break;
        default:
          break;
      }
    });
  }

  doTSPLStatus(List<int> bytes) async {
    if (bytes.length == 1) {
      if (bytes[0] == 0x00) {
        SmartDialog.showToast('状态：打印机正常');
      }
      if ((bytes[0] & 0x01) == 0x01) {
        SmartDialog.showToast('状态：打印机开盖');
      }
      if ((bytes[0] & 0x02) == 0x02) {
        SmartDialog.showToast('状态：纸张错误');
      }
      if ((bytes[0] & 0x04) == 0x04) {
        SmartDialog.showToast('状态：打印机缺纸');
      }
      if ((bytes[0] & 0x20) == 0x20) {
        SmartDialog.showToast('状态：打印机打印中');
      }
      if ((bytes[0] & 0x10) == 0x10) {
        SmartDialog.showToast('状态：打印机暂停');
      }
      if ((bytes[0] & 0x80) == 0x80) {
        SmartDialog.showToast('状态：打印机过热');
      }
    }
  }

  doCPCLStatus(List<int> bytes) async {
    if (bytes[0] == 0x00) {
      SmartDialog.showToast('状态：正常');
      return;
    }
    if (bytes.length > 1 && bytes[0] == 0x4f && bytes[1] == 0x4b) {
      SmartDialog.showToast('状态：正常');
      return;
    }
    if ((bytes[0] & 16) != 0) {
      SmartDialog.showToast('状态：开盖');
      return;
    }
    if ((bytes[0] & 1) != 0) {
      SmartDialog.showToast('状态：缺纸');
      return;
    }
    if ((bytes[0] & 8) != 0) {
      SmartDialog.showToast('状态：打印中');
      return;
    }
    if ((bytes[0] & 4) != 0) {
      SmartDialog.showToast('状态：低电');
      return;
    }
    SmartDialog.showToast('状态：正常');
    return;
  }

  doESCStatus(List<int> bytes) async {
    if (bytes.length == 1) {
      String s = "状态：";
      bool isok = true;
      if ((bytes[0] & 0x01) == 0x01) {
        s += "正在打印 ";
        isok = false;
      }
      if ((bytes[0] & 0x02) == 0x02) {
        s += "纸舱盖开 ";
        isok = false;
      }
      if ((bytes[0] & 0x04) == 0x04) {
        s += "缺纸 ";
        isok = false;
      }
      if ((bytes[0] & 0x08) == 0x08) {
        s += "电池电压低 ";
        isok = false;
      }
      if ((bytes[0] & 0x10) == 0x10) {
        s += "打印头过热 ";
        isok = false;
      }
      if (isok) {
        s += "正常";
      }
      SmartDialog.showToast(s);
    }
  }

  bool isConnected() {
    return _connectedDevice?.connectionState() == ConnectionState.connected;
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

  GenericTSPL rawTSPL() {
    GenericTSPL rawTSPL = TSPL.genericWithConnectedDevice(FakeConnectedDevice());
    return rawTSPL;
  }

  GenericCPCL rawCPCL() {
    GenericCPCL rawCPCL = CPCL.genericWithConnectedDevice(FakeConnectedDevice());
    return rawCPCL;
  }

  GenericESC rawESC() {
    GenericESC rawESC = ESC.genericWithConnectedDevice(FakeConnectedDevice());
    return rawESC;
  }
}

enum ReadMark {
  NONE,
  OPERATE_PRINTERVER, //打印机软件版本号
  OPERATE_SN, //打印机SN号
  OPERATE_MODEL, //打印机型号
  OPERATE_STATUS, //打印机状态
}
