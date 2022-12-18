import 'package:flutter/material.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';



class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry(
      {required FluetoothDevice device,
      bool isConnected = false,
      GestureTapCallback? onTap,
      GestureLongPressCallback? onLongPress,
      bool enabled = true,
      Color tileColor = Colors.white,
      Color buttonColor = Colors.red})
      : super(
            // onTap: onTap,
            tileColor: tileColor,
            onLongPress: onLongPress,
            enabled: enabled,
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
                    device.name ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:const TextStyle(color: Color(0xFF0C0C0C), fontSize: 14),
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
                  isConnected ? '断开' : '连接',
                  style: TextStyle(
                    fontSize: 14,
                    color: buttonColor,
                  ),
                )),
              ),
            ));

}
