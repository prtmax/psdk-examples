import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:printer_demo/tcp/view.dart';
import 'package:printer_demo/toolkit/custom_loading_widget.dart';
import 'package:printer_demo/toolkit/custom_toast_widget.dart';
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
      builder: FlutterSmartDialog.init(
        //default toast widget
        toastBuilder: (String msg) => CustomToastWidget(
          msg: msg,
          alignment: Alignment.center,
        ),
        //default loading widget
        loadingBuilder: (String msg) => CustomLoadingWidget(
          msg: msg,
          background: Colors.blue,
        ),
        // builder: _builder,
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

  final List<Map<String, dynamic>> _tagList = [
    {"tag": "tspl", "index": 0},
    {"tag": "cpcl", "index": 1},
    {"tag": "esc", "index": 2},
  ];

  @override
  void initState() {
    super.initState();
    listenConnectedDevice().listen((connected) {
      setState(() {
        connectedDevice = connected;
      });
    });
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doPrintPic(),
                  child: const Text('打印图片'),
                )),
            const SizedBox(height: 20),
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doPrintModel(),
                  child: const Text('打印模板'),
                )),
            const SizedBox(height: 20),
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doStatus(),
                  child: const Text('查询状态'),
                )),
          ],
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
    } finally {
      SmartDialog.dismiss();
    }
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
        .text(arg: CText(textX: 52 + 20, textY: 88 + 128 + 80 + 144 + 24 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: CFont.tss24))
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
                  style: TextStyle(color: Color(0xFFC7C7C7), fontSize: 14, fontWeight: FontWeight.normal),
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
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
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
