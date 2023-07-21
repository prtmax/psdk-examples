import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psdk_bluetooth_ble/psdk_bluetooth_ble.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';

import '../toolkit/custom_separator_widget.dart';
import '../toolkit/printer.dart';
import '../toolkit/tip_icon_generic.dart';
import 'logic.dart';
import 'state.dart';
import 'widgets/ble_widgets.dart';

class BlePage extends StatelessWidget {
  final BleLogic logic = Get.put(BleLogic());
  final BleState state = Get.find<BleLogic>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BleLogic>(builder: (logic) {
      return Scaffold(
        appBar: AppBar(title: const Text('打印机')),
        body: StreamBuilder<bool>(
          stream: BLEBluetooth().listenBluetoothState.stream,
          initialData: false,
          builder: (c, snapshot) {
            final bluetooth_state = snapshot.data;
            if (bluetooth_state == null) {
              return TipWithIconScreen(
                icon: Icons.bluetooth_disabled,
                tipText:'请确保蓝牙打开',
              );
            }
            if (bluetooth_state != true) {
              return TipWithIconScreen(
                icon: Icons.bluetooth_disabled,
                tipText: '请确保蓝牙打开',
              );
            }
            return Column(
              children: [
                Expanded(child: _findDevicesScreen(c)),
                _refreshView(c)
              ],
            );
          },
        ),
      );
    });
  }

  Widget _findDevicesScreen(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: state.results.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) return _headerView();

          final result = state.results[index - 1];
          return ScanResultTile(
            bleDevice: result,
            onTap: () async {
              if (!state.isConnected) {
                logic.connectDevice(result);
                return;
              }
              final alert = await showOkCancelAlertDialog(
                context: context,
                title: '提示',
                message: '是否断开',
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
        });
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
      return ScanResultTile(
        bleDevice: connectedDevice,
        onTap: logic.disconnect,
        isConnect: true,
      );
    }
  }

  Widget _headerView() {
    return Column(
      children: [
        if (state.isConnected) _connectedDeviceWidget(),
        if (state.isConnected) const CustomSeparatorWidget(),
        const ListTile(
          tileColor: Colors.white,
          title: Text(
            '请确保打印机开启',
            style: TextStyle(
                color: Colors.redAccent, fontSize: 14),
          ),
        ),
        const CustomSeparatorWidget(),
        const ListTile(
          tileColor: Colors.white,
          title: Center(
            child: Text("搜索设备"),
          ),
        )
      ],
    );
  }

  Widget _refreshView(BuildContext context) {
    return StreamBuilder<bool>(
      stream: BLEBluetooth().origin().isScanning,
      initialData: false,
      builder: (c, snapshot) {
        var isScanning = snapshot.data ?? false;
        return Container(
          color:  const Color(0XFFEFEFEF),
          child: Container(
              height: 40,
              margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30, top: 10),
              decoration: BoxDecoration(
                  color: const Color(0XFF0085FF), borderRadius: BorderRadius.circular(5)),
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
                        style: TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
              )),
        );
      },
    );
  }
}
