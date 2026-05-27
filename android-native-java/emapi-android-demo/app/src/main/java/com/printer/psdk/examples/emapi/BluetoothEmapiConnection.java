package com.printer.psdk.examples.emapi;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;

import com.printer.psdk.emapi.EmapiConnection;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

final class BluetoothEmapiConnection implements EmapiConnection {
    private static final UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    private final BluetoothSocket socket;
    private final InputStream input;
    private final OutputStream output;

    BluetoothEmapiConnection(BluetoothDevice device) throws IOException {
        socket = device.createRfcommSocketToServiceRecord(SPP_UUID);
        socket.connect();
        input = socket.getInputStream();
        output = socket.getOutputStream();
    }

    @Override
    public void write(byte[] data) throws IOException {
        output.write(data);
        output.flush();
    }

    @Override
    public byte[] read(int timeoutMs) throws IOException {
        long deadline = System.currentTimeMillis() + Math.max(timeoutMs, 1);
        while (input.available() == 0 && System.currentTimeMillis() < deadline) {
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IOException("Interrupted while waiting for EMAPI data", e);
            }
        }
        int available = input.available();
        if (available <= 0) {
            return new byte[0];
        }
        byte[] buffer = new byte[Math.min(available, 4096)];
        int count = input.read(buffer);
        if (count <= 0) {
            return new byte[0];
        }
        byte[] result = new byte[count];
        System.arraycopy(buffer, 0, result, 0, count);
        return result;
    }

    @Override
    public void close() throws IOException {
        socket.close();
    }
}
