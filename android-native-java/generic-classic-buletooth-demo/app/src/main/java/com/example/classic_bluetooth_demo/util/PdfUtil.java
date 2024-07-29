package com.example.classic_bluetooth_demo.util;

import android.app.ProgressDialog;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import com.artifex.mupdf.fitz.Document;
import com.artifex.mupdf.fitz.Page;
import com.artifex.mupdf.fitz.Rect;
import com.artifex.mupdf.fitz.android.AndroidDrawDevice;

public class PdfUtil {
  public static ProgressDialog loading;

  public static void dismissLoading() {
    ProgressDialog progressDialog = loading;
    if (progressDialog == null)
      return;
    progressDialog.dismiss();
  }

  public static Bitmap[] openFile(String paramString) {
    try {
      int j = (Resources.getSystem().getDisplayMetrics()).widthPixels;
      Document document = Document.openDocument(paramString);
      int k = document.countPages();
      Bitmap[] arrayOfBitmap = new Bitmap[k];
      for (int i = 0; i < k; i++) {
        Page page = document.loadPage(i);
        Rect rect = page.getBounds();
        float f = rect.x1;
        f = rect.x0;
        f = rect.y1;
        f = rect.y0;
        arrayOfBitmap[i] = AndroidDrawDevice.drawPage(page, j);
      }
      document.destroy();
      return arrayOfBitmap;
    } catch (Exception exception) {
      return null;
    }
  }

  public static void showLoading(Context paramContext, String paramString) {
    if (paramString == null)
      return;
    loading = ProgressDialog.show(paramContext, "", paramString, true);
  }
}
