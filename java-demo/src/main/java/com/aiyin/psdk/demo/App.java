package com.aiyin.psdk.demo;

import com.aiyin.psdk.demo.bluetooth.BluetoothPrint;
import com.aiyin.psdk.demo.tcp.NetPrinter;
import com.aiyin.psdk.demo.usb.USBPrinter;

import javax.swing.*;

public class App {
  public static void main(String[] args) {
    //局域网打印
//    NetPrinter netPrinter = new NetPrinter();
//    netPrinter.test();
    //USB打印
    SwingUtilities.invokeLater(() -> {
      new USBPrinter().setVisible(true);
    });
    //蓝牙打印
//    SwingUtilities.invokeLater(() -> {
//      new BluetoothPrint().setVisible(true);
//    });
  }

}
