import 'package:flutter/material.dart';

class CustomToastWidget extends StatelessWidget {
  CustomToastWidget({
    Key? key,
    required this.msg,
    required this.alignment,
  }) : super(key: key);

  final String msg;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$msg', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
