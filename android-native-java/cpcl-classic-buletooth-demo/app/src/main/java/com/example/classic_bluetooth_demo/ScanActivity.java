package com.example.classic_bluetooth_demo;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Process;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.BluetoothStateListen;
import com.printer.psdk.device.bluetooth.DiscoveryListen;


import java.util.ArrayList;
import java.util.List;


public class ScanActivity extends AppCompatActivity {

    private myAdapter listAdapter;
    private TextView tvEmpty;
    private Button tvScan;
    private EditText edit_name;
    private final List<Device> devList = new ArrayList<>();
    private final List<Device> searchList = new ArrayList<>();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan);
        initViews();

        Bluetooth.getInstance().initialize(getApplication());
        Bluetooth.getInstance().setDiscoveryListener(discoveryListener);
        Bluetooth.getInstance().setBluetoothStateListener(bluetoothStateListen);

    }

    private void initViews() {

        ListView lv = findViewById(R.id.lv);
        tvEmpty = findViewById(R.id.tvEmpty);
        tvScan = findViewById(R.id.tvScan);
        edit_name = findViewById(R.id.edit_name);
        listAdapter = new myAdapter(this, devList);
        lv.setAdapter(listAdapter);
        lv.setOnItemClickListener((parent, view, position, id) -> {
            Intent intent = new Intent(ScanActivity.this, MainActivity.class);
            intent.putExtra("device", listAdapter.mList.get(position).device);
            startActivity(intent);
        });
        tvScan.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (Bluetooth.getInstance().isInitialized()) {
                    if (tvScan.getText().toString().equals("扫描")) {
                        doStartDiscovery();

                    } else {
                        Bluetooth.getInstance().stopDiscovery();
                        tvScan.setText("扫描");
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

    private final BluetoothStateListen bluetoothStateListen = new BluetoothStateListen() {

        @Override
        public void onBluetoothAdapterStateChanged(int i) {

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
                    show("缺少定位权限");
                    ActivityCompat.requestPermissions(ScanActivity.this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 200);
                    break;
                case DiscoveryListen.ERROR_LOCATION_SERVICE_CLOSED://位置服务未开启
                    show("位置服务未开启");
                    break;
                case DiscoveryListen.ERROR_LACK_SCAN_PERMISSION://缺少搜索权限
                    show("缺少搜索权限");
                    break;
                case DiscoveryListen.ERROR_SCAN_FAILED://搜索失败
                    show("搜索失败");

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

    private void show(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }
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
        tvScan.setText("停止扫描");
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
