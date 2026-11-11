package com.printer.demo.view;

import android.Manifest;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.core.content.ContextCompat;

import com.dsj.printer.log.L;
import com.hjq.permissions.XXPermissions;
import com.printer.demo.GlobalPara;
import com.printer.sdk.comm.BleBluetoothHelper;
import com.printer.sdk.comm.BleDevice;
import com.printer.sdk.comm.WifiConnectHelper;
import com.printer.sdk.utils.ThreadLockUtils;
import com.printer.demo.utils.LoadingDialog;
import com.printer.demo.R;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public class BluetoothNetworkConfigView extends LinearLayout {
    private static final String TAG = "BluetoothConfigView";

    // UI组件
    private TextView tvScanTitle, tvScanDes, tvWifiModeTitle, tvAbtainWifiIpSuccess;
    private ListView deviceListView;
    private Button btStartBleScan, btnSwitch, btnNoSwitching, btnPrevious, btnNext, btnScanAgain;
    private LinearLayout scanLayout, wifiLayout, wifiModeLayout, wifiSuccessLayout;
    private EditText etWifiPassword, edWifiSSID;

    // 数据适配器
    private ArrayAdapter<String> deviceAdapter;
    private List<BleDevice> deviceList = new ArrayList<>();

    // 业务组件
    public BleBluetoothHelper bleBluetoothHelper;
    private WifiConnectHelper wifiHelper;
    private LoadingDialog loadingDialog;
    private Handler mainHandler;

    // 状态变量
    private boolean isAPConnect = false;
    private OnConfigSuccessListener configSuccessListener;
    private Context context;

    private static final int REQUEST_PERMISSIONS_CODE = 1001;
    private static final int REQUEST_ENABLE_BT = 1002;

    public BluetoothNetworkConfigView(Context context) {
        super(context);
        init(context);
    }

    public BluetoothNetworkConfigView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public BluetoothNetworkConfigView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        this.context = context;
        this.mainHandler = new Handler(Looper.getMainLooper());

        // 加载布局
        LayoutInflater.from(context).inflate(R.layout.bluetooth_config_view, this, true);

        // 初始化UI组件
        initViews();

        // 初始化蓝牙帮助类
        bleBluetoothHelper = new BleBluetoothHelper(context);
        setupBleCallbacks();

        // 初始化WiFi帮助类
        wifiHelper = new WifiConnectHelper(context);

        // 初始化加载对话框
        loadingDialog = new LoadingDialog(context);

        // 检查权限
        checkPermissions();
    }

    private void initViews() {
        // 扫描区域
        scanLayout = findViewById(R.id.scan_layout);
        tvScanTitle = findViewById(R.id.tv_scan_title);
        tvScanDes = findViewById(R.id.tv_scan_des);
        btStartBleScan = findViewById(R.id.bt_start_bleScan);
        deviceListView = findViewById(R.id.lv_bluetooth_devices);

        // WiFi模式选择区域
        wifiModeLayout = findViewById(R.id.wifi_mode_layout);
        tvWifiModeTitle = findViewById(R.id.tv_wifi_mode_title);
        btnSwitch = findViewById(R.id.btn_switch);
        btnNoSwitching = findViewById(R.id.btn_no_switching);

        // WiFi输入区域
        wifiLayout = findViewById(R.id.wifi_layout);
        edWifiSSID = findViewById(R.id.tv_wifi_SSID);
        etWifiPassword = findViewById(R.id.edit_wifi_password);
        btnPrevious = findViewById(R.id.btn_previous);
        btnNext = findViewById(R.id.btn_next);

        // WiFi成功区域
        wifiSuccessLayout = findViewById(R.id.wifi_success_layout);
        tvAbtainWifiIpSuccess = findViewById(R.id.tv_abtain_wifi_ip_success);
        btnScanAgain = findViewById(R.id.btn_scan_again);

        // 初始化设备列表适配器
        deviceAdapter = new ArrayAdapter<>(context, android.R.layout.simple_list_item_1);
        deviceListView.setAdapter(deviceAdapter);

        // 设置点击事件
        setupClickListeners();
    }

    private void setupClickListeners() {
        // 开始扫描
        btStartBleScan.setOnClickListener(v -> startScan());

        // 设备列表点击
        deviceListView.setOnItemClickListener((parent, view, position, id) -> {
            bleBluetoothHelper.stopScan();
            BleDevice device = deviceList.get(position);
            connectToDevice(device);
        });

        // 切换WiFi模式
        btnSwitch.setOnClickListener(v -> switchWifiMode());

        // 不切换WiFi模式
        btnNoSwitching.setOnClickListener(v -> {
            if (isAPConnect) {
                requestPrinterWifiSSIDAndPassword();
            } else {
                edWifiSSID.setText(getConnectWifiSsid());
            }
            wifiModeLayout.setVisibility(View.GONE);
            wifiLayout.setVisibility(View.VISIBLE);
        });

        // 上一步
        btnPrevious.setOnClickListener(v -> {
            scanLayout.setVisibility(View.VISIBLE);
            wifiLayout.setVisibility(View.GONE);
            tvWifiModeTitle.setText("目前wifi设置模式是，是否切换？");
        });

        // 下一步
        btnNext.setOnClickListener(v -> {
            if (isAPConnect) {
                connectAPWifi();
            } else {
                showLoadingDialog();
                sendRSSIAndPassword();
            }
        });

        // 重新扫描
        btnScanAgain.setOnClickListener(v -> {
            wifiSuccessLayout.setVisibility(View.GONE);
            scanLayout.setVisibility(View.VISIBLE);
            startScan();
        });
    }

    private void setupBleCallbacks() {
        bleBluetoothHelper.setConnectionListener(new BleBluetoothHelper.BleConnectionListener() {
            @SuppressLint("SetTextI18n")
            @Override
            public void onConnectionStateChange(int state, String message) {
                L.l2(TAG, "状态：" + state + ", 消息：" + message);
                if (message.equals("扫描结束")) {
                    runOnUiThread(() -> {
                        tvScanTitle.setText("扫描出附近设备");
                        tvScanDes.setText("越靠近设备，信号越强");
                        btStartBleScan.setVisibility(View.VISIBLE);
                    });
                } else if (message.equals("连接成功")) {
                    runOnUiThread(() -> {
                        scanLayout.setVisibility(View.GONE);
                        wifiModeLayout.setVisibility(View.VISIBLE);
                        showLoadingDialog();
                        requestPrinterWifiStatus();
                    });
                }
            }

            @Override
            public void onServicesDiscovered(List<BluetoothGattService> services) {
                L.l2(TAG, "发现服务数量：" + services.size());
            }

            @Override
            public void onDataReceived(UUID serviceUuid, UUID characteristicUuid, byte[] data) {
                L.l2(TAG, "收到数据：" + new String(data));
            }

            @Override
            public void onDataWrite(UUID serviceUuid, UUID characteristicUuid, byte[] data, int status) {
                L.l2(TAG, "数据写入状态：" + status);
            }

            @Override
            public void onDeviceFound(BluetoothDevice device, int rssi) {
                L.l2(TAG, "发现设备：" + device.getName() + ", RSSI：" + rssi);
                runOnUiThread(() -> {
                    addOrUpdateDevice(device, rssi);
                });
            }

            @Override
            public void onError(String errorMessage) {
                L.l2(TAG, "错误：" + errorMessage);
            }

            @Override
            public void onDataRead(UUID uuid, UUID uuid1, byte[] value, int status) {
                L.l2(TAG, "数据读取状态：" + status);
            }
        });

        bleBluetoothHelper.setSmartConfigListener(new BleBluetoothHelper.BleSmartConfigListener() {
            @SuppressLint("SetTextI18n")
            @Override
            public void onSmartConfigStateChange(int state, String message) {
                L.l2(TAG, "状态：" + state + ", 消息：" + message);

                runOnUiThread(() -> {
                    if (configSuccessListener != null) {
                        configSuccessListener.onStatusUpdate(state, message);
                    }
                });

                if (state == 3) {
                    // 获取wifi ip相关参数成功
                    String[] data = message.split(" ");
                    runOnUiThread(() -> {
                        edWifiSSID.setText("");
                        etWifiPassword.setText("");
                        wifiSuccessLayout.setVisibility(View.VISIBLE);
                        wifiLayout.setVisibility(View.GONE);
                        hideLoading();

                        if (configSuccessListener != null) {
                            configSuccessListener.onConfigSuccess(data[0], data[3]);
                        }
                    });
                } else if (state == 4) {
                    // 获取wifi工作状态成功
                    String mode = getModeFromStatus(message);
                    isAPConnect = mode != null && mode.equals("AP");
                    runOnUiThread(() -> {
                        hideLoading();
                        tvWifiModeTitle.setText("目前wifi设置模式:" + message + "，是否切换成" + (isAPConnect ? "STA" : "AP") + "？");
                    });
                } else if (state == 1) {
                    // 获取wifi的SSID成功
                    runOnUiThread(() -> {
                        edWifiSSID.setText(message);
                    });
                    bleBluetoothHelper.getLocatWifiPassword();
                } else if (state == 2) {
                    // 获取wifi的密码成功
                    runOnUiThread(() -> {
                        etWifiPassword.setText(message);
                    });
                } else if (state == 8005) {
                    // 设置wifi模式（AP/STA）成功
                    if (message != null && message.equals("00")) {
                        isAPConnect = !isAPConnect;
                    }
                    runOnUiThread(() -> {
                        tvWifiModeTitle.setText("wifi设置模式已切换成" + (isAPConnect ? "AP" : "STA") + "，是否再切换成" + (isAPConnect ? "STA" : "AP") + "？");
                    });
                }
            }

            @Override
            public void onSmartConfigProgress(int step, String description) {
                L.l2(TAG, "步骤：" + step + ", 描述：" + description);
            }
        });
    }

    /**
     * 开始扫描蓝牙设备
     */
    public void startScan() {



        List<String> permission = new ArrayList<>();
        permission.add(Manifest.permission.BLUETOOTH);
        permission.add(Manifest.permission.BLUETOOTH_ADMIN);
        permission.add(Manifest.permission.ACCESS_COARSE_LOCATION);
        permission.add(Manifest.permission.ACCESS_FINE_LOCATION);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permission.add(Manifest.permission.BLUETOOTH_CONNECT);
            permission.add(Manifest.permission.BLUETOOTH_SCAN);
            permission.add(Manifest.permission.BLUETOOTH_ADVERTISE);
        }

        XXPermissions.with(context)
                .permission(permission)
                .unchecked()
                .request((p, allGranted) -> {
                    if (allGranted) {
                        if (bleBluetoothHelper.isBluetoothAvailable()) {
                            // 清空设备列表
                            deviceList.clear();
                            deviceAdapter.clear();
                            deviceAdapter.notifyDataSetChanged();

                            tvScanTitle.setText("扫描中...");
                            tvScanDes.setText("持续搜索中...");
                            btStartBleScan.setText("重新扫描");

                            deviceListView.setVisibility(View.VISIBLE);
                            btStartBleScan.setVisibility(View.GONE);

                            // 扫描3秒
                            bleBluetoothHelper.startScan(3000);
                        } else {
                           showRequestOpenBluetoothDialog();
                        }
                    }
                    ThreadLockUtils.getLock().unlock();
                });
    }

    public void showRequestOpenBluetoothDialog() {
        new AlertDialog.Builder(context)
                .setTitle("开启蓝牙连接")
                .setMessage("为了连接您的蓝牙设备，需要开启蓝牙功能。")
                .setPositiveButton("立即开启", (dialog, which) -> {
                    Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                    context.startActivity(enableBtIntent);
                })
                .setNegativeButton("取消", null)
                .show();
    }

    /**
     * 添加或更新设备列表
     */
    private void addOrUpdateDevice(BluetoothDevice newDevice, int rssi) {
        for (int i = 0; i < deviceList.size(); i++) {
            BleDevice existingDevice = deviceList.get(i);
            BluetoothDevice device = existingDevice.get_device();
            if (device.getAddress().equals(newDevice.getAddress())) {
                deviceList.set(i, new BleDevice(newDevice, rssi));
                updateDeviceListUI();
                return;
            }
        }

        deviceList.add(new BleDevice(newDevice, rssi));
        updateDeviceListUI();
    }

    /**
     * 更新设备列表UI
     */
    private void updateDeviceListUI() {
        deviceAdapter.clear();

        Log.i(TAG, "updateDeviceListUI: deviceList的长度："+deviceList.size());
        for (BleDevice device : deviceList) {
            String deviceName = device.get_device().getName();
            if (deviceName == null) {
                deviceName = "未知设备";
            }
            String deviceInfo = String.format("%s\n%s", deviceName, device.get_rssi());
            deviceAdapter.add(deviceInfo);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            deviceList.sort(Comparator.comparingDouble(BleDevice::get_rssi).reversed());
        }
        deviceAdapter.notifyDataSetChanged();
        Log.i(TAG, "updateDeviceListUI后: deviceList的长度："+deviceList.size());
    }

    /**
     * 连接到设备
     */
    private void connectToDevice(BleDevice device) {
        bleBluetoothHelper.connectDevice(device.get_device());
    }

    /**
     * 发送WiFi信息
     */
    private void sendRSSIAndPassword() {
        String ssid = edWifiSSID.getText().toString().trim();
        String password = etWifiPassword.getText().toString().trim();

        if (ssid.isEmpty()) {
            showAutoHideToast("请输入SSID");
            return;
        }
        if (password.isEmpty()) {
            showAutoHideToast("请输入密码");
            return;
        }
        bleBluetoothHelper.sendSmartConfigData(ssid, password);
    }

    /**
     * 请求打印机WiFi状态
     */
    private void requestPrinterWifiStatus() {
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            bleBluetoothHelper.checkWifiWorkingStatus(1);
        }, 1500); // 延迟，主要是更改Mtu需要时间
    }

    /**
     * 请求打印机WiFi SSID和密码
     */
    private void requestPrinterWifiSSIDAndPassword() {
        bleBluetoothHelper.getLocatWifiSSID();
    }

    /**
     * 切换WiFi模式
     */
    private void switchWifiMode() {
        if (!isAPConnect) {
            bleBluetoothHelper.setLocatWifiParams(!isAPConnect);
        } else {
            isAPConnect = false;
            tvWifiModeTitle.setText("wifi设置模式已切换成STA，是否再切换成AP？");
        }
    }

    /**
     * 连接AP WiFi
     */
    private void connectAPWifi() {
        String currentConnectSSID = getConnectWifiSsid();
        String targetSSID = edWifiSSID.getText().toString();

        if (currentConnectSSID.equals(targetSSID)) {
            bleBluetoothHelper.getPrintIpParams();
        } else {
            AlertDialog.Builder builder = new AlertDialog.Builder(context);
            builder.setTitle("温馨提示")
                    .setMessage("是否已经连接了该SSID的wifi？")
                    .setPositiveButton("确定", (dialog, which) -> {
                        connectAPWifi();
                    })
                    .setNegativeButton("取消", null)
                    .show();
        }
    }

    /**
     * 检查权限
     */
    private void checkPermissions() {
        String[] permissions = {
                Manifest.permission.ACCESS_WIFI_STATE,
                Manifest.permission.CHANGE_WIFI_STATE,
                Manifest.permission.ACCESS_FINE_LOCATION
        };

        boolean allGranted = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }

        if (!allGranted) {
            // 请求权限，这里需要Activity的引用
            if (context instanceof androidx.fragment.app.FragmentActivity) {
                androidx.core.app.ActivityCompat.requestPermissions(
                        (androidx.fragment.app.FragmentActivity) context,
                        permissions,
                        REQUEST_PERMISSIONS_CODE
                );
            }
        }
    }

    /**
     * 显示加载对话框
     */
    private void showLoadingDialog() {
        loadingDialog.setMessage("正在加载数据...");
        loadingDialog.show();
    }

    /**
     * 隐藏加载对话框
     */
    private void hideLoading() {
        if (loadingDialog != null && loadingDialog.isShowing()) {
            loadingDialog.dismiss();
        }
    }

    /**
     * 显示自动隐藏的Toast
     */
    public void showAutoHideToast(String message) {
        Toast toast = Toast.makeText(context, message, Toast.LENGTH_SHORT);
        toast.show();
        new Handler().postDelayed(toast::cancel, 3000);
    }

    /**
     * 运行在UI线程
     */
    private void runOnUiThread(Runnable runnable) {
        if (mainHandler != null) {
            mainHandler.post(runnable);
        }
    }

    /**
     * 获取已连接的WiFi SSID
     */
    private String getConnectWifiSsid() {
        WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wifiManager != null) {
            WifiInfo wifiInfo = wifiManager.getConnectionInfo();
            if (wifiInfo != null) {
                String ssid = wifiInfo.getSSID();
                if (ssid != null && ssid.length() > 0) {
                    if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
                        ssid = ssid.substring(1, ssid.length() - 1);
                    }
                }
                return ssid;
            }
        }
        return "";
    }

    /**
     * 从状态字符串中获取模式
     */
    public static String getModeFromStatus(String status) {
        String[] parts = status.split(",");
        for (String part : parts) {
            if (part.contains("模式:")) {
                return part.split("模式:")[1].trim();
            }
        }
        return null;
    }

    /**
     * 设置配置成功监听器
     */
    public void setOnConfigSuccessListener(OnConfigSuccessListener listener) {
        this.configSuccessListener = listener;
    }

    /**
     * 清理资源
     */
    public void release() {
        if (bleBluetoothHelper != null) {
            bleBluetoothHelper.release();
        }
        if (loadingDialog != null && loadingDialog.isShowing()) {
            loadingDialog.dismiss();
        }
    }

    /**
     * 配置成功回调接口
     */
    public interface OnConfigSuccessListener {
        void onConfigSuccess(String ip, String port);
        void onStatusUpdate(int state, String message);
    }
}
