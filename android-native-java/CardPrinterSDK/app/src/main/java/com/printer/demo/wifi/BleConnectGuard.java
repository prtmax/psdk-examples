package com.printer.demo.wifi;

import android.os.Handler;

import com.printer.psdk.device.bluetooth.Connection;

import java.lang.reflect.Field;

/**
 * Shipped BLE connection arms a 10s timeout that calls BluetoothGatt.disconnect()
 * without a null check. disconnect() also clears the GATT object without
 * cancelling that timeout, so leaving the page while connecting crashes later.
 * This stays in the demo and does not change the SDK.
 */
final class BleConnectGuard {
    private BleConnectGuard() {
    }

    static boolean disarmIfGattMissing(Connection connection) {
        if (connection == null || hasGatt(connection)) {
            return false;
        }
        cancelConnectTimeout(connection);
        return true;
    }

    static void cancelConnectTimeout(Connection connection) {
        if (connection == null) {
            return;
        }
        try {
            Class<?> type = connection.getClass();
            Field handlerField = type.getDeclaredField("mTimeoutHandler");
            Field runnableField = type.getDeclaredField("mConnectTimeoutRunnable");
            handlerField.setAccessible(true);
            runnableField.setAccessible(true);
            Handler handler = (Handler) handlerField.get(connection);
            Runnable runnable = (Runnable) runnableField.get(connection);
            if (handler != null && runnable != null) {
                handler.removeCallbacks(runnable);
            }
        } catch (Exception ignored) {
        }
    }

    private static boolean hasGatt(Connection connection) {
        try {
            Field gattField = connection.getClass().getDeclaredField("mBluetoothGatt");
            gattField.setAccessible(true);
            return gattField.get(connection) != null;
        } catch (Exception ignored) {
            return true;
        }
    }
}