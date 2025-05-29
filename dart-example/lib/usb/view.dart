import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logic.dart';
import 'state.dart';

class UsbPage extends StatelessWidget {
  final UsbLogic logic = Get.put(UsbLogic());
  final UsbState state = Get.find<UsbLogic>().state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UsbLogic>(builder: (logic) {
      return Scaffold(
        appBar: AppBar(title: const Text('打印机')),
        body: Column(
          children: [
            Expanded(child: _printerList(state.results)),
          ],
        ),
      );
    });
  }

  Widget _printerList(var results) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (BuildContext context, int index) {
          var device = results[index];
          return Row(
            children: [
              Expanded(child: Text(device.name)),
              TextButton(
                onPressed: () {
                  logic.connectDevice(device);
                },
                child: const Text('连接'),
              ),
              const SizedBox(width: 100),
            ],
          );
        },
      ),
    );
  }
}
