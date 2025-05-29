import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../toolkit/Ip_port_connection_widget.dart';
import 'logic.dart';
import 'state.dart';

class TcpPage extends StatelessWidget {
  final TcpLogic logic = Get.put(TcpLogic());
  final TcpState state = Get.find<TcpLogic>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TcpLogic>(builder: (logic) {
      return Scaffold(
        appBar: AppBar(title: const Text('打印机')),
        body: const Column(
          children: [
            ListTile(
              tileColor: Colors.white,
              title: Text(
                '请确保打印机跟手机网络一致',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: IpPortConnectionWidget(),
            ),
          ],
        ),
      );
    });
  }
}
