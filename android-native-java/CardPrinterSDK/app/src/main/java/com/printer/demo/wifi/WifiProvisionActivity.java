package com.printer.demo.wifi;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.printer.demo.R;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.wifi.GenericWIFI;
import com.printer.psdk.wifi.WIFI;
import com.printer.psdk.wifi.args.WSetSSID;
import com.printer.psdk.wifi.args.WSetWifiIP;
import com.printer.psdk.wifi.args.WSetWifiLAP;

import java.io.IOException;
import java.util.regex.Pattern;

/**
 * Printer Wi-Fi provisioning copied from generic-android-demo WIFIActivity.
 * Commands go through psdk GenericWIFI over BLE, not libCardPrinter.
 */
public class WifiProvisionActivity extends Activity {
    public static final String EXTRA_DEVICE = "device";
    public static final String EXTRA_PRINTER_ADDRESS = "printer_address";
    private static final int PRINTER_PORT = 9100;
    private static final Pattern IP_PATTERN = Pattern.compile(
            "^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$");

    private EditText wifiName;
    private EditText wifiPassword;
    private EditText etIpAddress;
    private EditText etGateway;
    private EditText etNetmask;
    private RadioButton dhcpRadio;
    private RadioButton staticIpRadio;
    private View staticIpSettings;
    private TextView tvContent;
    private TextView titleRightText;
    private Button useIpButton;
    private Connection connection;
    private GenericWIFI wifi;
    private ReadMark readMark = ReadMark.NONE;
    private String lastPrinterIp;

    @SuppressLint("MissingPermission")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_wifi_provision);
        bindViews();
        BluetoothDevice device = getIntent().getParcelableExtra(EXTRA_DEVICE);
        if (device == null) {
            finish();
            return;
        }
        if (!Bluetooth.getInstance().isInitialized()) {
            Bluetooth.getInstance().initialize(getApplication());
        }
        connection = Bluetooth.getInstance().createConnectionBle(device, new ConnectListener() {
            @Override
            public void onConnectSuccess(ConnectedDevice connectedDevice) {
                wifi = WIFI.generic(connectedDevice);
                dataListen(connectedDevice);
            }

            @Override
            public void onConnectFail(String errMsg, Throwable e) {
                showState(deviceLabel(device) + "连接失败");
            }

            @Override
            public void onConnectionStateChanged(BluetoothDevice changed, int state) {
                String msg = stateMessage(state);
                if (!msg.isEmpty()) {
                    showState(deviceLabel(changed == null ? device : changed) + msg);
                }
            }
        });
        if (connection == null) {
            toast("创建蓝牙连接失败");
            finish();
            return;
        }
        new Thread(() -> connection.connect(null)).start();
        bindActions(device);
        fillCurrentWifiName();
    }

    private void bindViews() {
        wifiName = findViewById(R.id.wifi_name);
        wifiPassword = findViewById(R.id.wifi_pwd);
        titleRightText = findViewById(R.id.title_right_text);
        tvContent = findViewById(R.id.tv_content);
        dhcpRadio = findViewById(R.id.dhcp_radio);
        staticIpRadio = findViewById(R.id.static_ip_radio);
        staticIpSettings = findViewById(R.id.static_ip_settings);
        etIpAddress = findViewById(R.id.ip_address);
        etGateway = findViewById(R.id.gateway);
        etNetmask = findViewById(R.id.netmask);
        useIpButton = findViewById(R.id.button_use_ip);
        RadioGroup ipType = findViewById(R.id.ip_type_radio_group);
        ipType.setOnCheckedChangeListener((group, checkedId) ->
                staticIpSettings.setVisibility(checkedId == R.id.static_ip_radio ? View.VISIBLE : View.GONE));
    }

    @SuppressLint("MissingPermission")
    private void bindActions(BluetoothDevice device) {
        findViewById(R.id.button_search_name).setOnClickListener(v -> query(ReadMark.WIFI_NAME, wifi == null ? null : wifi.getSSID()));
        findViewById(R.id.button_search_pwd).setOnClickListener(v -> query(ReadMark.WIFI_PASSWORD, wifi == null ? null : wifi.getPassword()));
        findViewById(R.id.button_status).setOnClickListener(v -> query(ReadMark.WIFI_LINK_STATE, wifi == null ? null : wifi.state()));
        findViewById(R.id.button_search_dhcp).setOnClickListener(v -> query(ReadMark.WIFI_DHCP, wifi == null ? null : wifi.getWifiDHCP()));
        findViewById(R.id.button_get_wifi_role).setOnClickListener(v -> query(ReadMark.WIFI_ROLE, wifi == null ? null : wifi.getWifiRole()));
        findViewById(R.id.button_get_apssid).setOnClickListener(v -> query(ReadMark.WIFI_APSSID, wifi == null ? null : wifi.getWifiAPSSID()));
        findViewById(R.id.button_get_appassword).setOnClickListener(v -> query(ReadMark.WIFI_APPASSWORD, wifi == null ? null : wifi.getWifiAPPASSWORD()));
        findViewById(R.id.button_get_info).setOnClickListener(v -> query(ReadMark.ALL_WIFI_INFO, wifi == null ? null : wifi.getWifiInfo()));
        findViewById(R.id.button_get_ip).setOnClickListener(v -> {
            if (wifi == null) {
                query(ReadMark.ALL_IP_INFO, null);
                return;
            }
            query(ReadMark.ALL_IP_INFO, wifi.getWifiIP().getWifiMASK().getWifiGATEWAY());
        });
        findViewById(R.id.button_reset).setOnClickListener(v -> {
            if (!ensureReady()) {
                return;
            }
            safeWrite(wifi.reset());
            toast("已发送重置配网信息");
        });
        findViewById(R.id.button_send).setOnClickListener(v -> sendSsid());
        findViewById(R.id.button_set_ip).setOnClickListener(v -> sendIp());
        findViewById(R.id.button_set_wifi_role).setOnClickListener(v -> chooseRole());
        findViewById(R.id.button_set_wifi_lap).setOnClickListener(v -> editApParams(device));
        useIpButton.setOnClickListener(v -> returnPrinterAddress());
    }

    private void sendSsid() {
        if (!ensureReady()) {
            return;
        }
        String name = wifiName.getText().toString().trim();
        String pwd = wifiPassword.getText().toString().trim();
        if (name.isEmpty() || "未连接WiFi".equals(name)) {
            toast("请输入WiFi名称");
            return;
        }
        safeWrite(wifi.setSSID(WSetSSID.builder().name(name).password(pwd).build()));
        toast("已发送设置wifi名称密码");
        tvContent.setText("配网指令已发送: " + name);
    }

    private void sendIp() {
        if (!ensureReady()) {
            return;
        }
        if (dhcpRadio.isChecked()) {
            safeWrite(wifi.setWifiDHCP());
            toast("已发送动态IP设置");
            return;
        }
        String ip = etIpAddress.getText().toString().trim();
        String mask = etNetmask.getText().toString().trim();
        String gateway = etGateway.getText().toString().trim();
        if (!isValidIp(ip) || !isValidIp(mask) || !isValidIp(gateway)) {
            toast("请检查IP、掩码和网关");
            return;
        }
        safeWrite(wifi.setWifiIP(WSetWifiIP.builder().ip(ip).mask(mask).gateway(gateway).build()));
        rememberPrinterIp(ip);
        toast("已发送静态IP设置");
    }

    private void chooseRole() {
        if (!ensureReady()) {
            return;
        }
        final String[] items = {"STA模式(1)", "AP模式(2)", "共享模式(3)"};
        final int[] roles = {1, 2, 3};
        new AlertDialog.Builder(this)
                .setTitle("选择WIFI工作模式")
                .setItems(items, (dialog, which) -> {
                    safeWrite(wifi.setWifiRole(roles[which]));
                    toast("已发送设置WIFI模式(" + items[which] + ")，模块会自动重启");
                })
                .show();
    }

    @SuppressLint("MissingPermission")
    private void editApParams(BluetoothDevice device) {
        if (!ensureReady()) {
            return;
        }
        EditText etSsid = new EditText(this);
        etSsid.setHint("AP模式WiFi名称(SSID)");
        try {
            if (device.getName() != null) {
                etSsid.setText(device.getName());
            }
        } catch (Exception ignored) {
        }
        EditText etPwd = new EditText(this);
        etPwd.setHint("AP模式WiFi密码(可为空)");
        EditText etIp = new EditText(this);
        etIp.setHint("AP模式IP地址(默认192.168.1.1)");
        etIp.setText("192.168.1.1");
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 20, 50, 20);
        layout.addView(etSsid);
        layout.addView(etPwd);
        layout.addView(etIp);
        new AlertDialog.Builder(this)
                .setTitle("设置AP模式WIFI参数")
                .setView(layout)
                .setPositiveButton("发送", (dialog, which) -> {
                    String ssid = etSsid.getText().toString().trim();
                    String pwd = etPwd.getText().toString().trim();
                    String ip = etIp.getText().toString().trim();
                    if (ssid.isEmpty()) {
                        toast("SSID不能为空");
                        return;
                    }
                    if (ip.isEmpty()) {
                        ip = "192.168.1.1";
                    }
                    safeWrite(wifi.setWifiLAP(WSetWifiLAP.builder().ssid(ssid).password(pwd).ip(ip).build()));
                    rememberPrinterIp(ip);
                    toast("已发送设置AP模式WIFI参数");
                })
                .setNegativeButton("取消", null)
                .show();
    }

    private void query(ReadMark mark, GenericWIFI command) {
        if (!ensureReady() || command == null) {
            if (command == null) {
                toast("请先连接设备");
            }
            return;
        }
        readMark = mark;
        safeWrite(command);
    }

    private boolean ensureReady() {
        if (!isConnected() || wifi == null) {
            toast("请先连接设备");
            return false;
        }
        return true;
    }

    private void dataListen(ConnectedDevice connectedDevice) {
        DataListener.with(connectedDevice).listen((ListenAction) received -> {
            ReadMark mark = readMark;
            readMark = ReadMark.NONE;
            String text = decode(received);
            switch (mark) {
                case WIFI_NAME:
                    showContent("WIFI名称:" + text);
                    break;
                case WIFI_PASSWORD:
                    showContent("WIFI密码:" + text);
                    break;
                case WIFI_LINK_STATE:
                    boolean connected = false;
                    if (text.contains("GETLINKSTATE:")) {
                        String status = text.replace("GETLINKSTATE:", "").split(",")[0];
                        connected = "Connected".equals(status.trim());
                    }
                    showContent("wifi连接状态:" + (connected ? "已连接" : "未连接"));
                    break;
                case WIFI_DHCP:
                    boolean dhcp = "1".equals(text.replace("\r", "").replace("\n", ""));
                    runOnUiThread(() -> {
                        if (dhcp) {
                            dhcpRadio.setChecked(true);
                        } else {
                            staticIpRadio.setChecked(true);
                        }
                        tvContent.setText("DHCP:" + (dhcp ? "动态" : "静态"));
                    });
                    break;
                case ALL_IP_INFO:
                    String[] infos = text.split("\\r?\\n");
                    if (infos.length > 2) {
                        String ip = infos[0].trim();
                        String mask = infos[1].trim();
                        String gateway = infos[2].trim();
                        runOnUiThread(() -> {
                            tvContent.setText("ip:" + ip + "\n子网掩码:" + mask + "\n网关:" + gateway);
                            etIpAddress.setText(ip);
                            etNetmask.setText(mask);
                            etGateway.setText(gateway);
                            rememberPrinterIp(ip);
                        });
                    } else {
                        showContent(text);
                    }
                    break;
                case ALL_WIFI_INFO:
                    showContent("WIFI相关信息:" + text);
                    break;
                case WIFI_ROLE:
                    showContent("WIFI工作模式:" + roleText(text.replace("\r", "").replace("\n", "")));
                    break;
                case WIFI_APSSID:
                    showContent("AP模式SSID:" + text);
                    break;
                case WIFI_APPASSWORD:
                    showContent("AP模式密码:" + text);
                    break;
                default:
                    break;
            }
        }).start();
    }

    private void rememberPrinterIp(String ip) {
        if (!isValidIp(ip)) {
            return;
        }
        lastPrinterIp = ip;
        useIpButton.setEnabled(true);
        useIpButton.setText("使用此IP打印 (" + ip + ":" + PRINTER_PORT + ")");
    }

    private void returnPrinterAddress() {
        if (!isValidIp(lastPrinterIp)) {
            toast("还没有可用的打印机IP");
            return;
        }
        Intent data = new Intent();
        data.putExtra(EXTRA_PRINTER_ADDRESS, lastPrinterIp + ":" + PRINTER_PORT);
        setResult(RESULT_OK, data);
        finish();
    }

    private void fillCurrentWifiName() {
        WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wifiManager == null) {
            return;
        }
        WifiInfo info = wifiManager.getConnectionInfo();
        if (info == null || info.getSSID() == null) {
            return;
        }
        String ssid = info.getSSID().replace("\"", "");
        if (ssid.isEmpty() || "<unknown ssid>".equals(ssid)) {
            return;
        }
        wifiName.setText(ssid);
    }

    private boolean isValidIp(String input) {
        return input != null && IP_PATTERN.matcher(input).matches();
    }

    private void safeWrite(PSDK psdk) {
        try {
            WroteReporter reporter = psdk.write();
            if (!reporter.isOk()) {
                throw new IOException("写入数据失败", reporter.getException());
            }
        } catch (Exception e) {
            e.printStackTrace();
            toast("写入失败");
        }
    }

    private boolean isConnected() {
        try {
            return connection != null && connection.isConnected();
        } catch (Exception e) {
            return false;
        }
    }

    private void showContent(String content) {
        runOnUiThread(() -> tvContent.setText(content));
    }

    private void showState(String content) {
        runOnUiThread(() -> titleRightText.setText(content));
    }

    private void toast(String message) {
        runOnUiThread(() -> Toast.makeText(this, message, Toast.LENGTH_SHORT).show());
    }

    @SuppressLint("MissingPermission")
    private String deviceLabel(BluetoothDevice device) {
        try {
            String name = device.getName();
            if (name != null && !name.isEmpty()) {
                return name;
            }
        } catch (Exception ignored) {
        }
        return "";
    }

    private String stateMessage(int state) {
        switch (state) {
            case Connection.STATE_CONNECTING:
                return "连接中";
            case Connection.STATE_PAIRING:
                return "配对中...";
            case Connection.STATE_PAIRED:
                return "配对成功";
            case Connection.STATE_CONNECTED:
                return "连接成功";
            case Connection.STATE_DISCONNECTED:
                return "连接断开";
            case Connection.STATE_RELEASED:
                return "连接已销毁";
            default:
                return "";
        }
    }

    private String roleText(String role) {
        switch (role) {
            case "1":
                return "STA模式(1)";
            case "2":
                return "AP模式(2)";
            case "3":
                return "共享模式(3)";
            default:
                return role;
        }
    }

    private String decode(byte[] received) {
        if (received == null) {
            return "";
        }
        try {
            return new String(received, "GB2312").trim();
        } catch (Exception e) {
            return new String(received).trim();
        }
    }

    @Override
    protected void onDestroy() {
        if (connection != null) {
            try {
                connection.disconnect();
            } catch (Exception ignored) {
            }
        }
        super.onDestroy();
    }

    private enum ReadMark {
        NONE,
        WIFI_NAME,
        WIFI_PASSWORD,
        WIFI_LINK_STATE,
        WIFI_DHCP,
        ALL_IP_INFO,
        ALL_WIFI_INFO,
        WIFI_ROLE,
        WIFI_APSSID,
        WIFI_APPASSWORD
    }
}