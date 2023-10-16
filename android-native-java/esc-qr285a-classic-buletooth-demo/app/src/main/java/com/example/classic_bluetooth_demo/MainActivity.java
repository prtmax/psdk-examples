package com.example.classic_bluetooth_demo;


import android.graphics.*;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

import android.bluetooth.BluetoothDevice;
import android.os.Bundle;


import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import com.printer.psdk.compatible.external.qr285a.CompatibleQR285A;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.args.common.Raw;
import com.printer.psdk.frame.father.types.lifecycle.Lifecycle;
import com.printer.psdk.imagep.android.AndroidSourceImage;


import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.EnumMap;
import java.util.Hashtable;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
  private Connection connection;
  private TextView tv_connect_status;
  private EditText etMsg;
  private Button btnText, btnBitmap;
  private CompatibleQR285A esc;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    etMsg = findViewById(R.id.etMsg);
    btnText = findViewById(R.id.btnText);
    btnBitmap = findViewById(R.id.btnBitmap);
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        esc = new CompatibleQR285A(Lifecycle.builder().connectedDevice(connection).build());
      }

      @Override
      public void onConnectFail(String errMsg, Throwable e) {
      }

      @Override
      public void onConnectionStateChanged(BluetoothDevice device, int state) {
        String msg;
        switch (state) {
          case Connection.STATE_CONNECTING:
            msg = "连接中";
            break;
          case Connection.STATE_PAIRING:
            msg = "配对中...";
            break;
          case Connection.STATE_PAIRED:
            msg = "配对成功";
            break;
          case Connection.STATE_CONNECTED:
            msg = "连接成功";
            break;
          case Connection.STATE_DISCONNECTED:
            msg = "连接断开";
            break;
          case Connection.STATE_RELEASED:
            msg = "连接已销毁";
            break;
          default:
            msg = "";
        }
        if (!msg.isEmpty()) {
          runOnUiThread(new Runnable() {
            @Override
            public void run() {
              tv_connect_status.setText(device.getName() + msg);
            }
          });
        }
      }
    });
    if (connection == null) {
      finish();
      return;
    }
    connection.connect(null);
    EditText etMsg = findViewById(R.id.etMsg);
    btnText.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        //自定义指令
        CompatibleQR285A _gesc = esc.raw(Raw.builder().command(etMsg.getText().toString()).build());
        String result = safeWriteAndRead(_gesc);
        show(result);
      }
    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        //打印图片指令
//                BitmapFactory.Options mOptions = new BitmapFactory.Options();
//                mOptions.inScaled = false;
//                Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.test, mOptions);
        Bitmap bitmap = drawBitmap();
        CompatibleQR285A _gesc = esc.image(EImage.builder().image(new AndroidSourceImage(bitmap))
          .build()).position();
        String result = safeWriteAndRead(_gesc);
        show(result);
      }
    });
  }

  private Bitmap drawBitmap() {
    BitmapFactory.Options mOptions = new BitmapFactory.Options();
    mOptions.inScaled = false;
    Bitmap test = BitmapFactory.decodeResource(getResources(), R.drawable.test, mOptions);
    Paint paint = new Paint();
    Bitmap bitmap = Bitmap.createBitmap(40 * 8, 20 * 8, Bitmap.Config.ARGB_8888);
    Canvas canvas = new Canvas(bitmap);
    canvas.drawColor(Color.WHITE);
    paint.setColor(Color.BLACK);
    paint.setTextSize(16);
//        canvas.drawBitmap(test,0,0,paint);
    canvas.drawText("测试测试测试", 4, 20, paint);
    canvas.drawBitmap(createBarCode("12345678900000"), 4, 50, paint);
    canvas.drawBitmap(createQrCode("123456789", 12 * 8, 3), 4, 98, paint);
    return bitmap;
  }

  /**
   * 转换条形码
   *
   * @param content 条形码的字符串
   */
  private Bitmap createBarCode(String content) {

    content = content.trim();

    Map<EncodeHintType, Object> hints = new EnumMap(EncodeHintType.class);
    hints.put(EncodeHintType.CHARACTER_SET, "utf-8");
    hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.H);
    hints.put(EncodeHintType.MARGIN, 0);
    BitMatrix matrix;
    try {
      matrix = new MultiFormatWriter().encode(content, BarcodeFormat.CODE_128, 28, 38, hints);
    } catch (IllegalArgumentException | WriterException iae) {
      return null;
    }
    return bitMatrix2Bitmap(matrix);
  }

  public static Bitmap bitMatrix2Bitmap(BitMatrix matrix) {
    int w = matrix.getWidth();
    int h = matrix.getHeight();
    int[] rawData = new int[w * h];
    for (int i = 0; i < w; i++) {
      for (int j = 0; j < h; j++) {
        int color = Color.WHITE;
        if (matrix.get(i, j)) {
          // 有内容的部分，颜色设置为黑色，可以自己修改成其他颜色
          color = Color.BLACK;
        }
        rawData[i + (j * w)] = color;
      }
    }

    Bitmap bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
    bitmap.setPixels(rawData, 0, w, 0, 0, w, h);
    return bitmap;
  }

  /**
   * 生成包含字符串信息的二维码图片
   *
   * @param content    二维码携带信息
   * @param qrCodeSize 二维码图片大小
   * @throws WriterException
   */
  public Bitmap createQrCode(String content, int qrCodeSize, int level) {
    //设置二维码纠错级别ＭＡＰ
    Hashtable<EncodeHintType, ErrorCorrectionLevel> hintMap = new Hashtable<>();
    switch (level) {
      case 0:
        hintMap.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);  // 矫错级别
        break;
      case 1:
        hintMap.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.L);  // 矫错级别
        break;
      case 2:
        hintMap.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.Q);  // 矫错级别
        break;
      case 3:
        hintMap.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.H);  // 矫错级别
        break;
    }
    QRCodeWriter qrCodeWriter = new QRCodeWriter();
    BitMatrix matrix = null;
    try {
      matrix = qrCodeWriter.encode(content, BarcodeFormat.QR_CODE, qrCodeSize, qrCodeSize, hintMap);
    } catch (WriterException e) {
      e.printStackTrace();
    }
    return bitMatrix2Bitmap(deleteWhite(matrix));
  }

  private static BitMatrix deleteWhite(BitMatrix matrix) {
    int[] rec = matrix.getEnclosingRectangle();
    int resWidth = rec[2] + 1;
    int resHeight = rec[3] + 1;

    BitMatrix resMatrix = new BitMatrix(resWidth, resHeight);
    resMatrix.clear();
    for (int i = 0; i < resWidth; i++) {
      for (int j = 0; j < resHeight; j++) {
        if (matrix.get(i + rec[0], j + rec[1]))
          resMatrix.set(i, j);
      }
    }
    return resMatrix;
  }

  private byte[] bitmap2Bytes(Bitmap bm) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
    return baos.toByteArray();
  }

  private String safeWriteAndRead(PSDK psdk) {
    try {
      WroteReporter reporter = psdk.write();
      if (!reporter.isOk()) {
        throw new IOException("写入数据失败", reporter.getException());
      }
      Thread.sleep(200);
      byte[] bytes = psdk.read(ReadOptions.builder().timeout(2000).build());
      return new String(bytes);
    } catch (Exception e) {
      return null;
    }
  }

  private void show(String message) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
