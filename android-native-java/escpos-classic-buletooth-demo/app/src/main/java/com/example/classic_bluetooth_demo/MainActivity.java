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
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.esc.args.ELocation;
import com.printer.psdk.esc.mark.Location;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.args.common.Raw;
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
  private GenericESC esc;

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
        esc = ESC.generic(connectedDevice);
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
    new Thread(new Runnable() {
      @Override
      public void run() {
        connection.connect(null);
      }
    }).start();
    EditText etMsg = findViewById(R.id.etMsg);
    btnText.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if(esc == null) {
          show("打印机未连接");
          return;
        }
        //自定义指令
        GenericESC _gesc = esc.raw(Raw.builder().command(etMsg.getText().toString()).newline(false).build())
          .lineDot(220)
          .lineDot(220);
        safeWrite(_gesc);
      }
    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if(esc == null) {
          show("打印机未连接");
          return;
        }
        //打印图片指令
        BitmapFactory.Options mOptions = new BitmapFactory.Options();
        mOptions.inScaled = false;
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.model, mOptions);
        GenericESC _gesc = esc
          .location(ELocation.builder().location(Location.CENTER).build())//内容居中
          .image(EImage.builder().image(new AndroidSourceImage(bitmap)).build())
//          .lineDotCut()//走纸并切刀
          .lineDot(255)//走纸 根据实际调用
          .lineDot(255);
        safeWrite(_gesc);
      }
    });
  }

  private void safeWrite(PSDK psdk) {
    try {
      WroteReporter reporter = psdk.write();
      if (!reporter.isOk()) {
        throw new IOException("写入数据失败", reporter.getException());
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private void show(String message) {
    if (message == null) return;
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
