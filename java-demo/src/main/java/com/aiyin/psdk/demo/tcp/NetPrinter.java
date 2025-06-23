package com.aiyin.psdk.demo.tcp;

import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.net.NetConnectedDevice;
import com.printer.psdk.device.net.Network;
import com.printer.psdk.frame.father.args.common.Raw;

import java.io.IOException;

public class NetPrinter {


  public NetPrinter() {
    // 连接打印机, 填入 打印机 ip 和端口, 确保能连上打印机, 在同一个网络中
    Network network = new Network("192.168.1.10", 9100);
    // 获取打印机连接对象
    NetConnectedDevice nc = new NetConnectedDevice(network);
    // 创建指令构造器
    PrinterUtil.getInstance().init(nc);
  }

  // 测试打印
  public void test() {
    PrinterUtil.getInstance().safeWrite(PrinterUtil.getInstance().generateCmd());
  }

  // 查询打印机状态
  private void status() {
    try {
      byte[] cmd = PrinterUtil.getInstance().rawTspl().clear().status().command().binary();
      byte[] revStatus = PrinterUtil.getInstance().safeWriteAndRead(cmd);
      PrinterUtil.getInstance().getPrinterStatus(revStatus);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }


}
