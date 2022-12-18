import 'package:flutter/material.dart';

class CustomSeparatorWidget extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;
  final Color color;

  const CustomSeparatorWidget({
    Key? key,
    this.height = 0,
    this.indent = 15,
    this.endIndent = 15,
    this.color =const Color(0xFFC7C7C7)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );;
  }
}

