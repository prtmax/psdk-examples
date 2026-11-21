package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.ClearPrinterCache;

public class ClearCacheTask extends BaseTask {
    private final CardPrinterAPI api;

    public ClearCacheTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
    }

    @Override
    public void run() {
        super.run();
        try {
            ClearPrinterCache clearPrinterCache = new ClearPrinterCache();
            api.printerOp(clearPrinterCache);
            mainHandler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.clear_cache))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(0, context.getString(R.string.op_failed, context.getString(R.string.clear_cache), e.getMessage())).sendToTarget();
        }
    }
}
