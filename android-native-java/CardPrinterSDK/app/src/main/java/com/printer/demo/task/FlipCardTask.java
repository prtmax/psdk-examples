package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.FlipCard;

public class FlipCardTask extends BaseTask {
    private final CardPrinterAPI api;
    private final Printer.Serial serial;

    public FlipCardTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    @Override
    public void run() {
        try {
            api.cardOp(new FlipCard());
            mainHandler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.flip_paper))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(0, context.getString(R.string.op_failed, context.getString(R.string.flip_paper), e.getMessage())).sendToTarget();
        }
    }
}
