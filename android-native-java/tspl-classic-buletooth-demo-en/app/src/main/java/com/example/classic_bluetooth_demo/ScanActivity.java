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
import com.printer.psdk.device.bluetooth.classic.BluetoothStateListen;
import com.printer.psdk.device.bluetooth.classic.ClassicBluetooth;
import com.printer.psdk.device.bluetooth.classic.DiscoveryListen;


import java.util.ArrayList;
import java.util.List;
import java.util.Objects;


public class ScanActivity extends AppCompatActivity {

    private myAdapter listAdapter;
    private TextView tvEmpty;
    private Button tvScan;
    private EditText edit_name;
    private final List<Device> devList = new ArrayList<>();
    private final List<Device> searchList = new ArrayList<>();

    public static class Device {
        BluetoothDevice device;
        int rssi;
        String name;

        Device(BluetoothDevice device, int rssi) {
            this.device = device;
            this.rssi = rssi;
            name = device.getName();
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Device)) return false;
            Device device1 = (Device) o;
            return device.equals(device1.device);
        }

        @Override
        public int hashCode() {
            return Objects.hash(device);
        }

    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan);
        initViews();


        ClassicBluetooth.getInstance().initialize(getApplication());
        ClassicBluetooth.getInstance().setDiscoveryListener(discoveryListener);
        ClassicBluetooth.getInstance().setBluetoothStateListener(bluetoothStateListen);
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
            intent.putExtra("device", devList.get(position).device);
            startActivity(intent);
        });
        tvScan.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (ClassicBluetooth.getInstance().isInitialized()) {
                    if (tvScan.getText().toString().equals("scan")) {
                        doStartDiscovery();

                    } else {
                        ClassicBluetooth.getInstance().stopDiscovery();
                        tvScan.setText("scan");
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
                case DiscoveryListen.ERROR_LACK_LOCATION_PERMISSION:

                    ActivityCompat.requestPermissions(ScanActivity.this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 200);
                    break;
                case DiscoveryListen.ERROR_LOCATION_SERVICE_CLOSED:

                    break;
                case DiscoveryListen.ERROR_LACK_SCAN_PERMISSION:
                    break;
                case DiscoveryListen.ERROR_SCAN_FAILED:

                    break;
            }
        }


        @Override
        public void onDeviceFound(BluetoothDevice device, int rssi) {
            tvEmpty.setVisibility(View.INVISIBLE);
            Device dev = new Device(device, rssi);
            if (!devList.contains(dev) && dev.getName() != null) {
                if (!dev.getName().trim().equals("") && !dev.getName().isEmpty()) {
                    devList.add(dev);
                    listAdapter.notifyDataSetChanged();
                }
            }
        }
    };
    private final BluetoothStateListen bluetoothStateListen = new BluetoothStateListen() {

        @Override
        public void onBluetoothAdapterStateChanged(int i) {

        }
    };

    @Override
    protected void onResume() {
        super.onResume();
        if (ClassicBluetooth.getInstance().isInitialized()) {
            if (ClassicBluetooth.getInstance().isEnabledBluetooth()) {
                doStartDiscovery();
            } else {
                startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
            }
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (ClassicBluetooth.getInstance().isInitialized()) {
            ClassicBluetooth.getInstance().stopDiscovery();
        }
    }


    private void doStartDiscovery() {
        devList.clear();
        listAdapter.notifyDataSetChanged();
        tvEmpty.setVisibility(View.VISIBLE);
        ClassicBluetooth.getInstance().startDiscovery();
        tvScan.setText("stop scan");
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
            if (convertView == null) {
                holder = new ViewHolder();
                convertView = mInflater.inflate(R.layout.item_scan, null);
                holder.tvName = (TextView) convertView.findViewById(R.id.tvName);
                holder.tvAddr = (TextView) convertView.findViewById(R.id.tvAddr);
                holder.tvRssi = (TextView) convertView.findViewById(R.id.tvRssi);
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
