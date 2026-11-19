package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import com.printer.demo.R;
import com.printer.psdk.device.net.Network;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class EnumPrinterTask extends BaseTask {
    public static final int ENUM_PRINTER = 1;
    public static final int TYPE_LAN = 0;
    public static final int TYPE_USB = 1;
    private static final String DEFAULT_PORT = "9100";

    private final CardPrinterAPI api;
    private final int type;
    private final int requestId;

    public EnumPrinterTask(Context context, Handler mainHandler, CardPrinterAPI api, int type, int requestId) {
        super(context != null ? context : api.getContext(), mainHandler);
        this.api = api;
        this.type = type;
        this.requestId = requestId;
    }

    @Override
    public void run() {
        postStatus("");
        if (type == TYPE_LAN) {
            startLanDiscovery();
            return;
        }
        List<Printer> printers;
        try {
            printers = enumerate();
        } catch (SecurityException e) {
            Log.e("PrinterDiscovery", "Printer enumeration failed", e);
            postStatus(context.getString(R.string.discovery_failed, e.getMessage()));
            return;
        }
        if (type != TYPE_LAN && !printers.isEmpty()) {
            Message result = mainHandler.obtainMessage(ENUM_PRINTER, printers);
            result.arg1 = requestId;
            result.sendToTarget();
        }
        if (printers.isEmpty()) {
            postStatus(context.getString(R.string.no_printer));
        } else {
            postStatus(context.getString(R.string.op_successfully, context.getString(R.string.enum_printer)));
        }
    }

    private List<Printer> enumerate() {
        switch (type) {
            case TYPE_USB:
                List<Printer> usb = api.findUsbPrinter();
                return usb == null ? new ArrayList<Printer>() : usb;
            default:
                return new ArrayList<>();
        }
    }

    private void startLanDiscovery() {
        Network network = Network.getInstance();
        List<Printer> found = Collections.synchronizedList(new ArrayList<Printer>());
        network.setOnPrinterFoundListener(info -> addLanPrinter(found, info));
        network.setOnScanningChangeListener(scanning -> {
            if (scanning) {
                postStatus(context.getString(R.string.searching_printer));
                return;
            }
            IOException error = network.getLastDiscoveryError();
            if (error != null) {
                postStatus(context.getString(R.string.discovery_failed, error.getMessage()));
            } else if (found.isEmpty()) {
                postStatus(context.getString(R.string.no_printer));
            } else {
                postStatus(context.getString(R.string.op_successfully, context.getString(R.string.enum_printer)));
            }
        });
        network.startPrinterDiscovery();
    }

    private void addLanPrinter(List<Printer> found, Network.PrinterInfo info) {
        if (info == null) {
            return;
        }
        String ip = info.getId();
        if (ip == null || ip.isEmpty() || "unknown".equals(ip)) {
            return;
        }
        Printer printer;
        synchronized (found) {
            printer = new NamedNetworkPrinter(info.toString(), ip, DEFAULT_PORT);
            found.add(printer);
            Log.i("PrinterDiscovery", "found request=" + requestId + " printer=" + info);
        }
        Message result = mainHandler.obtainMessage(ENUM_PRINTER, Collections.singletonList(printer));
        result.arg1 = requestId;
        result.sendToTarget();
    }

    private void postStatus(String text) {
        Message message = mainHandler.obtainMessage(0, text);
        message.arg1 = requestId;
        message.arg2 = ENUM_PRINTER;
        message.sendToTarget();
    }
}
