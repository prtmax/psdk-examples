package com.printer.demo.task;

import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;

public class OpenPrinterTask extends BaseTask {
    public static final int OPEN_PRINTER = 3;
    private final CardPrinterAPI api;
    private final Printer printer;

    public OpenPrinterTask(Handler mainHandler, CardPrinterAPI api, Printer printer) {
        super(api.getContext(), mainHandler);
        this.api = api;
        this.printer = printer;
    }

    @Override
    public void run() {
        super.run();
//        if (printer == null) {
//            mainHandler.obtainMessage(0, context.getString(R.string.no_printer)).sendToTarget();
//        } else {
            try {
                api.requestUsbPermission(printer);
                api.connect(printer);

                api.setTimeout(45000);
                mainHandler.obtainMessage(OPEN_PRINTER).sendToTarget();
                mainHandler.obtainMessage(0, context.getString(R.string.open_successfully)).sendToTarget();
            } catch (OperationException e) {
                mainHandler.obtainMessage(0, context.getString(R.string.open_failed, e.getMessage())).sendToTarget();
            }
//        }
    }
}
