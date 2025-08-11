package com.aiyin.psdk.demo.tcp;

import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.net.NetConnectedDevice;
import com.printer.psdk.device.net.Network;

public class NetPrinter {


  public NetPrinter() {
    // 连接打印机, 填入 打印机 ip 和端口, 确保能连上打印机, 在同一个网络中
    Network network = new Network("192.168.1.10", 9100);
    // 获取打印机连接对象
    NetConnectedDevice nc = network.connect();
    // 创建指令构造器
    PrinterUtil.getInstance().init(nc);
  }

  // 测试打印
  public void test() {
    PrinterUtil.getInstance().safeWrite(PrinterUtil.getInstance().generateTSPLCmd());
    // 打印完后断开
    PrinterUtil.getInstance().disconnect();
  }

  // 查询打印机状态
  private void status() {
    String status = PrinterUtil.getInstance().statusTSPL();
  }


}
