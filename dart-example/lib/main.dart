import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:printer_demo/tcp/view.dart';
import 'package:printer_demo/toolkit/printer.dart';
import 'package:printer_demo/usb/view.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_father/father/args/common/raw.dart';
import 'package:psdk_frame_father/father/types/write.dart';
import 'package:psdk_fruit_cpcl/psdk_fruit_cpcl.dart';
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:psdk_fruit_tspl/psdk_fruit_tspl.dart';
import 'bluetooth/view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Printer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Printer Demo'),
      getPages: [
        GetPage(name: '/', page: () => const MyHomePage(title: 'Printer Demo')),
        GetPage(name: '/bluetooth', page: () => BluetoothPage()),
        GetPage(name: '/tcp', page: () => TcpPage()),
        GetPage(name: '/usb', page: () => UsbPage()),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ConnectedDevice? connectedDevice;
  StreamSubscription<ConnectedDevice?>? _deviceSubscription;

  final List<Map<String, dynamic>> _tagList = [
    {"tag": "tspl", "index": 0},
    {"tag": "cpcl", "index": 1},
    {"tag": "esc", "index": 2},
  ];

  @override
  void initState() {
    super.initState();
    _deviceSubscription = listenConnectedDevice().listen((connected) {
      if (mounted) {
        setState(() {
          connectedDevice = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.title), actions: [
        connectedDeviceBar(
          context,
          connectedDevice: connectedDevice,
        )
      ]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 32) / 3;
              return Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed('/bluetooth'),
                            child: const Text('蓝牙连接'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed('/tcp'),
                            child: const Text('tcp连接'),
                          ),
                        ),
                      ),
                      if (Platform.isAndroid || Platform.isWindows) const SizedBox(width: 20),
                      if (Platform.isAndroid || Platform.isWindows)
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Get.toNamed('/usb'),
                              child: const Text('usb连接'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                buildChoiceClip(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doPrintPic(),
                        child: const Text('打印图片'),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doPrintModel(),
                        child: const Text('打印模板'),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doStatus(),
                        child: const Text('查询状态'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    // 版本号查询按钮
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doQueryVersion(),
                        child: const Text('版本号'),
                      ),
                    ),
                    // 型号查询按钮
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doQueryModel(),
                        child: const Text('型号'),
                      ),
                    ),
                    // SN号查询按钮
                    SizedBox(
                      width: buttonWidth,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => doQuerySN(),
                        child: const Text('SN号'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (Printer.curCmd == 2)
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doQueryBattery(),
                          child: const Text('电量查询'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doQueryAllInfo(),
                          child: const Text('设备所有信息'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doGetShutdownTime(),
                          child: const Text('获取关机时间'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doSetPaperType(),
                          child: const Text('设置纸张类型'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doSetShutdownTime(),
                          child: const Text('设置关机时间'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doLearnGap(),
                          child: const Text('走纸校准'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => doSetDensity(),
                          child: const Text('设置浓度'),
                        ),
                      ),
                    ],
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget buildChoiceClip() {
    return Wrap(
      children: _tagList
          .map((e) => Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: buildItem(e),
              ))
          .toList(),
    );
  }

  ChoiceChip buildItem(Map<String, dynamic> map) {
    String tag = map["tag"];
    int index = map["index"];
    return ChoiceChip(
      label: Text(tag),
      selected: Printer.curCmd == index,
      onSelected: (bool selected) {
        setState(() {
          Printer.curCmd = selected ? index : 0;
        });
      },
      labelStyle: TextStyle(
        color: Printer.curCmd == index ? Colors.white : Colors.black,
      ),
      selectedColor: Colors.red,
      surfaceTintColor: Colors.white,
    );
  }

  Future<void> doPrintPic() async {
    try {
      if (Printer().connectedDevice() == null) {
        SmartDialog.showToast('未连接打印机');
        return;
      }
      String imageAsset = 'assets/images/model.jpg'; //path to asset
      ByteData bytes = await rootBundle.load(imageAsset);
      Uint8List imageBytes = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      SmartDialog.showLoading(msg: '正在打印');
      switch (Printer.curCmd) {
        case 0:
          Uint8List value = Printer()
              .rawTSPL()
              .clear()
              .page(arg: TPage(width: 76, height: 130))
              .image(arg: TImage(x: 0, y: 0, image: imageBytes))
              .print()
              .command()
              .binary();
          await safeWrite(value);
          break;
        case 1:
          Uint8List value = Printer()
              .rawCPCL()
              .clear()
              .page(arg: CPage(width: 608, height: 1000))
              .image(arg: CImage(startX: 0, startY: 0, image: imageBytes))
              .print()
              .command()
              .binary();
          await safeWrite(value);
          break;
        case 2:
          Printer.readMark = ReadMark.OPERATE_PRINT;
          Uint8List value = Printer().rawESC().enable().wakeup().image(arg: EImage(image: imageBytes)).stopJob().command().binary();
          await safeWrite(value);
          break;
      }
    } catch (e) {
      SmartDialog.showToast('打印失败${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  Future<void> doPrintModel() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '正在打印');
      switch (Printer.curCmd) {
        case 0:
          doTSPLModel();
          break;
        case 1:
          doCPCLModel();
          break;
        case 2:
          print("esc");
          break;
      }
    } catch (e) {
      SmartDialog.showToast('打印失败${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  Future<void> doStatus() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      Printer.readMark = ReadMark.OPERATE_STATUS;
      switch (Printer.curCmd) {
        case 0:
          Uint8List value = Printer().rawTSPL().status().command().binary();
          await safeWrite(value);
          break;
        case 1:
          Uint8List value = Printer().rawCPCL().status().command().binary();
          await safeWrite(value);
          break;
        case 2:
          Uint8List value = Printer().rawESC().state().command().binary();
          await safeWrite(value);
          break;
      }
    } catch (e) {
      SmartDialog.showToast('状态查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  ///查询版本号(返回结果在startRead()回调里)
  Future<void> doQueryVersion() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '查询版本号中');
      Printer.readMark = ReadMark.OPERATE_PRINTERVER;
      switch (Printer.curCmd) {
        case 0: // TSPL
          Uint8List value = Printer().rawTSPL().version().command().binary();
          await safeWrite(value);
          break;
        case 1: // CPCL
          Uint8List value = Printer().rawCPCL().version().command().binary();
          await safeWrite(value);
          break;
        case 2: // ESC
          Uint8List value = Printer().rawESC().version().command().binary();
          await safeWrite(value);
          break;
      }
    } catch (e) {
      SmartDialog.showToast('版本号查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 查询型号
  Future<void> doQueryModel() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '查询型号中');
      Printer.readMark = ReadMark.OPERATE_MODEL;
      switch (Printer.curCmd) {
        case 0: // TSPL
          Uint8List value = Printer().rawTSPL().mddle().command().binary();
          await safeWrite(value);
          break;
        case 1: // CPCL
          Uint8List value = Printer().rawCPCL().model().command().binary();
          await safeWrite(value);
          break;
        case 2: // ESC
          Uint8List value = Printer().rawESC().model().command().binary();
          await safeWrite(value);
          break;
      }
    } catch (e) {
      SmartDialog.showToast('型号查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 查询SN号
  Future<void> doQuerySN() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '查询SN号中');
      Printer.readMark = ReadMark.OPERATE_SN;
      switch (Printer.curCmd) {
        case 0: // TSPL
          Uint8List value = Printer().rawTSPL().sn().command().binary();
          await safeWrite(value);
          break;
        case 1: // CPCL
          Uint8List value = Printer().rawCPCL().sn().command().binary();
          await safeWrite(value);
          break;
        case 2: // ESC
          Uint8List value = Printer().rawESC().sn().command().binary();
          await safeWrite(value);
          break;
      }
    } catch (e) {
      SmartDialog.showToast('SN号查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 电量查询
  Future<void> doQueryBattery() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '查询电量中');
      Printer.readMark = ReadMark.OPERATE_BATVOL;
      Uint8List value = Printer().rawESC().batteryVolume().command().binary();
      await safeWrite(value);
    } catch (e) {
      SmartDialog.showToast('电量查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 设备所有信息查询
  Future<void> doQueryAllInfo() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '查询设备所有信息中');
      Printer.readMark = ReadMark.OPERATE_INFO;
      Uint8List value = Printer().rawESC().info().command().binary();
      await safeWrite(value);
    } catch (e) {
      SmartDialog.showToast('设备所有信息查询失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 获取关机时间
  Future<void> doGetShutdownTime() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '获取关机时间中');
      Printer.readMark = ReadMark.OPERATE_GET_TIME;
      Uint8List value = Printer().rawESC().getShutdownTime().command().binary();
      await safeWrite(value);
    } catch (e) {
      SmartDialog.showToast('获取关机时间失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 设置纸张类型
  Future<void> doSetPaperType() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }

    // 纸张类型选项
    ///A4机型纸张类型
    final List<PaperTypeItem> paperTypes = [
      PaperTypeItem(name: "标签纸", type: Type.noDryAdhesivePaper),
      PaperTypeItem(name: "连续纸", type: Type.continuousReelPaper),
      PaperTypeItem(name: "折叠黑标纸", type: Type.foldedBlackLabelPaper),
      PaperTypeItem(name: "折叠打孔纸", type: Type.holePaper),
    ];

    ///口袋机型纸张类型
    final List<PaperTypeItem> paperTypesQ3 = [
      PaperTypeItem(name: "标签纸", type: TypeQ3.noDryAdhesivePaper),
      PaperTypeItem(name: "连续纸", type: TypeQ3.continuousReelPaper),
      PaperTypeItem(name: "透明黑标纸", type: TypeQ3.transparentBlackLabelPaper),
    ];
    PaperTypeItem selectedPaper = paperTypes[0];

    await Get.dialog(
      StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter dialogSetState) {
          return AlertDialog(
            title: const Text('选择纸张类型'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: paperTypes.map((paper) {
                return RadioListTile<PaperTypeItem>(
                  title: Text(paper.name),
                  value: paper,
                  groupValue: selectedPaper,
                  onChanged: (value) {
                    if (value != null) {
                      dialogSetState(() {
                        selectedPaper = value;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // 关闭弹窗
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  try {
                    SmartDialog.showLoading(msg: '设置纸张类型中');
                    Uint8List value = Printer().rawESC().paperType(arg: EPaperType(type: selectedPaper.type)).command().binary();
                    // Uint8List value = Printer().rawESC().paperTypeQ3(arg: EPaperTypeQ3(type: selectedPaper.type)).command().binary();
                    await safeWrite(value);
                  } catch (e) {
                    SmartDialog.showToast('纸张类型设置失败：${e.toString()}');
                  } finally {
                    SmartDialog.dismiss();
                  }
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 设置关机时间
  Future<void> doSetShutdownTime() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }

    TextEditingController timeController = TextEditingController(text: '30');

    await Get.dialog(
      AlertDialog(
        title: const Text('设置关机时间（分钟）'),
        content: TextField(
          controller: timeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            hintText: '请输入关机时间（分钟）',
            border: OutlineInputBorder(),
            helperText: '0表示永不关机',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              String timeStr = timeController.text.trim();
              if (timeStr.isEmpty) {
                SmartDialog.showToast('请输入关机时间');
                return;
              }
              int? shutdownTime = int.tryParse(timeStr);
              if (shutdownTime == null || shutdownTime < 0) {
                SmartDialog.showToast('请输入有效的非负数字');
                return;
              }
              Get.back();
              try {
                SmartDialog.showLoading(msg: '设置关机时间中');
                Printer.readMark = ReadMark.OPERATE_SET_TIME;
                Uint8List value = Printer().rawESC().setShutdownTime(time: shutdownTime).command().binary();
                await safeWrite(value);
              } catch (e) {
                SmartDialog.showToast('关机时间设置失败：${e.toString()}');
              } finally {
                SmartDialog.dismiss();
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 口袋打印机 校正纸张（需要先设置纸张类型后再调用）
  Future<void> doLearnGap() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }
    try {
      SmartDialog.showLoading(msg: '校正纸张中');
      Printer.readMark = ReadMark.OPERATE_LEARN_GAP;
      Uint8List value = Printer().rawESC().learnLabelGap().command().binary();
      await safeWrite(value);
    } catch (e) {
      SmartDialog.showToast('校正纸张失败：${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// 设置浓度
  Future<void> doSetDensity() async {
    if (connectedDevice == null) {
      SmartDialog.showToast('未连接打印机');
      return;
    }

    ///0 1 2 对应低中高
    Uint8List value = Printer().rawESC().thickness(thickness: 1).command().binary();
    await safeWrite(value);
  }

  Future<void> doCPCLModel() async {
    Uint8List value = Printer()
        .rawCPCL()
        .clear()
        .page(arg: CPage(width: 608, height: 1040))
        .box(arg: CBox(lineWidth: 2, topLeftX: 0, topLeftY: 1, bottomRightX: 598, bottomRightY: 664))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 88, endX: 598, endY: 88))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 88 + 128, endX: 598, endY: 88 + 128))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 88 + 128 + 80, endX: 598, endY: 88 + 128 + 80))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 88 + 128 + 80 + 144, endX: 598 - 56 - 16, endY: 88 + 128 + 80 + 144))
        .line(arg: CLine(lineWidth: 2, startX: 52, startY: 88 + 128 + 80, endX: 52, endY: 88 + 128 + 80 + 144 + 128))
        .line(arg: CLine(lineWidth: 2, startX: 598 - 56 - 16, startY: 88 + 128 + 80, endX: 598 - 56 - 16, endY: 664))
        .bar(arg: CBar(x: 120, y: 88 + 12, content: '1234567890', lineWidth: 1, height: 80))
        .text(arg: CText(textX: 120 + 12, textY: 88 + 20 + 76, content: '1234567890', font: CFont.tss24))
        .text(arg: CText(textX: 12, textY: 88 + 128 + 80 + 32, content: '收', font: CFont.tss24))
        .text(arg: CText(textX: 12, textY: 88 + 128 + 80 + 96, content: '件', font: CFont.tss24))
        .text(arg: CText(textX: 12, textY: 88 + 128 + 80 + 144 + 32, content: '发', font: CFont.tss24))
        .text(arg: CText(textX: 12, textY: 88 + 128 + 80 + 144 + 80, content: '件', font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 144 + 128 + 16, content: "签收人/签收时间", font: CFont.tss24))
        .text(arg: CText(textX: 430, textY: 88 + 128 + 80 + 144 + 128 + 36, content: "月", font: CFont.tss24))
        .text(arg: CText(textX: 490, textY: 88 + 128 + 80 + 144 + 128 + 36, content: "日", font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 24, content: "收姓名13777777777", font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 24 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 144 + 24, content: "名字13777777777", font: CFont.tss24))
        // .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 144 + 24 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: CFont.tss24))
        .text(
            arg: CTextCanvas(
                textX: 52 + 20,
                textY: 88 + 128 + 80 + 144 + 24 + 32,
                imageBytes: await CTextCanvas.generateImageBytes(
                  content: "南京市浦口区威尼斯水城七街区七街区",
                  font: CFont.tss24,
                  rotation: CRotation.rotation_90,
                  bold: true,
                  alpha: 255,
                ))) //图片形式的text 支持外国语种
        .text(arg: CText(textX: 598 - 56 - 5, textY: 88 + 128 + 80 + 104, content: "派", font: CFont.tss24))
        .text(arg: CText(textX: 598 - 56 - 5, textY: 88 + 128 + 80 + 160, content: "件", font: CFont.tss24))
        .text(arg: CText(textX: 598 - 56 - 5, textY: 88 + 128 + 80 + 208, content: "联", font: CFont.tss24))
        .box(arg: CBox(lineWidth: 2, topLeftX: 0, topLeftY: 1, bottomRightX: 598, bottomRightY: 968))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 696 + 80, endX: 598, endY: 696 + 80))
        .line(arg: CLine(lineWidth: 2, startX: 0, startY: 696 + 80 + 136, endX: 598 - 56 - 16, endY: 696 + 80 + 136))
        .line(arg: CLine(lineWidth: 2, startX: 52, startY: 80, endX: 52, endY: 696 + 80 + 136))
        .line(arg: CLine(lineWidth: 2, startX: 598 - 56 - 16, startY: 80, endX: 598 - 56 - 16, endY: 968))
        .bar(
            arg: CBar(
                x: 320,
                y: 696 - 4,
                content: "1234567890",
                lineWidth: 1,
                height: 56,
                codeType: CCodeType.code128,
                codeRotation: CCodeRotation.rotation_0))
        .text(arg: CText(textX: 320 + 8, textY: 696 + 54, content: "1234567890", font: CFont.tss16))
        .text(arg: CText(textX: 12, textY: 696 + 80 + 35, content: "发", font: CFont.tss24))
        .text(arg: CText(textX: 12, textY: 696 + 80 + 84, content: "件", font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 696 + 80 + 28, content: "名字13777777777", font: CFont.tss24))
        .text(arg: CText(textX: 52 + 20, textY: 696 + 80 + 28 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: CFont.tss24))
        .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 50, content: "客", font: CFont.tss24))
        .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 82, content: "户", font: CFont.tss24))
        .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 106, content: "联", font: CFont.tss24))
        .text(arg: CText(textX: 12 + 8, textY: 696 + 80 + 136 + 22 - 5, content: "物品几个快递 12kg", font: CFont.tss24))
        .box(
            arg: CBox(
                lineWidth: 2, topLeftX: 598 - 56 - 16 - 120, topLeftY: 696 + 80 + 136 + 11, bottomRightX: 598 - 56 - 16 - 16, bottomRightY: 968 - 11))
        .text(arg: CText(textX: 598 - 56 - 16 - 120 + 17, textY: 696 + 80 + 136 + 11 + 6, content: "已验视", font: CFont.tss24))
        .print()
        .command()
        .binary();
    await safeWrite(value);
  }

  Future<void> doTSPLModel() async {
    Uint8List value = Printer()
        .rawTSPL()
        .page(arg: TPage(width: 76, height: 130))
        .box(arg: TBox(startX: 0, startY: 1, endX: 598, endY: 664, width: 2, radius: 0))
        .line(arg: TLine(startX: 0, startY: 88, endX: 598, endY: 88, width: 2))
        .line(arg: TLine(startX: 0, startY: 88 + 128, endX: 598, endY: 88 + 128, width: 2))
        .line(arg: TLine(startX: 0, startY: 88 + 128 + 80, endX: 598, endY: 88 + 128 + 80, width: 2))
        .line(arg: TLine(startX: 0, startY: 88 + 128 + 80 + 144, endX: 598 - 56 - 16, endY: 88 + 128 + 80 + 144, width: 2))
        .line(arg: TLine(startX: 0, startY: 88 + 128 + 80 + 144 + 128, endX: 598 - 56 - 16, endY: 88 + 128 + 80 + 144 + 128, width: 2))
        .line(arg: TLine(startX: 52, startY: 88 + 128 + 80, endX: 52, endY: 88 + 128 + 80 + 144 + 128, width: 2))
        .line(arg: TLine(startX: 598 - 56 - 16, startY: 88 + 128 + 80, endX: 598 - 56 - 16, endY: 664, width: 2))
        .barcode(
            arg: TBarCode(
                x: 120, y: 88 + 12, cellwidth: 2, height: 80, content: "1234567890", rotation: TRotation.rotation_0, codeType: TCodeType.code128))
        .text(arg: TText(x: 120 + 12, y: 88 + 20 + 76, content: "1234567890", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 12, y: 88 + 128 + 80 + 32, content: "收", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 12, y: 88 + 128 + 80 + 96, content: "件", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 12, y: 88 + 128 + 80 + 144 + 32, content: "发", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 12, y: 88 + 128 + 80 + 144 + 80, content: "件", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 52 + 20, y: 88 + 128 + 80 + 144 + 128 + 16, content: "签收人/签收时间", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 430, y: 88 + 128 + 80 + 144 + 128 + 36, content: "月", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 490, y: 88 + 128 + 80 + 144 + 128 + 36, content: "日", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 52 + 20, y: 88 + 128 + 80 + 24, content: "收姓名 13777777777", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(
            arg: TText(x: 52 + 20, y: 88 + 128 + 80 + 24 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 52 + 20, y: 88 + 128 + 80 + 144 + 24, content: "名字 13777777777", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(
            arg: TText(
                x: 52 + 20, y: 88 + 128 + 80 + 144 + 24 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 88 + 128 + 80 + 104, content: "派", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 88 + 128 + 80 + 160, content: "件", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 88 + 128 + 80 + 208, content: "联", font: TFont.tss24, xmulty: 1, ymulty: 1, isBold: false))
        .box(arg: TBox(startX: 0, startY: 1, endX: 598, endY: 968, width: 2, radius: 0))
        .line(arg: TLine(startX: 0, startY: 696 + 80, endX: 598, endY: 696 + 80, width: 2))
        .line(arg: TLine(startX: 0, startY: 696 + 80 + 136, endX: 598 - 56 - 16, endY: 696 + 80 + 136, width: 2))
        .line(arg: TLine(startX: 52, startY: 80, endX: 52, endY: 696 + 80 + 136, width: 2))
        .line(arg: TLine(startX: 598 - 56 - 16, startY: 80, endX: 598 - 56 - 16, endY: 968, width: 2))
        .barcode(
            arg: TBarCode(
                x: 320, y: 696 - 4, cellwidth: 2, height: 56, content: "1234567890", rotation: TRotation.rotation_0, codeType: TCodeType.code128))
        .text(arg: TText(x: 320 + 8, y: 696 + 54, content: "1234567890", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 12, y: 696 + 80 + 35, content: "发", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 12, y: 696 + 80 + 84, content: "件", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 52 + 20, y: 696 + 80 + 28, content: "名字 13777777777", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 52 + 20, y: 696 + 80 + 28 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 696 + 80 + 50, content: "客", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 696 + 80 + 82, content: "户", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 598 - 56 - 5, y: 696 + 80 + 106, content: "联", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(arg: TText(x: 12 + 8, y: 696 + 80 + 136 + 22 - 5, content: "物品：几个快递 12kg", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .box(arg: TBox(startX: 598 - 56 - 16 - 120, startY: 696 + 80 + 136 + 11, endX: 598 - 56 - 16 - 16, endY: 968 - 11, width: 2, radius: 0))
        // .text(arg: TText(x: 598 - 56 - 16 - 120 + 17, y: 696 + 80 + 136 + 11 + 6, content: "已验视", font: TFont.tss24, xmulty: 0, ymulty: 0, isBold: false))
        .text(
            arg: TText(
                x: 598 - 56 - 16 - 120 + 17,
                y: 696 + 80 + 136 + 11 + 6,
                content: "已验视",
                rawFont: "SIMHEI.TTF",
                xmulty: 14,
                ymulty: 14,
                isBold: false)) //使用自定义矢量字体放大倍数计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
        .print()
        .command()
        .binary();
    await safeWrite(value);
  }

  Future<bool> safeWrite(Uint8List binary) async {
    bool enableChunkWrite = Platform.isAndroid ? true : false;
    WroteReporter reporter =
        await Printer().tspl().clear().raw(Raw.binary(binary, newline: false)).write(options: WriteOptions(enableChunkWrite: enableChunkWrite));
    if (!reporter.ok) {
      SmartDialog.showToast('失败');
      return false;
    }
    SmartDialog.showToast('成功');
    return true;
  }

  /// connected device bar button
  static Widget connectedDeviceBar(
    BuildContext context, {
    ConnectedDevice? connectedDevice,
    double maxWidth = 200,
  }) {
    var btn = TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 0, right: 8)),
      child: connectedDevice == null
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "未连接",
                  style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LimitedBox(
                  maxWidth: 100,
                  child: Text(
                    connectedDevice.deviceName() ?? "",
                    style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
    return LimitedBox(
      maxWidth: maxWidth,
      child: connectedDevice == null
          ? btn
          : Tooltip(
              message: connectedDevice.deviceName(),
              child: btn,
            ),
    );
  }

  /// Listen connected device
  Stream<ConnectedDevice?> listenConnectedDevice({Duration? interval}) async* {
    Duration interval0 = interval ?? const Duration(seconds: 1);
    while (true) {
      await Future.delayed(interval0);
      var isConnected = Printer().isConnected();
      if (!isConnected) {
        yield null;
        continue;
      }
      yield Printer().connectedDevice();
    }
  }
}
