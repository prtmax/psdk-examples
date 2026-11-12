package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;
import android.os.Message;

import com.printer.demo.R;
import com.printer.psdk.device.net.Network;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class EnumPrinterTask extends BaseTask {
    public static final int ENUM_PRINTER = 1;
    public static final int TYPE_USB = 0;
    public static final int TYPE_LAN = 1;
    private static final String DEFAULT_PORT = "9100";
    private static final long DISCOVERY_WAIT_SECONDS = 12;

    private static final Object DISCOVERY_LOCK = new Object();

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
        super.run();
        List<Printer> printers;
        try {
            printers = enumerate();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }
        if (printers == null) {
            return;
        }
        if (type != TYPE_LAN) {
            if (!printers.isEmpty()) {
                Message result = mainHandler.obtainMessage(ENUM_PRINTER, printers);
                result.arg1 = requestId;
                result.sendToTarget();
            }
        }
        if (printers.isEmpty()) {
            postStatus(context.getString(R.string.no_printer));
        } else {
            postStatus(context.getString(R.string.op_successfully, context.getString(R.string.enum_printer)));
        }
    }

    private List<Printer> enumerate() throws InterruptedException {
        switch (type) {
            case TYPE_USB:
                List<Printer> usb = api.findUsbPrinter();
                return usb == null ? new ArrayList<Printer>() : usb;
            case TYPE_LAN:
                return discoverLanPrinters();
            default:
                return new ArrayList<>();
        }
    }

    /**
     * Network.startPrinterDiscovery() broadcasts for about 10 seconds.
     */
    private List<Printer> discoverLanPrinters() throws InterruptedException {
        synchronized (DISCOVERY_LOCK) {
            return discoverLanPrintersLocked();
        }
    }

    private List<Printer> discoverLanPrintersLocked() throws InterruptedException {
        postStatus(context.getString(R.string.searching_printer));
        Network network = Network.getInstance();
        List<Printer> found = Collections.synchronizedList(new ArrayList<Printer>());
        CountDownLatch done = new CountDownLatch(1);
        network.stopPrinterDiscovery();
        network.setOnPrinterFoundListener(info -> addLanPrinter(found, info));
        network.setOnScanningChangeListener(scanning -> {
            if (!scanning) {
                done.countDown();
            }
        });
        try {
            network.startPrinterDiscovery();
            if (!done.await(DISCOVERY_WAIT_SECONDS, TimeUnit.SECONDS)) {
                network.stopPrinterDiscovery();
            }
            synchronized (found) {
                return new ArrayList<>(found);
            }
        } finally {
            network.setOnPrinterFoundListener(null);
            network.setOnScanningChangeListener(null);
            if (network.isScanning()) {
                network.stopPrinterDiscovery();
            }
        }
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
            for (Printer existing : found) {
                if (existing instanceof Printer.NetworkPrinter
                        && ip.equals(((Printer.NetworkPrinter) existing).getIp())) {
                    return;
                }
            }
            printer = new NamedNetworkPrinter(info.toString(), ip, DEFAULT_PORT);
            found.add(printer);
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
