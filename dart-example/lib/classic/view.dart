import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printer_demo/classic/widgets/classic_device_list_entry.dart';
import 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';
import '../toolkit/custom_separator_widget.dart';
import '../toolkit/printer.dart';
import '../toolkit/tip_icon_generic.dart';
import 'logic.dart';
import 'state.dart';

class ClassicPage extends StatelessWidget {
  final ClassicLogic logic = Get.put(ClassicLogic());
  final ClassicState state = Get.find<ClassicLogic>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ClassicLogic>(builder: (logic) {
      return Scaffold(
          appBar: AppBar(title: const Text('打印机')),
          body: state.isEnabledLocation
              ? Column(
                  children: [
                    Expanded(child: _bluetoothManageScreen(context)),
                    _refreshView(context)
                  ],
                )
              : TipWithIconScreen(
                  icon: Icons.location_off,
                  tipText: '开启定位',
                  onTap: logic.checkLocationService,
                ));
    });
  }

  /// bluetooth manage screen
  Widget _bluetoothManageScreen(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(top: 10), children: <Widget>[
      if (state.isConnected) _connectedDeviceWidget(),
      if (state.isConnected) const CustomSeparatorWidget(),
      const ListTile(
        tileColor: Colors.white,
        title: Text(
          '请确保打印机开启',
          style: TextStyle(color: Colors.redAccent, fontSize: 14),
        ),
      ),
      const CustomSeparatorWidget(),
      if (!state.bluetoothState)
        ListTile(
          tileColor: Colors.white,
          title: const Text('开启',
              style: TextStyle(color: Color(0xFF0C0C0C), fontSize: 14)),
          trailing: CupertinoSwitch(
              value: state.bluetoothState,
              onChanged: logic.requestOperateBluetooth),
        ),
      if (!state.bluetoothState)
        ListTile(
          tileColor: Colors.white,
          title: const Text('状态',
              style: TextStyle(color: Color(0xFF0C0C0C), fontSize: 14)),
          subtitle: Text(
            state.bluetoothState.toString(),
            style: const TextStyle(color: Color(0xFFC7C7C7), fontSize: 14),
          ),
          trailing: SizedBox(
            width: 60,
            height: 26,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFF0085FF)),
              onPressed: () {
                logic.openSettings();
              },
              child: const Text(
                '设置',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.normal),
              ),
            ),
          ),
        ),
      // BetterWidgets.betterDivider(text: 'g.discovery'.tr),
      if (state.bluetoothState) _discoveryView(context),
    ]);
  }

  Widget _connectedDeviceWidget() {
    FluetoothDevice? connectedDevice = Printer().connectedDevice()?.origin();
    if (connectedDevice == null) {
      return ListTile(
        onTap: logic.disconnect,
        tileColor: Colors.white,
        title: const Text('获取连接设备失败'),
        subtitle: const Text('请尝试重新连接设备'),
        leading: const Icon(Icons.error, color: Colors.redAccent),
      );
    } else {
      return BluetoothDeviceListEntry(
        isConnected: true,
        device: connectedDevice,
        buttonColor: Colors.red,
        onTap: () {
          logic.disconnect();
        },
      );
    }
  }

  Widget _discoveryView(BuildContext context) {
    List<Widget> items = [
      const ListTile(
        tileColor: Colors.white,
        title: Center(
          child: Text("搜索设备"),
        ),
      )
    ];

    for (var result in state.results) {
      final device = result.origin;
      if (device.name == null) continue;
      if (device.name!.isEmpty) continue;
      var widget = BluetoothDeviceListEntry(
        device: result,
        onTap: () async {
          if (!state.isConnected) {
            logic.connectDevice(result);
            return;
          }
          final alert = await showOkCancelAlertDialog(
            context: context,
            title: '提示',
            message: '断开连接',
            defaultType: OkCancelAlertDefaultType.cancel,
          );
          if (alert == OkCancelResult.ok) {
            var future = logic.disconnect();
            future.then((value) {
              logic.connectDevice(result);
            });
          }
        },
      );
      items.add(widget);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: items);
  }

  Widget _refreshView(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ClassicBluetooth().listenDiscovery(),
      initialData: false,
      builder: (c, snapshot) {
        var isScanning = snapshot.data ?? false;
        return Container(
          color: const Color(0XFFEFEFEF),
          child: Container(
              height: 40,
              margin: const EdgeInsets.only(
                  left: 30, right: 30, bottom: 30, top: 10),
              decoration: BoxDecoration(
                  color: const Color(0XFF0085FF),
                  borderRadius: BorderRadius.circular(5)),
              child: ElevatedButton(
                onPressed: isScanning ? null : logic.restartDiscovery,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, double.infinity),
                    backgroundColor: const Color(0XFF0085FF)),
                child: isScanning
                    ? FittedBox(
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColorLight),
                          ),
                        ),
                      )
                    : const Text(
                        '刷新',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              )),
        );
      },
    );
  }
}
