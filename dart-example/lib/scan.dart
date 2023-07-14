import 'package:flutter/material.dart';
import 'package:scan/scan.dart';

class ScanPage extends StatelessWidget {
  ScanController controller = ScanController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            ScanView(
              controller: controller,
              scanAreaScale: .7,
              scanLineColor: Colors.green,
              onCapture: (data) {
                Navigator.pop(context,data);
              },
            ),
          ],
        ),
      ),
    );
  }
}
