import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Location oof screen
class TipWithIconScreen extends StatelessWidget {
  IconData icon;
  double iconSize;
  Color iconColor;
  String tipText;
  Color textColor;
  IconData? actionIcon;
  Color? actionIconColor;
  Function()? onTap;

  TipWithIconScreen({
    this.icon = Icons.info,
    this.iconSize = 200,
    this.iconColor = Colors.lightBlue,
    this.tipText = '',
    this.textColor = Colors.redAccent,
    this.actionIconColor,
    this.actionIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            this.icon,
            size: this.iconSize,
            color: this.iconColor,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Text(
              this.tipText,
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  ?.copyWith(color: this.textColor),
            ),
          ),
          if (this.onTap != null)
            IconButton(
              icon: Icon(this.actionIcon ?? Icons.replay),
              color: this.actionIconColor == null
                  ? Theme.of(context).primaryColor
                  : this.actionIconColor,
              onPressed: this.onTap,
            ),
        ],
      ),
    );
  }
}
