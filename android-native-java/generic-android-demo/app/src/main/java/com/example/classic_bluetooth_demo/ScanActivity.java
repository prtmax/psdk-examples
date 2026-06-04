package com.example.classic_bluetooth_demo;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;
import androidx.core.app.ActivityCompat;
import com.example.classic_bluetooth_demo.util.Util;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.BluetoothStateListen;
import com.printer.psdk.device.bluetooth.DiscoveryListen;


import java.util.ArrayList;
import java.util.List;


public class ScanActivity extends Activity {

  private static final int MODE_PRINT = 0;
  private static final int MODE_BLE = 1;
  private static final long RESTART_SCAN_DELAY_MS = 150L;

  private ListView lv;
  private myAdapter listAdapter;
  private TextView tvEmpty;
  private TextView tvModeHint;
  private Button bt_Scan, bt_usb, bt_net, bt_print_mode, bt_ble_mode;
  private EditText edit_name;
  private final List<Device> devList = new ArrayList<>();
  private final List<Device> searchList = new ArrayList<>();
  private AlertDialog alertDialog;
  private int currentMode = MODE_PRINT;
  private final Handler handler = new Handler(Looper.getMainLooper());
  private final Runnable restartDiscoveryRunnable = this::doStartDiscovery;


  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    if (savedInstanceState != null) {
      currentMode = savedInstanceState.getInt("scan_mode", MODE_PRINT);
    }
    setContentView(R.layout.activity_scan);
    initViews();
    updateModeUi();
    //初始化sdk
    Bluetooth.getInstance().initialize(getApplication());
    Bluetooth.getInstance().setDiscoveryListener(discoveryListener);
    Bluetooth.getInstance().setBluetoothStateListener(bluetoothStateListen);
    checkPermissions();
  }

  @Override
  protected void onSaveInstanceState(Bundle outState) {
    super.onSaveInstanceState(outState);
    outState.putInt("scan_mode", currentMode);
  }

  @Override
  protected void onPause() {
    super.onPause();
    handler.removeCallbacks(restartDiscoveryRunnable);
    if (Bluetooth.getInstance().isInitialized()) {
      Bluetooth.getInstance().stopDiscovery();
    }
  }

  private static final String[] PERMISSIONS_STORAGE = {
    Manifest.permission.READ_EXTERNAL_STORAGE,
    Manifest.permission.WRITE_EXTERNAL_STORAGE,
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION,
    Manifest.permission.ACCESS_LOCATION_EXTRA_COMMANDS,
    Manifest.permission.BLUETOOTH_SCAN,
    Manifest.permission.BLUETOOTH_CONNECT,
    Manifest.permission.BLUETOOTH_PRIVILEGED
  };
  private static final String[] PERMISSIONS_LOCATION = {
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION,
    Manifest.permission.ACCESS_LOCATION_EXTRA_COMMANDS,
    Manifest.permission.BLUETOOTH_SCAN,
    Manifest.permission.BLUETOOTH_CONNECT,
    Manifest.permission.BLUETOOTH_PRIVILEGED
  };

  private void checkPermissions() {
    int permission1 = ActivityCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);
    int permission2 = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT);
    if (permission1 != PackageManager.PERMISSION_GRANTED) {
      // We don't have permission so prompt the user
      ActivityCompat.requestPermissions(
        this,
        PERMISSIONS_STORAGE,
        1
      );
    } else if (permission2 != PackageManager.PERMISSION_GRANTED) {
      ActivityCompat.requestPermissions(
        this,
        PERMISSIONS_LOCATION,
        1
      );
    }
  }

  public void showList(int position) {
    final String[] items = currentMode == MODE_PRINT
      ? new String[]{"CPCL打印（SPP）", "TSPL打印（SPP）", "ESC打印（SPP）", "ZPL打印（SPP）"}
      : new String[]{"TSPL配网（BLE）", "ESC配网（BLE）"};
    AlertDialog.Builder alertBuilder = new AlertDialog.Builder(this);
    alertBuilder.setTitle(currentMode == MODE_PRINT ? R.string.scan_mode_title_print : R.string.scan_mode_title_ble);
    alertBuilder.setItems(items, new DialogInterface.OnClickListener() {
      @Override
      public void onClick(DialogInterface dialogInterface, int i) {
        if (currentMode == MODE_PRINT) {
          switch (i) {
            case 0:
              startDeviceActivity(CPCLActivity.class, position);
              break;
            case 1:
              startDeviceActivity(TSPLActivity.class, position);
              break;
            case 2:
              startDeviceActivity(ESCActivity.class, position);
              break;
            case 3:
              startDeviceActivity(ZPLActivity.class, position);
              break;
          }
        } else {
          switch (i) {
            case 0:
              startDeviceActivity(WIFIActivity.class, position);
              break;
            case 1:
              startDeviceActivity(ESCWIFIActivity.class, position);
              break;
          }
        }
        Util.show(ScanActivity.this, items[i]);
        alertDialog.dismiss();
      }
    });
    alertDialog = alertBuilder.create();
    alertDialog.show();
  }


  private void initViews() {

    lv = findViewById(R.id.lv);
    tvEmpty = findViewById(R.id.tvEmpty);
    tvModeHint = findViewById(R.id.tvModeHint);
    bt_Scan = findViewById(R.id.bt_Scan);
    bt_usb = findViewById(R.id.bt_usb);
    bt_net = findViewById(R.id.bt_net);
    bt_print_mode = findViewById(R.id.bt_print_mode);
    bt_ble_mode = findViewById(R.id.bt_ble_mode);
    edit_name = findViewById(R.id.edit_name);
    listAdapter = new myAdapter(this, devList);
    lv.setAdapter(listAdapter);
    lv.setOnItemClickListener((parent, view, position, id) -> showList(position));
    bt_usb.setOnClickListener(view -> startActivity(new Intent(ScanActivity.this, USBActivity.class)));
    bt_net.setOnClickListener(view -> startActivity(new Intent(ScanActivity.this, NETActivity.class)));
    bt_print_mode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        setCurrentMode(MODE_PRINT);
      }
    });
    bt_ble_mode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        setCurrentMode(MODE_BLE);
      }
    });
    bt_Scan.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        if (Bluetooth.getInstance().isInitialized()) {
          if (bt_Scan.getText().toString().equals("扫描")) {
            doStartDiscovery();

          } else {
            Bluetooth.getInstance().stopDiscovery();
            bt_Scan.setText("扫描");
          }
        }
      }
    });
    edit_name.addTextChangedListener(new TextWatcher() {
      @Override
      public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

      }

      @Override
      public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {

      }

      @Override
      public void afterTextChanged(Editable editable) {
        applySearchFilter(editable == null ? "" : editable.toString());
      }
    });
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    handler.removeCallbacks(restartDiscoveryRunnable);
    Process.killProcess(Process.myPid());
  }

  private final BluetoothStateListen bluetoothStateListen = i -> {
    switch (i) {
      case BluetoothAdapter.STATE_OFF:
        Util.show(ScanActivity.this, "蓝牙关闭");
        break;
      case BluetoothAdapter.STATE_ON:
        Util.show(ScanActivity.this, "蓝牙打开");
        break;
    }
  };

  private final DiscoveryListen discoveryListener = new DiscoveryListen() {
    @Override
    public void onDiscoveryStart() {
      invalidateOptionsMenu();
    }

    @Override
    public void onDiscoveryStop() {
      invalidateOptionsMenu();
    }

    @Override
    public void onDiscoveryError(int errorCode, String errorMsg) {
      switch (errorCode) {
        case DiscoveryListen.ERROR_LACK_LOCATION_PERMISSION://缺少定位权限

          ActivityCompat.requestPermissions(ScanActivity.this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 200);
          break;
        case DiscoveryListen.ERROR_LOCATION_SERVICE_CLOSED://位置服务未开启

          break;
        case DiscoveryListen.ERROR_LACK_SCAN_PERMISSION://缺少搜索权限
          break;
        case DiscoveryListen.ERROR_SCAN_FAILED://搜索失败

          break;
      }
    }


    @Override
    public void onDeviceFound(BluetoothDevice device, int rssi) {
      Device dev = new Device(device, rssi);
      if (isDeviceAllowedForCurrentMode(device) && !devList.contains(dev) && !TextUtils.isEmpty(dev.getName()) && !TextUtils.isEmpty(dev.getName().trim())) {
        devList.add(dev);
        tvEmpty.setVisibility(View.INVISIBLE);
        applySearchFilter(edit_name.getText() == null ? "" : edit_name.getText().toString());
      }
    }
  };


  @SuppressLint("MissingPermission")
  @Override
  protected void onResume() {
    super.onResume();
    if (Bluetooth.getInstance().isInitialized()) {
      if (Bluetooth.getInstance().isEnabledBluetooth()) {
        doStartDiscovery();
      } else {
        startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
      }
    }
  }


  private void doStartDiscovery() {
    devList.clear();
    searchList.clear();
    applySearchFilter(edit_name.getText() == null ? "" : edit_name.getText().toString());
    tvEmpty.setVisibility(View.VISIBLE);
    Bluetooth.getInstance().startDiscovery();
    bt_Scan.setText("停止扫描");
  }

  private void setCurrentMode(int mode) {
    currentMode = mode;
    updateModeUi();
    restartDiscovery();
  }

  private void restartDiscovery() {
    handler.removeCallbacks(restartDiscoveryRunnable);
    if (!Bluetooth.getInstance().isInitialized() || !Bluetooth.getInstance().isEnabledBluetooth()) {
      return;
    }
    Bluetooth.getInstance().stopDiscovery();
    handler.postDelayed(restartDiscoveryRunnable, RESTART_SCAN_DELAY_MS);
  }

  private void updateModeUi() {
    if (tvModeHint != null) {
      tvModeHint.setText(currentMode == MODE_PRINT ? R.string.scan_mode_hint_print : R.string.scan_mode_hint_ble);
    }
    if (bt_print_mode != null && bt_ble_mode != null) {
      bt_print_mode.setEnabled(currentMode != MODE_PRINT);
      bt_ble_mode.setEnabled(currentMode != MODE_BLE);
    }
  }

  private void applySearchFilter(String keyword) {
    searchList.clear();
    if (TextUtils.isEmpty(keyword)) {
      listAdapter = new myAdapter(ScanActivity.this, devList);
    } else {
      for (Device device : devList) {
        if (!TextUtils.isEmpty(device.getName()) && device.getName().contains(keyword)) {
          searchList.add(device);
        }
      }
      listAdapter = new myAdapter(ScanActivity.this, searchList);
    }
    lv.setAdapter(listAdapter);
    tvEmpty.setVisibility(listAdapter.getCount() == 0 ? View.VISIBLE : View.INVISIBLE);
  }

  private boolean isDeviceAllowedForCurrentMode(BluetoothDevice device) {
    if (device == null) {
      return false;
    }
    int type = device.getType();
    if (currentMode == MODE_PRINT) {
      return type != BluetoothDevice.DEVICE_TYPE_LE;
    }
    if (currentMode == MODE_BLE) {
      return type != BluetoothDevice.DEVICE_TYPE_CLASSIC;
    }
    return true;
  }

  private void startDeviceActivity(Class<? extends Activity> activityClass, int position) {
    Intent intent = new Intent(ScanActivity.this, activityClass);
    intent.putExtra("device", listAdapter.mList.get(position).device);
    startActivity(intent);
  }

  public class myAdapter extends BaseAdapter {

    private List<Device> mList;
    private Context mContext;
    private LayoutInflater mInflater;

    public myAdapter(Context mContext, List<Device> mList) {
      this.mList = mList;
      this.mContext = mContext;
      this.mInflater = LayoutInflater.from(mContext);

    }

    @Override
    public int getCount() {
      return mList.size();
    }

    @Override
    public Object getItem(int i) {
      return i;
    }

    @Override
    public long getItemId(int i) {
      return i;
    }


    @Override
    public View getView(int i, View convertView, ViewGroup viewGroup) {
      ViewHolder holder;
      //如果缓存convertView为空，则需要创建View
      if (convertView == null) {
        holder = new ViewHolder();
        //根据自定义的Item布局加载布局
        convertView = mInflater.inflate(R.layout.item_scan, null);
        holder.tvName = (TextView) convertView.findViewById(R.id.tvName);
        holder.tvAddr = (TextView) convertView.findViewById(R.id.tvAddr);
        holder.tvRssi = (TextView) convertView.findViewById(R.id.tvRssi);
        //将设置好的布局保存到缓存中，并将其设置在Tag里，以便后面方便取出Tag
        convertView.setTag(holder);
      } else {
        holder = (ViewHolder) convertView.getTag();
      }
      holder.tvName.setText(TextUtils.isEmpty(mList.get(i).getName()) ? "N/A" : mList.get(i).getName());
      holder.tvAddr.setText(mList.get(i).device.getAddress());
      holder.tvRssi.setText(mList.get(i).rssi + "");

      return convertView;

    }

  }

  //ViewHolder静态类
  static class ViewHolder {
    public TextView tvName;
    public TextView tvAddr;
    public TextView tvRssi;
  }


}
