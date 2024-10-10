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
import android.os.Process;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;
import androidx.core.app.ActivityCompat;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.DiscoveryListen;


import java.util.ArrayList;
import java.util.List;


public class ScanActivity extends Activity {

  private myAdapter listAdapter;
  private TextView tvEmpty;
  private Button bt_Scan, bt_usb, bt_net;
  private EditText edit_name;
  private final List<Device> devList = new ArrayList<>();
  private final List<Device> searchList = new ArrayList<>();
  private AlertDialog alertDialog;


  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_scan);
    initViews();
    //初始化sdk
    Bluetooth.getInstance().initialize(getApplication());
    Bluetooth.getInstance().setDiscoveryListener(discoveryListener);
    checkPermissions();
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
    final String[] items = {"CPCL", "TSPL", "ESC", "WIFI"};
    AlertDialog.Builder alertBuilder = new AlertDialog.Builder(this);
    alertBuilder.setTitle("请先选择指令类型");
    alertBuilder.setItems(items, new DialogInterface.OnClickListener() {
      @Override
      public void onClick(DialogInterface dialogInterface, int i) {
        switch (i) {
          case 0:
            Intent intent0 = new Intent(ScanActivity.this, CPCLActivity.class);
            intent0.putExtra("device", listAdapter.mList.get(position).device);
            startActivity(intent0);
            break;
          case 1:
            Intent intent1 = new Intent(ScanActivity.this, TSPLActivity.class);
            intent1.putExtra("device", listAdapter.mList.get(position).device);
            startActivity(intent1);
            break;
          case 2:
            Intent intent2 = new Intent(ScanActivity.this, ESCActivity.class);
            intent2.putExtra("device", listAdapter.mList.get(position).device);
            startActivity(intent2);
            break;
          case 3:
            Intent intent3 = new Intent(ScanActivity.this, WIFIActivity.class);
            intent3.putExtra("device", listAdapter.mList.get(position).device);
            startActivity(intent3);
            break;
        }
        Toast.makeText(ScanActivity.this, items[i], Toast.LENGTH_SHORT).show();
        alertDialog.dismiss();
      }
    });
    alertDialog = alertBuilder.create();
    alertDialog.show();
  }


  private void initViews() {

    ListView lv = findViewById(R.id.lv);
    tvEmpty = findViewById(R.id.tvEmpty);
    bt_Scan = findViewById(R.id.bt_Scan);
    bt_usb = findViewById(R.id.bt_usb);
    bt_net = findViewById(R.id.bt_net);
    edit_name = findViewById(R.id.edit_name);
    listAdapter = new myAdapter(this, devList);
    lv.setAdapter(listAdapter);
    lv.setOnItemClickListener((parent, view, position, id) -> showList(position));
    bt_usb.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        Intent intent = new Intent(ScanActivity.this, USBActivity.class);
        startActivity(intent);
      }
    });
    bt_net.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        Intent intent = new Intent(ScanActivity.this, NETActivity.class);
        startActivity(intent);
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
        searchList.clear();
        if (editable.toString().equals("")) {
          listAdapter = new myAdapter(ScanActivity.this, devList);
          lv.setAdapter(listAdapter);
        } else {
          for (Device device : devList) {
            if (device.getName() != null) {
              if (device.getName().contains(editable.toString())) {
                searchList.add(device);
              }
            }
          }
          listAdapter = new myAdapter(ScanActivity.this, searchList);
          lv.setAdapter(listAdapter);
        }
      }
    });
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    Process.killProcess(Process.myPid());
  }

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
      tvEmpty.setVisibility(View.INVISIBLE);
      Device dev = new Device(device, rssi);
      if (!devList.contains(dev) && dev.getName() != null) {
        if (!dev.getName().trim().equals("") && !dev.getName().isEmpty() && !dev.getName().endsWith("_BLE") && !dev.getName().endsWith("-LE")) {
          devList.add(dev);
          listAdapter.notifyDataSetChanged();
        }
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

  @Override
  protected void onPause() {
    super.onPause();
    if (Bluetooth.getInstance().isInitialized()) {
      Bluetooth.getInstance().stopDiscovery();
    }
  }


  private void doStartDiscovery() {
    devList.clear();
    listAdapter.notifyDataSetChanged();
    tvEmpty.setVisibility(View.VISIBLE);
    Bluetooth.getInstance().startDiscovery();
    bt_Scan.setText("停止扫描");
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
