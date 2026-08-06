package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothDevice;
import android.content.DialogInterface;
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
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.args.common.Raw;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.wifi.GenericWIFI;
import com.printer.psdk.wifi.WIFI;
import com.printer.psdk.wifi.args.WSetSSID;
import com.printer.psdk.wifi.args.WSetWifiIP;
import com.printer.psdk.wifi.args.WSetWifiRole;
import com.printer.psdk.wifi.args.WSetWifiLAP;
import com.printer.psdk.wifi.args.WGetWifiAPSSID;
import com.printer.psdk.wifi.args.WGetWifiAPPASSWORD;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class WIFIActivity extends Activity {
  private EditText wifi_name, wifi_pwd;
  private EditText etIpAddress, etGateway, etNetmask;
  private Button button_send, button_search_name, button_search_pwd, button_status, button_search_dhcp, button_reset;
  private Button btnSetIp, btnGetIp, btnInfo;
  private Button button_set_wifi_role, button_get_wifi_role;
  private Button button_set_wifi_lap, button_get_apssid, button_get_appassword;
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
    button_reset = (Button) findViewById(R.id.button_reset);
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
    btnInfo = findViewById(R.id.button_get_info);
    button_set_wifi_role = findViewById(R.id.button_set_wifi_role);
    button_get_wifi_role = findViewById(R.id.button_get_wifi_role);
    button_set_wifi_lap = findViewById(R.id.button_set_wifi_lap);
    button_get_apssid = findViewById(R.id.button_get_apssid);
    button_get_appassword = findViewById(R.id.button_get_appassword);
    BluetoothDevice device = getIntent().getParcelableExtra("device");
    connection = Bluetooth.getInstance().createConnectionBle(device, new ConnectListener() {
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
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_NAME;
        GenericWIFI _gesc = wifi.getSSID();
        safeWrite(_gesc);
      }
    });
    button_search_pwd.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_PASSWORD;
        GenericWIFI _gesc = wifi.getPassword();
        safeWrite(_gesc);
      }
    });
    button_status.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_LINK_STATE;
        GenericWIFI _gesc = wifi.state();
        safeWrite(_gesc);
      }
    });
    button_reset.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        GenericWIFI _gesc = wifi.reset();
        safeWrite(_gesc);
      }
    });
    button_search_dhcp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_DHCP;
        GenericWIFI _gesc = wifi.getWifiDHCP();
        safeWrite(_gesc);
      }
    });
    button_send.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        String wifiName = wifi_name.getText().toString().trim();
        String wifiPwd = wifi_pwd.getText().toString().trim();
        if (!wifiName.equals("")) {
          GenericWIFI _gesc = wifi.setSSID(WSetSSID.builder().name(wifiName).password(wifiPwd).build());
          safeWrite(_gesc);
        } else {
          Util.show(WIFIActivity.this, "名称或密码为空");
        }
      }
    });
    btnSetIp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        if(dhcp_radio.isChecked()){
          GenericWIFI _gesc = wifi.setWifiDHCP();//设置成动态ip
          safeWrite(_gesc);
          return;
        }
        String ip = etIpAddress.getText().toString();
        String mask = etNetmask.getText().toString();
        String gateway = etGateway.getText().toString();
        if (!isValidInput(ip)) {
          Util.show(WIFIActivity.this, "检查输入的ip");
          return;
        }
        if (!isValidInput(mask)) {
          Util.show(WIFIActivity.this, "检查输入的子网掩码");
          return;
        }
        if (!isValidInput(gateway)) {
          Util.show(WIFIActivity.this, "检查输入的网关");
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
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_ALL_IP_INFO;
        GenericWIFI _gesc = wifi.getWifiIP().getWifiMASK().getWifiGATEWAY();//查询相关信息
        safeWrite(_gesc);
      }
    });
    btnInfo.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_ALL_WIFI_INFO;
        GenericWIFI _gesc = wifi.getWifiInfo();//查询wifi相关信息
        safeWrite(_gesc);
      }
    });
    button_set_wifi_role.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        final String[] items = {"STA模式(1)", "AP模式(2)", "共享模式(3)"};
        final int[] proles = {1, 2, 3};
        new AlertDialog.Builder(WIFIActivity.this)
          .setTitle("选择WIFI工作模式")
          .setItems(items, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
              GenericWIFI _gesc = wifi.setWifiRole(proles[which]);
              safeWrite(_gesc);
              Util.show(WIFIActivity.this, "已发送设置WIFI模式(" + items[which] + ")，模块会自动重启");
            }
          })
          .show();
      }
    });
    button_get_wifi_role.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_ROLE;
        GenericWIFI _gesc = wifi.getWifiRole();//查询WIFI工作模式
        safeWrite(_gesc);
      }
    });
    button_set_wifi_lap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        final EditText etSsid = new EditText(WIFIActivity.this);
        etSsid.setHint("AP模式WiFi名称(SSID)");
        // 默认填入蓝牙设备名称
        try {
          if (device != null && device.getName() != null) {
            etSsid.setText(device.getName());
          }
        } catch (Exception e) {
          // 获取名称失败时忽略，让用户手动输入
        }
        final EditText etPwd = new EditText(WIFIActivity.this);
        etPwd.setHint("AP模式WiFi密码(可为空)");
        final EditText etIp = new EditText(WIFIActivity.this);
        etIp.setHint("AP模式IP地址(默认192.168.1.1)");
        etIp.setText("192.168.1.1");
        LinearLayout layout = new LinearLayout(WIFIActivity.this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 20, 50, 20);
        layout.addView(etSsid);
        layout.addView(etPwd);
        layout.addView(etIp);
        new AlertDialog.Builder(WIFIActivity.this)
          .setTitle("设置AP模式WIFI参数")
          .setView(layout)
          .setPositiveButton("发送", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
              String ssid = etSsid.getText().toString().trim();
              String pwd = etPwd.getText().toString().trim();
              String ip = etIp.getText().toString().trim();
              if (ssid.isEmpty()) {
                Util.show(WIFIActivity.this, "SSID不能为空");
                return;
              }
              if (ip.isEmpty()) {
                ip = "192.168.1.1";
              }
              GenericWIFI _gesc = wifi.setWifiLAP(
                WSetWifiLAP.builder().ssid(ssid).password(pwd).ip(ip).build());
              safeWrite(_gesc);
              Util.show(WIFIActivity.this, "已发送设置AP模式WIFI参数(SSID/密码/IP)");
            }
          })
          .setNegativeButton("取消", null)
          .show();
      }
    });
    button_get_apssid.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_APSSID;
        GenericWIFI _gesc = wifi.getWifiAPSSID();//查询AP模式SSID
        safeWrite(_gesc);
      }
    });
    button_get_appassword.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (!isConnected()) {
          Util.show(WIFIActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_WIFI_APPASSWORD;
        GenericWIFI _gesc = wifi.getWifiAPPASSWORD();//查询AP模式密码
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
            case OPERATE_ALL_WIFI_INFO:
              readMark = ReadMark.NONE;
              String wifiInfo = "";
              try {
                wifiInfo = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String contentWifiInfo = "WIFI相关信息:" + wifiInfo;
              runOnUiThread(() -> tv_content.setText(contentWifiInfo));
              break;
            case OPERATE_WIFI_ROLE:
              readMark = ReadMark.NONE;
              String role = "";
              try {
                role = new String(received, "GB2312").replace("\r\n", "");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String roleDesc;
              switch (role) {
                case "1":
                  roleDesc = "STA模式(1)";
                  break;
                case "2":
                  roleDesc = "AP模式(2)";
                  break;
                case "3":
                  roleDesc = "共享模式(3)";
                  break;
                default:
                  roleDesc = role;
                  break;
              }
              String contentRole = "WIFI工作模式:" + roleDesc;
              runOnUiThread(() -> tv_content.setText(contentRole));
              break;
            case OPERATE_WIFI_APSSID:
              readMark = ReadMark.NONE;
              String apSsid = "";
              try {
                apSsid = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String contentApSsid = "AP模式SSID:" + apSsid;
              runOnUiThread(() -> tv_content.setText(contentApSsid));
              break;
            case OPERATE_WIFI_APPASSWORD:
              readMark = ReadMark.NONE;
              String apPwd = "";
              try {
                apPwd = new String(received, "GB2312");
              } catch (Exception e) {
                e.printStackTrace();
              }
              String contentApPwd = "AP模式密码:" + apPwd;
              runOnUiThread(() -> tv_content.setText(contentApPwd));
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
