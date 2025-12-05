package com.example.classic_bluetooth_demo.util;

import android.content.Context;
import android.graphics.Bitmap;
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
