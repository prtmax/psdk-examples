package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.InitializePrinter;

public class InitPrinterTask extends BaseTask {
    private final CardPrinterAPI api;

    public InitPrinterTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
    }

    @Override
    public void run() {
        super.run();
        try {
            InitializePrinter initializePrinter = new InitializePrinter();
            api.printerOp(initializePrinter);
            mainHandler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.init_printer))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(0, context.getString(R.string.op_failed, context.getString(R.string.init_printer), e.getMessage())).sendToTarget();
        }
    }
}
