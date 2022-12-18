import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:printer_demo/toolkit/custom_loading_widget.dart';
import 'package:printer_demo/toolkit/custom_toast_widget.dart';
import 'package:printer_demo/toolkit/printer.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_father/father/psdk.dart';
import 'package:psdk_frame_father/father/types/write.dart';
import 'package:psdk_fruit_cpcl/psdk_fruit_cpcl.dart';

import 'ble/view.dart';
import 'classic/view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      routes: {
        'MyHomePage': (_) => const MyHomePage(title: 'Home'),
        'ClassicPage': (_) => ClassicPage(),
        'BlePage': (_) => BlePage(),
      },
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
      appBar: AppBar(title: Text(widget.title), actions: [
        connectedDeviceBar(
          context,
          connectedDevice: connectedDevice,
        )
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doPrintPic(),
                  child: const Text('打印图片'),
                )),
            const SizedBox(width: 1, height: 20),
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doPrintModel(),
                  child: const Text('打印模板'),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> doPrintPic() async {
    if (Printer().connectedDevice() == null) {
      if (Platform.isAndroid) {
        Navigator.of(context).pushNamed("BlePage");
      } else {
        Navigator.of(context).pushNamed("BlePage");
      }
      return;
    }
    SmartDialog.showLoading(msg: '正在打印');
    try {
      if (Printer().connectedDevice() == null) {
        SmartDialog.showToast('未连接打印机');
        return;
      }
      String imageAsset = 'assets/images/model.jpg'; //path to asset
      ByteData bytes = await rootBundle.load(imageAsset);
      Uint8List imageBytes =
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      img.Image croppedImage = img.decodeImage(imageBytes)!;
      int imgWidth = croppedImage.width;
      int imgHeight = croppedImage.height;
      PSDK psdk = Printer()
          .cpcl()
          .clear()
          .page(arg: CPage(width: 608, height: 1000))
          .image(
              arg: CImage(
                  startX: 0,
                  startY: 0,
                  image: imageBytes,
                  width: imgWidth,
                  height: imgHeight))
          .print();
      psdk.write(options: WriteOptions());
      SmartDialog.showToast('g.success'.tr);
    } catch (e) {
      SmartDialog.showToast('打印失败${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  Future<void> doPrintModel() async {
    if (Printer().connectedDevice() == null) {
      if (Platform.isAndroid) {
        Navigator.of(context).pushNamed("ClassicPage");
      } else {
        Navigator.of(context).pushNamed("BlePage");
      }
      return;
    }
    SmartDialog.showLoading(msg: '正在打印');
    try {
      if (Printer().connectedDevice() == null) {
        SmartDialog.showToast('未连接打印机');
        return;
      }
      PSDK psdk = Printer()
          .cpcl()
          .clear()
          .page(arg: CPage(height: 1040, width: 608))
          .box(
              arg: CBox(
                  lineWidth: 2,
                  topLeftX: 0,
                  topLeftY: 1,
                  bottomRightX: 598,
                  bottomRightY: 664))
          .line(
              arg: CLine(
                  lineWidth: 2, startX: 0, startY: 88, endX: 598, endY: 88))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 0,
                  startY: 88 + 128,
                  endX: 598,
                  endY: 88 + 128))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 0,
                  startY: 88 + 128 + 80,
                  endX: 598,
                  endY: 88 + 128 + 80))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 0,
                  startY: 88 + 128 + 80 + 144,
                  endX: 598 - 56 - 16,
                  endY: 88 + 128 + 80 + 144))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 52,
                  startY: 88 + 128 + 80,
                  endX: 52,
                  endY: 88 + 128 + 80 + 144 + 128))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 598 - 56 - 16,
                  startY: 88 + 128 + 80,
                  endX: 598 - 56 - 16,
                  endY: 664))
          .bar(
              arg: CBar(
                  x: 120,
                  y: 88 + 12,
                  content: '1234567890',
                  lineWidth: 1,
                  height: 80))
          .text(
              arg: CText(
                  textX: 120 + 12,
                  textY: 88 + 20 + 76,
                  content: '1234567890',
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 12,
                  textY: 88 + 128 + 80 + 32,
                  content: '收',
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 12,
                  textY: 88 + 128 + 80 + 96,
                  content: '件',
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 12,
                  textY: 88 + 128 + 80 + 144 + 32,
                  content: '发',
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 12,
                  textY: 88 + 128 + 80 + 144 + 80,
                  content: '件',
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 52 + 20,
                  textY: 88 + 128 + 80 + 144 + 128 + 16,
                  content: "签收人/签收时间",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 430,
                  textY: 88 + 128 + 80 + 144 + 128 + 36,
                  content: "月",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 490,
                  textY: 88 + 128 + 80 + 144 + 128 + 36,
                  content: "日",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 52 + 20,
                  textY: 88 + 128 + 80 + 24,
                  content: "收姓名13777777777",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 52 + 20,
                  textY: 88 + 128 + 80 + 24 + 32,
                  content: "南京市浦口区威尼斯水城七街区七街区",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 52 + 20,
                  textY: 88 + 128 + 80 + 144 + 24,
                  content: "名字13777777777",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 52 + 20,
                  textY: 88 + 128 + 80 + 144 + 24 + 32,
                  content: "南京市浦口区威尼斯水城七街区七街区",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 598 - 56 - 5,
                  textY: 88 + 128 + 80 + 104,
                  content: "派",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 598 - 56 - 5,
                  textY: 88 + 128 + 80 + 160,
                  content: "件",
                  font: Font.tss24))
          .text(
              arg: CText(
                  textX: 598 - 56 - 5,
                  textY: 88 + 128 + 80 + 208,
                  content: "联",
                  font: Font.tss24))
          .box(
              arg: CBox(
                  lineWidth: 2,
                  topLeftX: 0,
                  topLeftY: 1,
                  bottomRightX: 598,
                  bottomRightY: 968))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 0,
                  startY: 696 + 80,
                  endX: 598,
                  endY: 696 + 80))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 0,
                  startY: 696 + 80 + 136,
                  endX: 598 - 56 - 16,
                  endY: 696 + 80 + 136))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 52,
                  startY: 80,
                  endX: 52,
                  endY: 696 + 80 + 136))
          .line(
              arg: CLine(
                  lineWidth: 2,
                  startX: 598 - 56 - 16,
                  startY: 80,
                  endX: 598 - 56 - 16,
                  endY: 968))
          .bar(
              arg: CBar(
                  x: 320,
                  y: 696 - 4,
                  content: "1234567890",
                  lineWidth: 1,
                  height: 56,
                  codeType: CodeType.code128,
                  codeRotation: CodeRotation.rotation_0))
          .text(
              arg:
                  CText(textX: 320 + 8, textY: 696 + 54, content: "1234567890", font: Font.tss16))
          .text(arg: CText(textX: 12, textY: 696 + 80 + 35, content: "发", font: Font.tss24))
          .text(arg: CText(textX: 12, textY: 696 + 80 + 84, content: "件", font: Font.tss24))
          .text(arg: CText(textX: 52 + 20, textY: 696 + 80 + 28, content: "名字13777777777", font: Font.tss24))
          .text(arg: CText(textX: 52 + 20, textY: 696 + 80 + 28 + 32, content: "南京市浦口区威尼斯水城七街区七街区", font: Font.tss24))
          .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 50, content: "客", font: Font.tss24))
          .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 82, content: "户", font: Font.tss24))
          .text(arg: CText(textX: 598 - 56 - 5, textY: 696 + 80 + 106, content: "联", font: Font.tss24))
          .text(arg: CText(textX: 12 + 8, textY: 696 + 80 + 136 + 22 - 5, content: "物品几个快递 12kg", font: Font.tss24))
          .box(arg: CBox(lineWidth: 2, topLeftX: 598 - 56 - 16 - 120, topLeftY: 696 + 80 + 136 + 11, bottomRightX: 598 - 56 - 16 - 16, bottomRightY: 968 - 11))
          .text(arg: CText(textX: 598 - 56 - 16 - 120 + 17, textY: 696 + 80 + 136 + 11 + 6, content: "已验视", font: Font.tss24))
          .print();
      psdk.write();
      SmartDialog.showToast('打印成功');
    } catch (e) {
      SmartDialog.showToast('打印失败${e.toString()}');
    } finally {
      SmartDialog.dismiss();
    }
  }

  /// connected device bar button
  static Widget connectedDeviceBar(
    BuildContext context, {
    ConnectedDevice? connectedDevice,
    double maxWidth = 200,
  }) {
    var btn = TextButton(
      onPressed: () {
        if (Platform.isAndroid) {
          Navigator.of(context).pushNamed("ClassicPage");
        } else {
          Navigator.of(context).pushNamed("BlePage");
        }
      },
      style: TextButton.styleFrom(
          padding: const EdgeInsets.only(left: 0, right: 8)),
      child: connectedDevice == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "未连接",
                  style: TextStyle(
                      color: Color(0xFFC7C7C7),
                      fontSize: 14,
                      fontWeight: FontWeight.normal),
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
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
    Duration _interval = interval ?? const Duration(seconds: 1);
    while (true) {
      await Future.delayed(_interval);
      var isConnected = Printer().isConnected();
      if (!isConnected) {
        yield null;
        continue;
      }
      yield Printer().connectedDevice();
    }
  }
}
