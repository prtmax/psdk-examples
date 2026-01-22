import 'package:flutter/material.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';


class ScanResultTile extends StatelessWidget {
  final FluetoothDevice bleDevice;
  final VoidCallback? onTap;
  final Color buttonColor;
  final bool isConnect;

  ScanResultTile(
      {Key? key,
        required this.bleDevice,
        this.onTap,
        this.buttonColor = Colors.red,
        this.isConnect = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        tileColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/common_printer.png',
              width: 25,
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: Text(
                bleDevice.name ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  const TextStyle(color: Color(0xFF0C0C0C), fontSize: 14),
              ),
            ),
          ],
        ),
        trailing: InkWell(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.5),
              border: Border.all(
                width: 1,
                color: buttonColor,
              ),
            ),
            child: Center(
                child: Text(
                  isConnect ? '断开' : '连接',
                  style: TextStyle(
                    fontSize: 14,
                    color: buttonColor,
                  ),
                )),
          ),
        ));


  }
}



class NoDataScreen extends StatelessWidget {
  const NoDataScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.not_interested,
              size: 200.0,
              color: Colors.white30,
            ),
            Text(
              'Not have data.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
