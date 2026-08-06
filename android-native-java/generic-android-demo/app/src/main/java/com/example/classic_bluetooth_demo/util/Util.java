package com.example.classic_bluetooth_demo.util;

import android.content.Context;
import android.graphics.Bitmap;
import android.net.Uri;
import android.widget.Toast;

import java.io.InputStream;

public class Util {

  public static void show(Context context, String message) {
    if (message == null) {
      return;
    }
    Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
  }

  public static byte[] readResources(Context context, int ID) {
    try {
      InputStream in = context.getResources().openRawResource(ID);
      int length = in.available();
      byte[] buffer = new byte[length];
      in.read(buffer);
      in.close();
      return buffer;
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  public static byte[] readUri(Context context, Uri uri) {
    try {
      InputStream in = context.getContentResolver().openInputStream(uri);
      if (in == null) return null;
      int length = in.available();
      byte[] buffer = new byte[length];
      in.read(buffer);
      in.close();
      return buffer;
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  public static String Byte2Hex(Byte inByte) {
    return String.format("%02x", inByte).toUpperCase();
  }

  public static String ByteArrToHex(byte[] inBytArr) {
    StringBuilder strBuilder = new StringBuilder();
    int j = inBytArr.length;
    for (int i = 0; i < j; i++) {
      strBuilder.append(Byte2Hex(inBytArr[i]));
    }
    return strBuilder.toString();
  }

  /**
   * 将十六进制字符串转换为 byte 数组
   * @param hexStr 十六进制字符串（可包含换行、空格等空白字符，会被自动忽略）
   * @return 转换后的 byte 数组
   */
  public static byte[] HexToByteArr(String hexStr) {
    // 去除所有空白字符（换行、空格、回车等）
    String cleanHex = hexStr.replaceAll("\\s+", "");
    int len = cleanHex.length();
    byte[] data = new byte[len / 2];
    for (int i = 0; i < len; i += 2) {
      data[i / 2] = (byte) ((Character.digit(cleanHex.charAt(i), 16) << 4)
          + Character.digit(cleanHex.charAt(i + 1), 16));
    }
    return data;
  }

  /**
   * 解析 TSPL 打印机状态
   * @return 状态描述字符串
   */
  public static String parseTsplStatus(byte[] bytes) {
    if (bytes == null || bytes.length == 0) {
      return "失败";
    }
    if (bytes.length == 1) {
      if (bytes[0] == 0x00) {
        return "打印机正常";
      }
      StringBuilder sb = new StringBuilder();
      if ((bytes[0] & 0x01) == 0x01) sb.append("打印机开盖 ");
      if ((bytes[0] & 0x02) == 0x02) sb.append("纸张错误 ");
      if ((bytes[0] & 0x04) == 0x04) sb.append("打印机缺纸 ");
      if ((bytes[0] & 0x10) == 0x10) sb.append("打印机暂停 ");
      if ((bytes[0] & 0x20) == 0x20) sb.append("打印机打印中 ");
      if ((bytes[0] & 0x80) == 0x80) sb.append("打印机过热 ");
      if (sb.length() > 0) return sb.toString().trim();
      return "打印机正常";
    }
    return "未知状态";
  }

  /**
   * 解析 CPCL 打印机状态
   * @return 状态描述字符串
   */
  public static String parseCpclStatus(byte[] bytes) {
    if (bytes == null || bytes.length == 0) {
      return "失败";
    }
    if (bytes.length >= 2 && bytes[0] == 0x4f && bytes[1] == 0x4b) {
      return "打印机正常";
    }
    if (bytes[0] == 0x00) {
      return "打印机正常";
    }
    StringBuilder sb = new StringBuilder();
    if ((bytes[0] & 1) != 0) sb.append("缺纸 ");
    if ((bytes[0] & 4) != 0) sb.append("低电压 ");
    if ((bytes[0] & 8) != 0) sb.append("打印中 ");
    if ((bytes[0] & 16) != 0) sb.append("纸舱盖打开 ");
    if (sb.length() > 0) return sb.toString().trim();
    return "打印机正常";
  }

  /**
   * 解析 ESC 打印机状态
   * @return 状态描述字符串
   */
  public static String parseEscStatus(byte[] bytes) {
    if (bytes == null || bytes.length == 0) {
      return "失败";
    }
    if (bytes.length == 1) {
      String s = "状态：";
      boolean isok = true;
      if ((bytes[0] & 0x01) == 0x01) { s += "正在打印 "; isok = false; }
      if ((bytes[0] & 0x02) == 0x02) { s += "纸舱盖开 "; isok = false; }
      if ((bytes[0] & 0x04) == 0x04) { s += "缺纸 "; isok = false; }
      if ((bytes[0] & 0x08) == 0x08) { s += "电池电压低 "; isok = false; }
      if ((bytes[0] & 0x10) == 0x10) { s += "打印头过热 "; isok = false; }
      if (isok) s += "良好";
      return s;
    }
    return "未知状态";
  }

  /// 缩放
  public static Bitmap resize(Bitmap bitmap, int width, int height) {
    if (width == 0 && height == 0) {
      return bitmap;
    }
    int originalWidth = bitmap.getWidth();
    int originalHeight = bitmap.getHeight();

    if (width == 0) {
      float scaleRatio = (float) height / originalHeight;
      width = (int) (originalWidth * scaleRatio);
    } else if (height == 0) {
      float scaleRatio = (float) width / originalWidth;
      height = (int) (originalHeight * scaleRatio);
    }
    return Bitmap.createScaledBitmap(bitmap, width, height, true);
  }
}
