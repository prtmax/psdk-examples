package com.example.classic_bluetooth_demo;

import android.bluetooth.BluetoothDevice;

import java.util.Objects;

public class Device {
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
