import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hazardous_waste/hazardous_waste.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printer_demo/scan.dart';
import 'package:printer_demo/toolkit/custom_loading_widget.dart';
import 'package:printer_demo/toolkit/custom_toast_widget.dart';
import 'package:printer_demo/toolkit/image_util.dart';
import 'package:printer_demo/toolkit/printer.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_father/father/psdk.dart';
import 'package:psdk_frame_father/father/types/write.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:psdk_fruit_esc/psdk_fruit_esc.dart';
import 'package:scan/scan.dart';
import 'package:screenshot/screenshot.dart';
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
      title: '危废打印',
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
        'ScanPage': (_) => ScanPage(),
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
  List<Uint8List> imageBytes = [];
  PrefabData? date;
  ScreenshotController screenshotController = ScreenshotController();
  Uint8List? printImage;

  @override
  void initState() {
    super.initState();
    _initState();
    listenConnectedDevice().listen((connected) {
      setState(() {
        connectedDevice = connected;
      });
    });
  }

  Future<void> _initState() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
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
            if (imageBytes.isNotEmpty)
              Screenshot(
                controller: screenshotController,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Stack(
                    children: [
                      Center(
                          child: Image.memory(
                        imageBytes[0],
                        fit: BoxFit.fill,
                      )),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox.fromSize(
                  size: const Size(145, 50),
                  child: ElevatedButton(
                    onPressed: () => scanByChooseImage(),
                    child: const Text('选择危废二维码'),
                  ),
                ),
                SizedBox.fromSize(
                  size: const Size(145, 50),
                  child: ElevatedButton(
                    onPressed: () => toScan(),
                    child: const Text('扫描危废二维码'),
                  ),
                )
              ],
            ),
            const SizedBox(width: 1, height: 20),
            SizedBox.fromSize(
                size: const Size(145, 50),
                child: ElevatedButton(
                  onPressed: () => doPrintPic(),
                  child: const Text('打印危废标签'),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> toScan() async {
    Navigator.of(context).pushNamed<dynamic>("ScanPage").then((result) =>
        result == null ? SmartDialog.showToast('未找到二维码') : scanned(result));
  }

  Future<void> scanByChooseImage() async {
    picker.XFile? xFile = await picker.ImagePicker()
        .pickImage(source: picker.ImageSource.gallery);
    if (xFile == null) return;
    String? result = await Scan.parse(xFile.path);
    if (result == null || result == '') {
      SmartDialog.showToast('未找到二维码');
      return;
    }
    scanned(result);
  }

  Future<void> scanned(String result) async {
    SmartDialog.showLoading(msg: '正在处理');
    date =
        await HazardousWaste(origin: DataOrigin.ZhejiangJinhua, qrlink: result)
            .handle();
    if (date == null) return;
    if (date?.image == null) return;
    setState(() {
      imageBytes.insert(0, date!.image!);
    });
    await Future.delayed(const Duration(seconds: 2));
    printImage = await screenshotController.capture(pixelRatio: 6.11);
    if (printImage == null) {
      SmartDialog.showToast('暂无数据');
      return;
    }
    // printImage = await ImageUtil.dealPic(printImage!);
    if (printImage == null) {
      SmartDialog.showToast('暂无数据');
      return;
    }
    SmartDialog.dismiss();
    // doPrintPic(date.image!);
  }

  Future<void> doPrintPic() async {
    if (connectedDevice == null) {
      if (Platform.isAndroid) {
        Navigator.of(context).pushNamed("ClassicPage");
      } else {
        Navigator.of(context).pushNamed("BlePage");
      }
      return;
    }
    if (printImage == null) {
      SmartDialog.showToast('暂无数据');
      return;
    }
    SmartDialog.showLoading(msg: '正在打印');
    try {
      int copies = date?.copies ?? 1;
      if(copies==0)copies=1;
      for (int i = 0; i < copies; i++) {
        PSDK psdk = Printer()
            .esc()
            .clear()
            .enable()
            .wakeup()
            .location(location: 1)
            .image(arg: EImage(compress: true, image: printImage!))
            .position()
            .stopJob();
        await psdk.write(options: WriteOptions());
      }

      SmartDialog.showToast('g.success'.tr);
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
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
