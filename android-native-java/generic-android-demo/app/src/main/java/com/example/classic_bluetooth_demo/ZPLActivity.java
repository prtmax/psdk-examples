package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.args.common.Raw;


public class ZPLActivity extends Activity {
  private static final String TAG = "ZPLActivity";
  private Connection connection;
  private TextView tv_connect_status;
  private Button btnModel;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_zpl);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    btnModel = findViewById(R.id.btnModel);
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        PrintUtil.getInstance().init(connectedDevice);
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
    btnModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        //传入zpl指令字符串 生成byte数据
        byte[] printData = PrintUtil.getInstance().rawTspl().raw(Raw.builder().command("^XA^PW870^LL1515\n" +
          "^CI14\n" +
          "^PON\n" +
          "^FO30,90,0\n" +
          "^A@N,90,90,E:zhonghei.TTF\n" +
          "^FH\\^FD装箱明细^FS\n" +
          "^FO30,240,0\n" +
          "^FB450,2,12,L^A@N,24,24,E:zhonghei.TTF\n" +
          "^FH\\^FD单号: 18311120213582736^FS\n" +
          "^FO540,240,0\n" +
          "^FB315,2,12,L^A@N,24,24,E:zhonghei.TTF\n" +
          "^FH\\^FD打印日期: 2025.01.17^FS\n" +
          "^FO30,330,0\n" +
          "^FB510,2,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD货主姓名:  ^FS\n" +
          "^FO540,330,0\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD箱Mark: 1^FS\n" +
          "^FO540,405,0\n" +
          "^A@N,27,27,E:zhonghei.TTF\n" +
          "^FH\\^FD总量: 24^FS\n" +
          "^FO30,525,0\n" +
          "^GB840,0,3,B,0\n" +
          "^FS\n" +
          "^FO60,555,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD商品名称^FS\n" +
          "^FO420,555,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD货号^FS\n" +
          "^FO660,555,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD尺码^FS\n" +
          "^FO780,555,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD数量^FS\n" +
          "^FO30,600,0\n" +
          "^GB840,0,3,B,0\n" +
          "^FS\n" +
          "^FO45,630,0\n" +
          "^FPH,3\n" +
          "^FB330,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDcommodity-fff74d621473^FS\n" +
          "^FO405,630,0\n" +
          "^FPH,3\n" +
          "^FB210,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDlolCX-f670a617^FS\n" +
          "^FO645,630,0\n" +
          "^FPH,3\n" +
          "^FB150,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD38 v2^FS\n" +
          "^FO795,630,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD1^FS\n" +
          "^FO45,870,0\n" +
          "^FPH,3\n" +
          "^FB330,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDcommodity-fff74d621473^FS\n" +
          "^FO405,870,0\n" +
          "^FPH,3\n" +
          "^FB210,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDlolCX-f670a617^FS\n" +
          "^FO645,870,0\n" +
          "^FPH,3\n" +
          "^FB150,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD37 v2^FS\n" +
          "^FO795,870,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD1^FS\n" +
          "^FO45,1110,0\n" +
          "^FPH,3\n" +
          "^FB330,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDNike Air VaporMax 黑武士 女款^FS\n" +
          "^FO405,1110,0\n" +
          "^FPH,3\n" +
          "^FB210,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD849557-006^FS\n" +
          "^FO645,1110,0\n" +
          "^FPH,3\n" +
          "^FB150,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD35.5^FS\n" +
          "^FO795,1110,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD20^FS\n" +
          "^FO45,1350,0\n" +
          "^FPH,3\n" +
          "^FB330,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDcommodity-fff74d621473^FS\n" +
          "^FO405,1350,0\n" +
          "^FPH,3\n" +
          "^FB210,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FDlolCX-f670a617^FS\n" +
          "^FO645,1350,0\n" +
          "^FPH,3\n" +
          "^FB150,5,12,L^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD37 v1^FS\n" +
          "^FO795,1350,0\n" +
          "^FPH,3\n" +
          "^A@N,30,30,E:zhonghei.TTF\n" +
          "^FH\\^FD1^FS\n" +
          "^XZ").build()).command().binary();
        boolean result = safeWrite(printData);
        show(result ? "成功" : "失败");
      }
    });
  }

  private boolean safeWrite(byte[] printData) {
    try {
      WroteReporter reporter = PrintUtil.getInstance().tspl().raw(Raw.builder().command(printData).build()).write();
      return reporter.isOk();
    } catch (Exception e) {
      e.printStackTrace();
      return false;
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
