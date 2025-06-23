package com.aiyin.psdk.demo.util;

import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.frame.father.args.common.Raw;
import com.printer.psdk.imagep.java.JavaSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;


public class PrinterUtil {
  private ConnectedDevice _connectedDevice;
  private GenericTSPL _tspl;

  private PrinterUtil() {
  }

  public static PrinterUtil getInstance() {
    return InstanceHolder.instance;
  }

  public ConnectedDevice connectedDevice() {
    return this._connectedDevice;
  }

  public GenericTSPL tspl() {
    return this._tspl;
  }

  public GenericTSPL rawTspl() {
    return TSPL.generic(ConnectedDevice.NONE);
  }

  public void init(ConnectedDevice paramConnectedDevice) {
    this._connectedDevice = paramConnectedDevice;
    this._tspl = TSPL.generic(paramConnectedDevice);
  }

  public byte[] generateCmd() {
    try {
      InputStream imageStream = getClass().getResourceAsStream("/images/logo.bmp");
      BufferedImage image = ImageIO.read(imageStream);
      if (image != null) {
        System.out.println("成功加载图像！");
        System.out.println("宽度: " + image.getWidth());
        System.out.println("高度: " + image.getHeight());
      }
      byte[] printData = rawTspl()
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
        .text(TText.builder()
          .x(400)
          .y(65)
          .rawFont("SIMHEI.TTF")//矢量字体
          .xmulti(14)
          .ymulti(14)
          .content("上海浦东")
          .build())//使用自定义矢量字体放大倍数计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
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
        .print(1).command().binary();
      return printData;
    } catch (IOException e) {
      System.err.println("加载图像时出错: " + e.getMessage());
    }
    return null;
  }

  public PrinterStatus status() {
    try {
      byte[] cmd = new byte[]{0x10, (byte) 0xFF, 0x40};
      byte[] revStatus = PrinterUtil.getInstance().safeWriteAndRead(cmd);
      return PrinterUtil.getInstance().getPrinterStatus(revStatus);
    } catch (Exception e) {
      e.printStackTrace();
      return PrinterStatus.TIMEOUT;
    }
  }

  //解析状态
  public PrinterStatus getPrinterStatus(byte[] revStatus) {
    try {
      if (revStatus != null && revStatus.length == 1) {
        if (revStatus[0] != 0) {
          byte status = revStatus[0];
          System.out.println("打印机状态码: " + status);

          if ((status & 0x01) == 0x01) {
            System.out.println("打印机状态: 纸舱盖打开");
            return PrinterStatus.LIB_IS_OPEN;
          }

          if ((status & 0x02) == 0x02) {
            System.out.println("打印机状态: 打印错误");
            return PrinterStatus.PRINT_ERROR;
          }

          if ((status & 0x04) == 0x04) {
            System.out.println("打印机状态: 缺纸");
            return PrinterStatus.NO_PAPER;
          }

          if ((status & 0x20) == 0x20) {
            System.out.println("打印机状态: 打印中");
            return PrinterStatus.PRINTING;
          }

          if ((status & 0x10) == 0x10) {
            System.out.println("打印机状态: 暂停");
            return PrinterStatus.PAUSED;
          }

          if ((status & 0x80) == 0x80) {
            System.out.println("打印机状态: 过热");
            return PrinterStatus.OVERHEATED;
          }
        }
        System.out.println("打印机状态: 正常");
        return PrinterStatus.NORMAL;
      } else {
        System.out.println("打印机状态: 获取超时");
        return PrinterStatus.TIMEOUT;
      }
    } catch (Exception e) {
      System.out.println("获取打印机状态异常: " + e.getMessage());
      e.printStackTrace();
      return PrinterStatus.TIMEOUT;
    }
  }

  public void safeWrite(byte[] data) {
    try {
      // 写入指令给打印机
      WroteReporter reporter = tspl().raw(Raw.builder().command(data).build()).write();
      // 判断写入失败
      if (!reporter.isOk()) {
        // 抛出错误
        throw new IOException("fail", reporter.getException());
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public byte[] safeWriteAndRead(byte[] data) {
    try {
      // 写入指令给打印机
      WroteReporter reporter = tspl().raw(Raw.builder().command(data).build()).write();
      // 判断写入失败
      if (!reporter.isOk()) {
        // 抛出错误
        throw new IOException("fail", reporter.getException());
      }
      // 延迟一段时间
      Thread.sleep(200);
      // 读取打印机返回, 设定 timeout 2000ms
      return tspl().read(ReadOptions.builder().timeout(2000).build());
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }

  private static final class InstanceHolder {
    static final PrinterUtil instance = new PrinterUtil();
  }
}
