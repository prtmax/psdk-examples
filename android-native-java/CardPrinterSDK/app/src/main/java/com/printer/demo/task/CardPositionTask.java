package com.printer.demo.task;

import android.os.Handler;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.CardPosition;

public class CardPositionTask extends BaseTask {
    public static final int CARD_POSITION = 9;
    private final CardPrinterAPI api;

    public CardPositionTask(Handler mainHandler, CardPrinterAPI api) {
        super(api.getContext(), mainHandler);
        this.api = api;
    }

    @Override
    public void run() {
        super.run();
        CardPosition cardPosition = new CardPosition();
        try {
            api.getDataOp(cardPosition);

            mainHandler.obtainMessage(0, context.getString(R.string.paper_position) + ":" + cardPosition.getDescribe()).sendToTarget();

        } catch (OperationException e) {
            mainHandler.obtainMessage(CARD_POSITION, context.getString(R.string.op_failed, context.getString(R.string.paper_position), e.getMessage())).sendToTarget();
        }
    }
}
