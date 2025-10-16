package com.aiyin.psdk.demo.util;

import com.printer.psdk.cpcl.CPCL;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.CodeRotation;
import com.printer.psdk.cpcl.mark.CodeType;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
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
  private GenericCPCL _cpcl;
  private GenericESC _esc;

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

  public GenericCPCL cpcl() {
    return this._cpcl;
  }

  public GenericESC esc() {
    return this._esc;
  }

  public GenericTSPL rawTspl() {
    return TSPL.generic(ConnectedDevice.NONE);
  }

  public GenericCPCL rawCpcl() {
    return CPCL.generic(ConnectedDevice.NONE);
  }

  public GenericESC rawEsc() {
    return ESC.generic(ConnectedDevice.NONE);
  }

  public void init(ConnectedDevice paramConnectedDevice) {
    this._connectedDevice = paramConnectedDevice;
    this._tspl = TSPL.generic(paramConnectedDevice);
    this._cpcl = CPCL.generic(paramConnectedDevice);
    this._esc = ESC.generic(paramConnectedDevice);
  }

  //构建tspl指令
  public byte[] generateTSPLCmd() {
    try {
      return rawTspl()
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
            .image(new JavaSourceImage(getImage()))
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
    } catch (Exception e) {
      System.err.println("构建失败: " + e.getMessage());
    }
    return null;
  }

  //构建cpcl指令
  public byte[] generateCPCLCmd() {
    try {
      return rawCpcl()
        // 清理指令缓存
        .clear()
        // 设定页面大小
        .page(CPage.builder().width(608).height(1040).copies(1).build())
        .image(
          CImage.builder()
            .startX(0)
            .startY(0)
            .image(new JavaSourceImage(getImage()))
            .compress(true)
            .build())
        .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(664).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(88).endX(598).endY(88).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(88 + 128).endX(598).endY(88 + 128).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(88 + 128 + 80).endX(598).endY(88 + 128 + 80).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144 + 128).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
        .line(CLine.builder().startX(52).startY(88 + 128 + 80).endX(52).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
        .line(CLine.builder().startX(598 - 56 - 16).startY(88 + 128 + 80).endX(598 - 56 - 16).endY(664).lineWidth(2).build())
        .bar(CBar.builder().x(120).y(88 + 12).lineWidth(1).height(80).content("1234567890").codeType(CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
        .text(CText.builder().textX(120 + 12).textY(88 + 20 + 76).font(com.printer.psdk.cpcl.mark.Font.TSS24_MAX1).content("1234567890").build())
        .text(CText.builder().textX(12).textY(88 + 128 + 80 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("收").build())
        .text(CText.builder().textX(12).textY(88 + 128 + 80 + 96).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
        .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("发").build())
        .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 80).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
        .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 128 + 16).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("签收人/签收时间").build())
        .text(CText.builder().textX(430).textY(88 + 128 + 80 + 144 + 128 + 36).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("月").build())
        .text(CText.builder().textX(490).textY(88 + 128 + 80 + 144 + 128 + 36).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("日").build())
        .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("收姓名" + " " + "13777777777").build())
        .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
        .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("名字" + " " + "13777777777").build())
        .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 104).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("派").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 160).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 208).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("联").build())
        .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(968).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(696 + 80).endX(598).endY(696 + 80).lineWidth(2).build())
        .line(CLine.builder().startX(0).startY(696 + 80 + 136).endX(598 - 56 - 16).endY(696 + 80 + 136).lineWidth(2).build())
        .line(CLine.builder().startX(52).startY(80).endX(52).endY(696 + 80 + 136).lineWidth(2).build())
        .line(CLine.builder().startX(598 - 56 - 16).startY(80).endX(598 - 56 - 16).endY(968).lineWidth(2).build())
        .bar(CBar.builder().x(320).y(696 - 4).lineWidth(1).height(56).content("1234567890").codeType(CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
        .text(CText.builder().textX(320 + 8).textY(696 + 54).font(com.printer.psdk.cpcl.mark.Font.TSS16).content("1234567890").build())
        .text(CText.builder().textX(12).textY(696 + 80 + 35).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("发").build())
        .text(CText.builder().textX(12).textY(696 + 80 + 84).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
        .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("名字" + " " + "13777777777").build())
        .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 50).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("客").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 82).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("户").build())
        .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 106).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("联").build())
        .text(CText.builder().textX(12 + 8).textY(696 + 80 + 136 + 22 - 5).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("物品：" + "几个快递" + " " + "12kg").build())
        .box(CBox.builder().topLeftX(598 - 56 - 16 - 120).topLeftY(696 + 80 + 136 + 11).bottomRightX(598 - 56 - 16 - 16).bottomRightY(968 - 11).lineWidth(2).build())
        .mag(CMag.builder().font(com.printer.psdk.cpcl.mark.Font.TSS24_MAX1).build())//放大倍数
        .text(CText.builder().textX(598 - 56 - 16 - 120 + 17).textY(696 + 80 + 136 + 11 + 6).font(com.printer.psdk.cpcl.mark.Font.TSS24_MAX1).bold(true).content("已验视").build())
        .mag(CMag.builder().font(com.printer.psdk.cpcl.mark.Font.TSS24).build())//还原
        .form()//标签定位指令
        .print(CPrint.builder().mode(CPrint.Mode.MIRROR).build()).command().binary();
    } catch (Exception e) {
      System.err.println("构建失败: " + e.getMessage());
    }
    return null;
  }

  //构建esc指令
  public byte[] generateESCCmd() {
    try {
      return rawEsc()
        .clear()
        .enable()
        .image(
          EImage.builder()
            .image(new JavaSourceImage(getImage()))
            .compress(false)
            .build())
        .stopJob()
       .command().binary();
    } catch (Exception e) {
      System.err.println("构建失败: " + e.getMessage());
    }
    return null;
  }

  public byte[] getPrintData(String currentType) {
    byte[] data;
    switch (currentType){
      case "cpcl":
        data = PrinterUtil.getInstance().generateCPCLCmd();
        break;
      case "esc":
        data = PrinterUtil.getInstance().generateESCCmd();
        break;
      default:
        data = PrinterUtil.getInstance().generateTSPLCmd();
        break;
    }
    return data;
  }

  public void printModel(String currentType) {
    PrinterUtil.getInstance().safeWrite(getPrintData(currentType));
  }

  public BufferedImage getImage(){
    InputStream imageStream = getClass().getResourceAsStream("/images/logo.bmp");
    if(imageStream == null) return null;
    BufferedImage image;
    try {
      image = ImageIO.read(imageStream);
    } catch (IOException e) {
      System.err.println("加载图像失败: " + e.getMessage());
      return null;
    }
    if (image != null) {
      System.out.println("成功加载图像！");
      System.out.println("宽度: " + image.getWidth());
      System.out.println("高度: " + image.getHeight());
    }
    return image;
  }

  public String statusTSPL() {
    try {
      byte[] cmd = PrinterUtil.getInstance().rawTspl().clear().status().command().binary();
      byte[] revStatus = PrinterUtil.getInstance().safeWriteAndRead(cmd);
      return PrinterUtil.getInstance().getPrinterStatusTSPL(revStatus);
    } catch (Exception e) {
      e.printStackTrace();
      return "超时";
    }
  }

  public String statusCPCL() {
    try {
      byte[] cmd = PrinterUtil.getInstance().rawCpcl().clear().status().command().binary();
      byte[] revStatus = PrinterUtil.getInstance().safeWriteAndRead(cmd);
      return PrinterUtil.getInstance().getPrinterStatusCPCL(revStatus);
    } catch (Exception e) {
      e.printStackTrace();
      return "超时";
    }
  }

  public String statusESC() {
    try {
      byte[] cmd = PrinterUtil.getInstance().rawEsc().clear().state().command().binary();
      byte[] revStatus = PrinterUtil.getInstance().safeWriteAndRead(cmd);
      return PrinterUtil.getInstance().getPrinterStatusESC(revStatus);
    } catch (Exception e) {
      e.printStackTrace();
      return "超时";
    }
  }

  public String printerStatus(String currentType) {
    String status;
    switch (currentType){
      case "cpcl":
        status = PrinterUtil.getInstance().statusCPCL();
        break;
      case "esc":
        status = PrinterUtil.getInstance().statusESC();
        break;
      default:
        status = PrinterUtil.getInstance().statusTSPL();
        break;
    }
    return status;
  }

  //解析状态
  public String getPrinterStatusTSPL(byte[] revStatus) {
    try {
      if (revStatus != null && revStatus.length == 1) {
        if (revStatus[0] != 0) {
          byte status = revStatus[0];
          System.out.println("打印机状态码: " + status);

          if ((status & 0x01) == 0x01) {
            System.out.println("打印机状态: 纸舱盖打开");
            return "纸舱盖打开";
          }

          if ((status & 0x02) == 0x02) {
            System.out.println("打印机状态: 打印错误");
            return "打印错误";
          }

          if ((status & 0x04) == 0x04) {
            System.out.println("打印机状态: 缺纸");
            return "缺纸";
          }

          if ((status & 0x20) == 0x20) {
            System.out.println("打印机状态: 打印中");
            return "打印中";
          }

          if ((status & 0x10) == 0x10) {
            System.out.println("打印机状态: 暂停");
            return "暂停";
          }

          if ((status & 0x80) == 0x80) {
            System.out.println("打印机状态: 过热");
            return "过热";
          }
        }
        System.out.println("打印机状态: 正常");
        return "正常";
      } else {
        System.out.println("打印机状态: 获取超时");
        return "获取超时";
      }
    } catch (Exception e) {
      System.out.println("获取打印机状态异常: " + e.getMessage());
      e.printStackTrace();
      return "获取超时";
    }
  }

  public String getPrinterStatusCPCL(byte[] Rep) {
    if (Rep == null) {
      return "失败";
    }
    if (Rep[0] == 0x00) {
      return "OK";
    }
    if ((Rep[0] == 0x4f) && (Rep[1] == 0x4b)) {
      return "OK";
    }
    if ((Rep[0] & 16) != 0) {
      return "CoverOpened";
    }
    if ((Rep[0] & 1) != 0) {
      return "NoPaper";
    }
    if ((Rep[0] & 8) != 0) {
      return "Printing";
    }
    if ((Rep[0] & 4) != 0) {
      return "BatteryLow";
    }
    return "OK";
  }

  public String getPrinterStatusESC(byte[] bytes) {
    if (bytes.length == 1) {
      String s = "状态：";
      boolean isok = true;
      if ((bytes[0] & 0x01) == 0x01) {
        s += "正在打印 ";
        isok = false;
      }
      if ((bytes[0] & 0x02) == 0x02) {
        s += "纸舱盖开 ";
        isok = false;
      }
      if ((bytes[0] & 0x04) == 0x04) {
        s += "缺纸 ";
        isok = false;
      }
      if ((bytes[0] & 0x08) == 0x08) {
        s += "电池电压低 ";
        isok = false;
      }
      if ((bytes[0] & 0x10) == 0x10) {
        s += "打印头过热 ";
        isok = false;
      }
      if (isok) {
        s += "良好";
      }
      return s;
    }
    return "失败";
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

  public void disconnect() {
   if(this._connectedDevice != null){
     try {
       this._connectedDevice.disconnect();
     } catch (IOException e) {
       e.printStackTrace();
     }
   }
  }

  private static final class InstanceHolder {
    static final PrinterUtil instance = new PrinterUtil();
  }
}
