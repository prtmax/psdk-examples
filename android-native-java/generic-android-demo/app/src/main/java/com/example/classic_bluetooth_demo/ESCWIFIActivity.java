package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import com.example.classic_bluetooth_demo.util.ReadMark;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.ESetWifi;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.wifi.GenericWIFI;
import com.printer.psdk.wifi.WIFI;
import com.printer.psdk.wifi.args.WSetSSID;
import com.printer.psdk.wifi.args.WSetWifiIP;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ESCWIFIActivity extends Activity {
  private EditText wifi_name, wifi_pwd;
  private EditText etIpAddress, etGateway, etNetmask;
  private Button button_send, button_search_name, button_search_pwd, button_status, button_get_key;
  private TextView tv_content;
  private TextView title_right_text;
  private Connection connection;
  private GenericESC esc;
  private ReadMark readMark = ReadMark.NONE;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_esc_wifi);
    wifi_name = (EditText) findViewById(R.id.wifi_name);
    wifi_pwd = (EditText) findViewById(R.id.wifi_pwd);
    title_right_text = (TextView) findViewById(R.id.title_right_text);
    button_send = (Button) findViewById(R.id.button_send);
    button_status = (Button) findViewById(R.id.button_status);
    button_get_key = (Button) findViewById(R.id.button_get_key);
    tv_content = (TextView) findViewById(R.id.tv_content);
    BluetoothDevice device = getIntent().getParcelableExtra("device");
    connection = Bluetooth.getInstance().createConnectionBle(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        esc = ESC.generic(connectedDevice);
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

    button_status.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_WIFI_LINK_STATE;
        GenericESC _gesc = esc.getWifiSta();
        safeWrite(_gesc);
      }
    });
    button_get_key.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_GET_KEY;
        GenericESC _gesc = esc.getKey();
        safeWrite(_gesc);
      }
    });
    button_send.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        String wifiName = wifi_name.getText().toString().trim();
        String wifiPwd = wifi_pwd.getText().toString().trim();
        if (!wifiName.equals("")) {
          readMark = ReadMark.OPERATE_SET_WIFI;
          GenericESC _gesc = esc.setWifi(ESetWifi.builder().ssid(wifiName).password(wifiPwd).build());
          safeWrite(_gesc);
        } else {
          Toast.makeText(ESCWIFIActivity.this, "名称或密码为空", Toast.LENGTH_LONG).show();
        }
      }
    });

    // 获取当前设备连接的WiFi名称并填入输入框
    getCurrentWifiName();
  }

  private void getCurrentWifiName() {
    WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
    if (wifiManager != null) {
      WifiInfo wifiInfo = wifiManager.getConnectionInfo();
      if (wifiInfo != null) {
        String ssid = wifiInfo.getSSID();
        if (ssid != null && !ssid.equals("<unknown ssid>")) {
          wifi_name.setText(ssid.replace("\"", ""));
        } else {
          wifi_name.setText("未连接WiFi");
        }
      } else {
        wifi_name.setText("未连接WiFi");
      }
    } else {
      wifi_name.setText("WiFi管理器不可用");
    }
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    DataListenerRunner dataListenerRunner = DataListener.with(connectedDevice)
            .listen(new ListenAction() {
              @Override
              public void action(byte[] received) {
                switch (readMark) {
                  case OPERATE_SET_WIFI:
                    readMark = ReadMark.NONE;
                    String result = "";
                    try {
                      result = new String(received, "GB2312");
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                    String resultString = "设置wifi:" + (result.equals("OK") ? "成功" : "失败");
                    runOnUiThread(() -> tv_content.setText(resultString));
                    break;
                  case OPERATE_WIFI_LINK_STATE:
                    readMark = ReadMark.NONE;
                    boolean wifiConnected = received.length == 2 && (received[1] == 0x01 || received[1] == 0x02);
                    String content = "wifi连接状态:" + (wifiConnected ? "已连接" : "未连接");
                    runOnUiThread(() -> tv_content.setText(content));
                    break;
                  case OPERATE_GET_KEY:
                    readMark = ReadMark.NONE;
                    String key = "";
                    try {
                      key = new String(received, "GB2312");
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                    String keyString = "打印机秘钥:" + key;
                    runOnUiThread(() -> tv_content.setText(keyString));
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

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }
}
