package com.printer.demo.wifi;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.app.ActivityCompat;

import com.printer.demo.R;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.DiscoveryListen;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * BLE scan entry for printer Wi-Fi provisioning.
 * Classic devices are filtered out, matching generic-android-demo BLE mode.
 */
public class BleScanActivity extends Activity {
    private static final int REQ_PERMISSION = 21;
    private static final int REQ_PROVISION = 22;
    private static final long RESTART_SCAN_DELAY_MS = 150L;

    private final List<BleDevice> devices = new ArrayList<>();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable restartDiscoveryRunnable = this::startDiscovery;

    private ListView listView;
    private TextView emptyView;
    private Button scanButton;
    private DeviceAdapter adapter;

    private final DiscoveryListen discoveryListener = new DiscoveryListen() {
        @Override
        public void onDiscoveryStart() {
        }

        @Override
        public void onDiscoveryStop() {
        }

        @Override
        public void onDiscoveryError(int errorCode, String errorMsg) {
            if (errorCode == DiscoveryListen.ERROR_LACK_LOCATION_PERMISSION) {
                requestNeededPermissions();
            } else if (!TextUtils.isEmpty(errorMsg)) {
                toast(errorMsg);
            }
        }

        @SuppressLint("MissingPermission")
        @Override
        public void onDeviceFound(BluetoothDevice device, int rssi) {
            if (!isBleDevice(device)) {
                return;
            }
            String name;
            try {
                name = device.getName();
            } catch (SecurityException e) {
                name = "";
            }
            if (TextUtils.isEmpty(name) || TextUtils.isEmpty(name.trim())) {
                return;
            }
            BleDevice found = new BleDevice(device, name.trim(), rssi);
            if (devices.contains(found)) {
                return;
            }
            devices.add(found);
            adapter.notifyDataSetChanged();
            emptyView.setVisibility(View.GONE);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_ble_scan);
        listView = findViewById(R.id.lv_devices);
        emptyView = findViewById(R.id.tv_empty);
        scanButton = findViewById(R.id.bt_scan);
        adapter = new DeviceAdapter();
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((parent, view, position, id) -> openProvision(devices.get(position)));
        scanButton.setOnClickListener(v -> {
            if (!Bluetooth.getInstance().isInitialized()) {
                return;
            }
            if ("停止扫描".contentEquals(scanButton.getText())) {
                Bluetooth.getInstance().stopDiscovery();
                scanButton.setText("扫描");
            } else {
                startDiscovery();
            }
        });
        Bluetooth.getInstance().initialize(getApplication());
        Bluetooth.getInstance().setDiscoveryListener(discoveryListener);
        if (!hasScanPermissions()) {
            requestNeededPermissions();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!Bluetooth.getInstance().isInitialized() || !hasScanPermissions()) {
            return;
        }
        if (Bluetooth.getInstance().isEnabledBluetooth()) {
            startDiscovery();
        } else {
            startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
        }
    }

    @Override
    protected void onPause() {
        handler.removeCallbacks(restartDiscoveryRunnable);
        if (Bluetooth.getInstance().isInitialized()) {
            Bluetooth.getInstance().stopDiscovery();
        }
        super.onPause();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_PROVISION && resultCode == RESULT_OK && data != null) {
            setResult(RESULT_OK, data);
            finish();
        }
    }

    private void openProvision(BleDevice device) {
        if (Bluetooth.getInstance().isInitialized()) {
            Bluetooth.getInstance().stopDiscovery();
        }
        Intent intent = new Intent(this, WifiProvisionActivity.class);
        intent.putExtra(WifiProvisionActivity.EXTRA_DEVICE, device.device);
        startActivityForResult(intent, REQ_PROVISION);
    }

    private void startDiscovery() {
        if (!Bluetooth.getInstance().isInitialized()) {
            return;
        }
        if (!Bluetooth.getInstance().isEnabledBluetooth()) {
            startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
            return;
        }
        devices.clear();
        adapter.notifyDataSetChanged();
        emptyView.setVisibility(View.VISIBLE);
        Bluetooth.getInstance().startDiscovery();
        scanButton.setText("停止扫描");
    }

    private boolean isBleDevice(BluetoothDevice device) {
        if (device == null) {
            return false;
        }
        try {
            return device.getType() != BluetoothDevice.DEVICE_TYPE_CLASSIC;
        } catch (SecurityException e) {
            return false;
        }
    }

    private boolean hasScanPermissions() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                    == PackageManager.PERMISSION_GRANTED
                    && ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private void requestNeededPermissions() {
        List<String> permissions = new ArrayList<>();
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
        permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN);
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
        }
        ActivityCompat.requestPermissions(this, permissions.toArray(new String[0]), REQ_PERMISSION);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQ_PERMISSION && hasScanPermissions()) {
            handler.removeCallbacks(restartDiscoveryRunnable);
            handler.postDelayed(restartDiscoveryRunnable, RESTART_SCAN_DELAY_MS);
        }
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    private static final class BleDevice {
        final BluetoothDevice device;
        final String name;
        final int rssi;

        BleDevice(BluetoothDevice device, String name, int rssi) {
            this.device = device;
            this.name = name;
            this.rssi = rssi;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (!(o instanceof BleDevice)) {
                return false;
            }
            return device.equals(((BleDevice) o).device);
        }

        @Override
        public int hashCode() {
            return Objects.hash(device);
        }
    }

    private class DeviceAdapter extends BaseAdapter {
        @Override
        public int getCount() {
            return devices.size();
        }

        @Override
        public Object getItem(int position) {
            return devices.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @SuppressLint("MissingPermission")
        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View view = convertView;
            if (view == null) {
                view = LayoutInflater.from(BleScanActivity.this).inflate(R.layout.item_ble_device, parent, false);
            }
            BleDevice device = devices.get(position);
            ((TextView) view.findViewById(R.id.tvName)).setText(device.name);
            ((TextView) view.findViewById(R.id.tvAddr)).setText(device.device.getAddress());
            ((TextView) view.findViewById(R.id.tvRssi)).setText(String.valueOf(device.rssi));
            return view;
        }
    }
}