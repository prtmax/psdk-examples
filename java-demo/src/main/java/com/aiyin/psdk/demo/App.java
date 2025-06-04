package com.aiyin.psdk.demo;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;

import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.net.NetConnectedDevice;
import com.printer.psdk.device.net.Network;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.types.HexOutput;
import com.printer.psdk.imagep.java.JavaSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;

import javax.imageio.ImageIO;

public class App {
  public static void main(String[] args) {
    PsdkDemo demo = new PsdkDemo();
    demo.test();
  }

  private static class PsdkDemo {

    private final GenericTSPL tspl;

    public PsdkDemo() {
      // 连接打印机, 填入 打印机 ip 和端口, 确保能连上打印机, 在同一个网络中
      Network network = new Network("192.168.1.10", 9100);
      // 获取打印机连接对象
      NetConnectedDevice nc = new NetConnectedDevice(network);
      // 创建指令构造器
      this.tspl = TSPL.generic(nc);
    }

    public void test() {
      try {
        InputStream imageStream = getClass().getResourceAsStream("/images/logo.bmp");
        BufferedImage image = ImageIO.read(imageStream);
        if (image != null) {
          System.out.println("成功加载图像！");
          System.out.println("宽度: " + image.getWidth());
          System.out.println("高度: " + image.getHeight());
        }
        this.tspl
          // 清理指令缓存
          .clear()
          // 设定页面大小
          .page(TPage.builder()
            .width(100) // 100mm
            .height(180) // 180mm
            .build())
          // 设定打印方向
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)// 上端先出
              .mirror(TDirection.Mirror.NO_MIRROR) // 不镜像
              .build())
          // 标签纸, 设定间距
          .gap(true)
          // 设定切纸
          .cut(true)
          // 设定打印速度
          .speed(6)
          // 设定打印浓度
          .density(6)
          // 清理指令
          .cls()
          // 图片打印
          .image(
            TImage.builder()
              .x(0)
              .y(0)
              .image(new JavaSourceImage(image))
              .compress(true)
              .build())
          // 条码
          .bar(TBar.builder()
            .x(300) // x 轴
            .y(10) // y 轴
            .width(4) // 宽度
            .height(90) // 高度
            .build())
          // 文字
          .text(TText.builder()
            .x(400)// x 轴
            .y(25) // y 轴
            .font(Font.TSS24) // 字体
            .xmulti(3) // x 放大倍数
            .ymulti(3) // y 放大倍数
            .content("上海浦东") // 内容
            .build())
          // 圆形
          .circle(TCircle.builder()
            .x(670) // x 轴
            .y(1170) // y 轴
            .width(6) // 宽度
            .radius(100) // 半径
            .build())
          // 二维码
          .qrcode(TQRCode.builder()
            .x(620) // x 轴
            .y(620) // y 轴
            .correctLevel(CorrectLevel.H) // 纠错等级
            .cellWidth(4) // 单元宽度
            .content("www.qrprt.com") // 内容
            .build())
          // 打印
          .print(1);

        // 发送指令, 并读取打印机返回
        String response = this.safeWriteAndRead(this.tspl);
        // 打印返回数据 (hex)
        System.out.println(response);
      } catch (IOException e) {
        System.err.println("加载图像时出错: " + e.getMessage());
      }
    }

    private String safeWriteAndRead(PSDK psdk) {
      try {
        // 写入指令给打印机
        WroteReporter reporter = psdk.write();
        // 判断写入失败
        if (!reporter.isOk()) {
          // 抛出错误
          throw new IOException("fail", reporter.getException());
        }
        // 延迟一段时间
        Thread.sleep(200);
        // 读取打印机返回, 设定 timeout 2000ms
        byte[] bytes = psdk.read(ReadOptions.builder().timeout(2000).build());
        // 返回数据 hex
        return HexOutput.simple().format(bytes);
      } catch (Exception e) {
        e.printStackTrace();
        return null;
      }
    }

  }
}
