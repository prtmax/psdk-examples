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
import com.printer.psdk.wifi.args.WSetWifiIP;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class WIFIActivity extends Activity {
  private EditText wifi_name, wifi_pwd;
  private EditText etIpAddress, etGateway, etNetmask;
  private Button button_send, button_search_name, button_search_pwd, button_status, button_search_dhcp;
  private Button btnSetIp, btnGetIp;
  private RadioGroup rgIpType;
  private RadioButton dhcp_radio, static_ip_radio;
  private View staticIpSettings;
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
    button_search_dhcp = (Button) findViewById(R.id.button_search_dhcp);
    rgIpType = findViewById(R.id.ip_type_radio_group);
    dhcp_radio = findViewById(R.id.dhcp_radio);
    static_ip_radio = findViewById(R.id.static_ip_radio);
    staticIpSettings = findViewById(R.id.static_ip_settings);
    etIpAddress = findViewById(R.id.ip_address);
    etGateway = findViewById(R.id.gateway);
    etNetmask = findViewById(R.id.netmask);
    btnSetIp = findViewById(R.id.button_set_ip);
    btnGetIp = findViewById(R.id.button_get_ip);
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
    button_search_dhcp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_WIFI_DHCP;
        GenericWIFI _gesc = wifi.getWifiDHCP();
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
    btnSetIp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if(dhcp_radio.isChecked()){
          GenericWIFI _gesc = wifi.setWifiDHCP();//设置成动态ip
          safeWrite(_gesc);
          return;
        }
        String ip = etIpAddress.getText().toString();
        String mask = etNetmask.getText().toString();
        String gateway = etGateway.getText().toString();
        if (!isValidInput(ip)) {
          Toast.makeText(WIFIActivity.this, "检查输入的ip", Toast.LENGTH_LONG).show();
          return;
        }
        if (!isValidInput(mask)) {
          Toast.makeText(WIFIActivity.this, "检查输入的子网掩码", Toast.LENGTH_LONG).show();
          return;
        }
        if (!isValidInput(gateway)) {
          Toast.makeText(WIFIActivity.this, "检查输入的网关", Toast.LENGTH_LONG).show();
          return;
        }
        //设置成静态ip需传入相关信息
        GenericWIFI _gesc = wifi.setWifiIP(WSetWifiIP.builder().ip(ip).mask(mask).gateway(gateway).build());
        safeWrite(_gesc);
      }
    });
    btnGetIp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        readMark = ReadMark.OPERATE_ALL_IP_INFO;
        GenericWIFI _gesc = wifi.getWifiIP().getWifiMASK().getWifiGATEWAY();//查询相关信息
        safeWrite(_gesc);
      }
    });
    rgIpType.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(RadioGroup group, int checkedId) {
        if (checkedId == R.id.static_ip_radio) {
          staticIpSettings.setVisibility(View.VISIBLE);
        } else {
          staticIpSettings.setVisibility(View.GONE);
        }
      }
    });
  }

  /// 校验格式
  private boolean isValidInput(String input) {
    final String IP_REGEX = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    Pattern pattern = Pattern.compile(IP_REGEX);
    Matcher matcher = pattern.matcher(input);
    return matcher.matches();
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
              boolean wifiConnected = false;
              if (linkState.contains("GETLINKSTATE:")) {
                String status = linkState.replaceAll("GETLINKSTATE:", "").split(",")[0];
                wifiConnected = status.equals("Connected");
              }
              String content = "wifi连接状态:" + (wifiConnected ? "已连接" : "未连接");
              runOnUiThread(() -> tv_content.setText(content));
              break;
            case OPERATE_WIFI_DHCP:
              readMark = ReadMark.NONE;
              String dhcp = "";
              try {
                dhcp = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              boolean isDHCP = dhcp.replace("\r\n", "").equals("1");
              String contentDHCP = "DHCP:" + (isDHCP ? "动态" : "静态");
              runOnUiThread(() -> {
                if (isDHCP) {
                  dhcp_radio.setChecked(true);
                } else {
                  static_ip_radio.setChecked(true);
                }
                tv_content.setText(contentDHCP);
              });
              break;
            case OPERATE_ALL_IP_INFO:
              readMark = ReadMark.NONE;
              String ipInfo = "";
              try {
                ipInfo = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String[] infos = ipInfo.split("\r\n");
              if (infos.length > 2) {
                String ip = infos[0];
                String mask = infos[1];
                String gateway = infos[2];
                String contentIpInfo = "ip:" + ip + "\n" + "子网掩码:" + mask + "\n" + "网关:" + gateway;
                runOnUiThread(() -> {
                  tv_content.setText(contentIpInfo);
                  etIpAddress.setText(ip);
                  etNetmask.setText(mask);
                  etGateway.setText(gateway);
                });
              }
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
