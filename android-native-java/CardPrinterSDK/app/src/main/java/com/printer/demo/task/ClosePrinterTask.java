package com.printer.demo.task;

import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;

public class ClosePrinterTask extends BaseTask {
    public static final int CLOSE_PRINTER = 4;
    private final CardPrinterAPI api;

    public ClosePrinterTask(Handler mainHandler, CardPrinterAPI api) {
        super(api.getContext(), mainHandler);
        this.api = api;
    }

    @Override
    public void run() {
        super.run();
        api.disconnect();
        mainHandler.obtainMessage(CLOSE_PRINTER).sendToTarget();
        mainHandler.obtainMessage(0, context.getString(R.string.close_printer)).sendToTarget();
    }
}
