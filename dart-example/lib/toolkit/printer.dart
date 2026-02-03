import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_father/father/types/hex_output.dart';
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
    streamRead = tspl().read(options: ReadOptions(timeout: 2)).listen((bytes) {
      doReceiveData(bytes);
    });
  }

  ///打印机上报的数据
  doReceiveData(Uint8List received) async {
    // 这几个开头的是打印机主动上报的数据 有可能粘包 做粘包解析
    if (received[0] == 0xFF || received[0] == 0xFB || received[0] == 0xFE || received[0] == 0xFD) {
      // 处理粘包
      while (received.isNotEmpty) {
        if (received.length >= 2) {
          // 提取前两个字节
          Uint8List value = received.sublist(0, 2);
          received = received.sublist(2); // 移除前两位

          // 根据数据类型处理
          switch (value[0]) {
            case 0xFE:
              onPaperError(value);
              break;
            case 0xFD:
              onStartOrStopSend(value);
              break;
            case 0xFF:
              onPrintStatus(value);
              break;
            case 0xFB:
              onBatteryStatus(value);
              break;
            default:
              onReceive(value);
              break;
          }
        } else {
          // 如果不足两个字节，直接处理剩余数据
          Uint8List value = received;
          received = Uint8List(0); // 清空原始列表
          onReceive(value);
        }
      }
    } else {
      // 如果不是粘包数据，直接处理
      onReceive(received);
    }
  }

  ///app主动查询返回的数据
  onReceive(Uint8List bytes) {
    switch (readMark) {
      case ReadMark.OPERATE_BATVOL:
        readMark = ReadMark.NONE;
        if (bytes.length == 2) {
          int battery = bytes[1] > 100 ? 100 : bytes[1];
          SmartDialog.showToast('电量：$battery');
          switch (bytes[0]) {
            case 0x00:
              SmartDialog.showToast('未充电');
              break;
            case 0x01:
              SmartDialog.showToast('未充电');
              break;
            case 0x02:
              SmartDialog.showToast('充电中');
              break;
            case 0x03:
              SmartDialog.showToast('充电完成');
              break;
          }
        }
        break;
      case ReadMark.OPERATE_PRINTERVER:
        readMark = ReadMark.NONE;
        String printerVersion = String.fromCharCodes(bytes);
        SmartDialog.showToast(printerVersion);
        break;
      case ReadMark.OPERATE_SN:
        readMark = ReadMark.NONE;
        String printerSN = String.fromCharCodes(bytes);
        SmartDialog.showToast(printerSN);
        break;
      case ReadMark.OPERATE_MODEL:
        readMark = ReadMark.NONE;
        String printerModel = String.fromCharCodes(bytes);
        SmartDialog.showToast(printerModel);
        break;
      case ReadMark.OPERATE_INFO:
        readMark = ReadMark.NONE;
        String printerInfo = String.fromCharCodes(bytes);
        SmartDialog.showToast(printerInfo);
        break;
      case ReadMark.OPERATE_GET_TIME:
        readMark = ReadMark.NONE;
        if (bytes.length == 2) {
          int time = int.parse(HexOutput.def().format(bytes), radix: 16);
          SmartDialog.showToast('关机时间：$time分钟');
        }
        break;
      case ReadMark.OPERATE_SET_TIME:
        readMark = ReadMark.NONE;
        if (HexOutput.def().format(bytes) == "4f4b") {
          SmartDialog.showToast('设置关机时间成功');
        } else {
          SmartDialog.showToast('设置关机时间失败');
        }
        break;
      case ReadMark.OPERATE_LEARN_GAP:
        readMark = ReadMark.NONE;
        String backValue = String.fromCharCodes(bytes);
        if (!(backValue.toLowerCase() == "ok")) {
          SmartDialog.showToast('校准失败');
        } else {
          ///学习成功后发送定位指令
          readMark = ReadMark.OPERATE_POSITION;
          esc().enable().lineDot(dot: 10).position().stopJob().write();
        }
        break;
      case ReadMark.OPERATE_POSITION:
        readMark = ReadMark.NONE;
        if (HexOutput.def().format(bytes).toLowerCase().contains("4f4b") || HexOutput.def().format(bytes).toLowerCase().contains("aa")) {
          SmartDialog.showToast('校准成功');
        } else {
          SmartDialog.showToast('校准失败');
        }
        break;
      case ReadMark.OPERATE_STATUS:
        readMark = ReadMark.NONE;
        switch (Printer.curCmd) {
          case 0:
            doTSPLStatus(bytes);
            break;
          case 1:
            doCPCLStatus(bytes);
            break;
          case 2:
            doESCStatus(bytes);
            break;
        }
        break;
      case ReadMark.OPERATE_PRINT:
        readMark = ReadMark.NONE;
        if (HexOutput.def().format(bytes).toLowerCase().contains("4f4b") || HexOutput.def().format(bytes).toLowerCase().contains("aa")) {
          print('-------------ok------------');

          ///打印完成 可以在这里下发第二份数据
        }
        break;
      default:
        break;
    }
  }

  ///纸张错误
  Future<void> onPaperError(Uint8List bytes) async {
    switch (bytes[1]) {
      ///折叠黑标纸
      case 0x01:
        SmartDialog.showToast('识别到纸张错误：当前为折叠黑标纸');
        break;

      ///连续卷筒纸
      case 0x02:
        SmartDialog.showToast('识别到纸张错误：当前为连续卷筒纸');
        break;

      ///不干胶缝隙纸
      case 0x03:
        SmartDialog.showToast('识别到纸张错误：当前为不干胶缝隙纸');
        break;
    }
  }

  ///打印机暂停和恢复
  void onStartOrStopSend(Uint8List bytes) {
    switch (bytes[1]) {
      case 0x01:
        SmartDialog.showToast('打印被中断');
        break;
      case 0x02:
        SmartDialog.showToast('打印中断恢复，可以继续下发打印数据');
        break;
    }
  }

  ///打印机主动状态上报
  void onPrintStatus(Uint8List bytes) {
    if (bytes[1] == 0x00) {
      SmartDialog.showToast('正常');
      return;
    }
    if ((bytes[1] & 0x01) == 0x01) {
      ///过热
      SmartDialog.showToast('过热');
    }
    if ((bytes[1] & 0x02) == 0x02) {
      SmartDialog.showToast('开盖');
    }
    if ((bytes[1] & 0x04) == 0x04) {
      SmartDialog.showToast('缺纸');
    }
    if ((bytes[1] & 0x08) == 0x08) {
      SmartDialog.showToast('低电');
    }
    if ((bytes[1] & 0x10) == 0x10) {
      ///未识别耗材
      SmartDialog.showToast('未识别耗材');
    }
  }

  ///充电状态上报
  void onBatteryStatus(Uint8List bytes) {
    switch (bytes[1]) {
      case 0x00:
        SmartDialog.showToast('未充电');
        break;
      case 0x01:
        SmartDialog.showToast('未充电');
        break;
      case 0x02:
        SmartDialog.showToast('充电中');
        break;
      case 0x03:
        SmartDialog.showToast('充电完成');
        break;
    }
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
  OPERATE_PRINT, //打印
  OPERATE_PRINTERVER, //打印机软件版本号
  OPERATE_SN, //打印机SN号
  OPERATE_MODEL, //打印机型号
  OPERATE_STATUS, //打印机状态
  OPERATE_INFO, //设备所有信息
  OPERATE_BATVOL, //电量查询
  OPERATE_SET_TIME, //设置关机时间
  OPERATE_GET_TIME, //获取关机时间
  OPERATE_LEARN_GAP, //学习缝隙
  OPERATE_POSITION, //走纸定位
}

class PaperTypeItem {
  final String name;
  final dynamic type;

  PaperTypeItem({required this.name, required this.type});
}
