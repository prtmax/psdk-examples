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
import com.example.classic_bluetooth_demo.util.Util;
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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

public class ESCWIFIActivity extends Activity {
  private static final String[] PRODUCTION_HOSTS = {
          "https://cprint-api.iprtapp.com",
          "https://cprint-api.aynapp.aiyinprinter.com.cn",
          "https://cprint-api.aynapp.aiyinprinter.com",
          "https://cprint-api.aynapp.aiyin.com",
          "https://cprint-api.aynapp.ai-yin.cn",
          "https://cprint-api.aynapp.ai-yin.com",
          "https://cprint-api.aynapp.ai-yin.com.cn"
  };
  private static final String[] STAGING_HOSTS = {
          "https://cprint-api-stg.iprtapp.com",
          "https://cprint-api-stg.aynapp.aiyinprinter.com.cn",
          "https://cprint-api-stg.aynapp.aiyinprinter.com",
          "https://cprint-api-stg.aynapp.aiyin.com",
          "https://cprint-api-stg.aynapp.ai-yin.cn",
          "https://cprint-api-stg.aynapp.ai-yin.com",
          "https://cprint-api-stg.aynapp.ai-yin.com.cn"
  };

  private EditText wifi_name, wifi_pwd;
  private Button button_send, button_status, button_get_wifi_name, button_get_key, button_get_sn;
  private TextView tv_content;
  private TextView title_right_text;
  private Connection connection;
  private GenericESC esc;
  private ReadMark readMark = ReadMark.NONE;
  // 新增控件变量
  private EditText et_key, et_host_custom;
  private Button btn_set_key, btn_set_host, btn_host_production, btn_host_staging;
  private TextView tv_host_environment;
  private CheckBox[] hostCheckBoxes;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_esc_wifi);
    wifi_name = (EditText) findViewById(R.id.wifi_name);
    wifi_pwd = (EditText) findViewById(R.id.wifi_pwd);
    title_right_text = (TextView) findViewById(R.id.title_right_text);
    button_send = (Button) findViewById(R.id.button_send);
    button_status = (Button) findViewById(R.id.button_status);
    button_get_wifi_name = (Button) findViewById(R.id.button_get_wifi_name);
    button_get_key = (Button) findViewById(R.id.button_get_key);
    button_get_sn = (Button) findViewById(R.id.button_get_sn);
    tv_content = (TextView) findViewById(R.id.tv_content);
    et_key = (EditText) findViewById(R.id.et_key);
    btn_set_key = (Button) findViewById(R.id.btn_set_key);
    et_host_custom = (EditText) findViewById(R.id.et_host_custom);
    btn_set_host = (Button) findViewById(R.id.btn_set_host);
    btn_host_production = (Button) findViewById(R.id.btn_host_production);
    btn_host_staging = (Button) findViewById(R.id.btn_host_staging);
    tv_host_environment = (TextView) findViewById(R.id.tv_host_environment);
    hostCheckBoxes = new CheckBox[]{
            (CheckBox) findViewById(R.id.cb_host1),
            (CheckBox) findViewById(R.id.cb_host2),
            (CheckBox) findViewById(R.id.cb_host3),
            (CheckBox) findViewById(R.id.cb_host4),
            (CheckBox) findViewById(R.id.cb_host5),
            (CheckBox) findViewById(R.id.cb_host6),
            (CheckBox) findViewById(R.id.cb_host7)
    };
    setHostPreset(PRODUCTION_HOSTS, "正式");
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
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_LINK_STATE;
        GenericESC _gesc = esc.getWifiSta();
        safeWrite(_gesc);
      }
    });
    button_get_wifi_name.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_ESC_WIFI_NAME;
        GenericESC _gesc = esc.getWifiName();
        safeWrite(_gesc);
      }
    });
    button_get_key.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_GET_KEY;
        GenericESC _gesc = esc.getKey();
        safeWrite(_gesc);
      }
    });
    button_send.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        String wifiName = wifi_name.getText().toString().trim();
        String wifiPwd = wifi_pwd.getText().toString().trim();
        if (!wifiName.equals("")) {
          readMark = ReadMark.OPERATE_SET_WIFI;
          GenericESC _gesc = esc.setWifi(ESetWifi.builder().ssid(wifiName).password(wifiPwd).build());
          safeWrite(_gesc);
        } else {
          Util.show(ESCWIFIActivity.this, "名称或密码为空");
        }
      }
    });
    button_get_sn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_PRINTERSN;
        GenericESC _gesc = esc.sn();
        safeWrite(_gesc);
      }
    });
    // 设置秘钥按钮事件
    btn_set_key.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        String key = et_key.getText().toString().trim();
        if (key.isEmpty()) {
          Util.show(ESCWIFIActivity.this, "请输入设备秘钥");
          return;
        }
        readMark = ReadMark.OPERATE_SET_KEY;
        GenericESC _gesc = esc.setKey(key);
        safeWrite(_gesc);
      }
    });
    btn_host_production.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        setHostPreset(PRODUCTION_HOSTS, "正式");
      }
    });
    btn_host_staging.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        setHostPreset(STAGING_HOSTS, "测试");
      }
    });

    // 设置域名按钮事件
    btn_set_host.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCWIFIActivity.this, "请先连接设备");
          return;
        }
        List<String> hosts = new ArrayList<>();
        for (CheckBox hostCheckBox : hostCheckBoxes) {
          if (hostCheckBox.isChecked()) hosts.add(hostCheckBox.getText().toString());
        }
        String custom = et_host_custom.getText().toString().trim();
        if (!custom.isEmpty()) {
          String[] arr = custom.split("\\|");
          for (String s : arr) {
            String host = s.trim();
            if (!host.isEmpty()) hosts.add(host);
          }
        }
        if (hosts.isEmpty()) {
          Util.show(ESCWIFIActivity.this, "请至少选择或输入一个域名");
          return;
        }
        readMark = ReadMark.OPERATE_SET_HOST;
        GenericESC _gesc = esc.setHost(hosts);
        safeWrite(_gesc);
      }
    });

    // 获取当前设备连接的WiFi名称并填入输入框
    getCurrentWifiName();
  }

  private void setHostPreset(String[] hosts, String environment) {
    tv_host_environment.setText("当前：" + environment + "云打印域名");
    for (int i = 0; i < hostCheckBoxes.length; i++) {
      hostCheckBoxes[i].setText(hosts[i]);
      hostCheckBoxes[i].setChecked(true);
    }
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
                  case OPERATE_ESC_WIFI_NAME:
                    readMark = ReadMark.NONE;
                    String wifiName = new String(received, StandardCharsets.UTF_8);
                    runOnUiThread(() -> {
                      wifi_name.setText(wifiName);
                      tv_content.setText("打印机当前WiFi名称:" + wifiName);
                    });
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
                  case OPERATE_PRINTERSN:
                    readMark = ReadMark.NONE;
                    String sn = "";
                    try {
                      sn = new String(received, "GB2312");
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                    String snString = "打印机SN:" + sn;
                    runOnUiThread(() -> tv_content.setText(snString));
                    break;
                  case OPERATE_SET_KEY:
                    readMark = ReadMark.NONE;
                    String setKeyResult = "";
                    try {
                      setKeyResult = new String(received, "GB2312");
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                    String setKeyString = "设置秘钥:" + (setKeyResult.equals("OK") ? "成功" : "失败");
                    runOnUiThread(() -> tv_content.setText(setKeyString));
                    break;
                  case OPERATE_SET_HOST:
                    readMark = ReadMark.NONE;
                    String setHostResult = "";
                    try {
                      setHostResult = new String(received, "GB2312");
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                    String setHostString = "设置域名:" + (setHostResult.equals("OK") ? "成功" : "失败");
                    runOnUiThread(() -> tv_content.setText(setHostString));
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
  private boolean isConnected() {
    try {
      return connection != null && connection.isConnected();
    } catch (Exception e) {
      return false;
    }
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }
}
