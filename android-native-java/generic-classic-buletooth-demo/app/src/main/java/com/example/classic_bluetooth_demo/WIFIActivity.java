package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import com.example.classic_bluetooth_demo.util.ReadMark;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.wifi.GenericWIFI;
import com.printer.psdk.wifi.WIFI;
import com.printer.psdk.wifi.args.WSetSSID;

import java.io.IOException;

public class WIFIActivity extends Activity {
  private EditText wifi_name, wifi_pwd;
  private Button button_send;
  private Button button_search_name;
  private Button button_search_pwd;
  private Button button_status;
  private TextView tv_content;
  private TextView title_right_text;
  private Connection connection;
  private GenericWIFI wifi;
  private ReadMark readMark = ReadMark.NONE;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_wifi);
    wifi_name = (EditText) findViewById(R.id.wifi_name);
    wifi_pwd = (EditText) findViewById(R.id.wifi_pwd);
    title_right_text = (TextView) findViewById(R.id.title_right_text);
    button_send = (Button) findViewById(R.id.button_send);
    button_search_name = (Button) findViewById(R.id.button_search_name);
    button_search_pwd = (Button) findViewById(R.id.button_search_pwd);
    button_status = (Button) findViewById(R.id.button_status);
    tv_content = (TextView) findViewById(R.id.tv_content);
    BluetoothDevice device = getIntent().getParcelableExtra("device");
    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        wifi = WIFI.generic(connectedDevice);
        dataListen(connectedDevice);
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
              title_right_text.setText(device.getName() + msg);
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
    button_search_name.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_WIFI_NAME;
        GenericWIFI _gesc = wifi.getSSID();
        safeWrite(_gesc);
      }
    });
    button_search_pwd.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_WIFI_PASSWORD;
        GenericWIFI _gesc = wifi.getPassword();
        safeWrite(_gesc);
      }
    });
    button_status.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_WIFI_LINK_STATE;
        GenericWIFI _gesc = wifi.state();
        safeWrite(_gesc);
      }
    });
    button_send.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        String wifiName = wifi_name.getText().toString().trim();
        String wifiPwd = wifi_pwd.getText().toString().trim();
        if (!wifiName.equals("") && !wifiPwd.equals("")) {
          readMark = ReadMark.OPERATE_WIFI_LINK_STATE;
          GenericWIFI _gesc = wifi.setSSID(WSetSSID.builder().name(wifiName).password(wifiPwd).build());
          safeWrite(_gesc);
        } else {
          Toast.makeText(WIFIActivity.this, "名称或密码为空", Toast.LENGTH_LONG).show();
        }
      }
    });


  }

  private void dataListen(ConnectedDevice connectedDevice) {
    DataListenerRunner dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
          switch (readMark) {
            case OPERATE_WIFI_NAME:
              readMark = ReadMark.NONE;
              String SSID = "";
              try {
                SSID = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String contentSSID = "WIFI名称:" + SSID;
              runOnUiThread(() -> tv_content.setText(contentSSID));
              break;
            case OPERATE_WIFI_PASSWORD:
              readMark = ReadMark.NONE;
              String PWD = "";
              try {
                PWD = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String contentPWD = "WIFI密码:" + PWD;
              runOnUiThread(() -> tv_content.setText(contentPWD));
              break;
            case OPERATE_WIFI_LINK_STATE:
              readMark = ReadMark.NONE;
              String linkState = "";
              try {
                linkState = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String content = "wifi连接状态:" + linkState;
              runOnUiThread(() -> tv_content.setText(content));
              break;
            default:

              break;
          }
        }
      })
      .start();
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

  private String ByteArrToHex(byte[] inBytArr) {
    StringBuilder strBuilder = new StringBuilder();
    int j = inBytArr.length;
    for (int i = 0; i < j; i++) {
      strBuilder.append(Byte2Hex(inBytArr[i]));
      strBuilder.append(":");
    }
    return strBuilder.toString();
  }

  private String Byte2Hex(Byte inByte) {
    return String.format("%02x", inByte).toUpperCase();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }
}
