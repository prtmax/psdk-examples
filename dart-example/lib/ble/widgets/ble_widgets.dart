// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:psdk_bluetooth_traits/psdk_bluetooth_traits.dart';


class ScanResultTile extends StatelessWidget {
  final FluetoothDevice bleDevice;
  final VoidCallback? onTap;
  late Color buttonColor;
  late bool isConnect;

  ScanResultTile(
      {Key? key,
      required this.bleDevice,
      this.onTap,
      this.buttonColor = Colors.red,
      this.isConnect = false})
      : super(key: key);

  Widget _buildTitle(BuildContext context) {

      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bleDevice.name ?? " ",
            overflow: TextOverflow.ellipsis,
          ),

        ],
      );

  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

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
            Icon(
              Icons.not_interested,
              size: 200.0,
              color: Colors.white30,
            ),
            Text(
              'Not have data.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  ?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
