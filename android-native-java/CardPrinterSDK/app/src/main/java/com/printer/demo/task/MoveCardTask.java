package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Spinner;
import android.widget.TextView;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.MoveCard;

public class MoveCardTask extends BaseTask {
    public static final int MOVE_CARD = 6;
    private final CardPrinterAPI api;
    private final Printer.Serial serial;

    public MoveCardTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    @Override
    protected void onDialogShown(View view) {
        ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.move_to);
        int[] ids = {R.array.d300kp_move_mode, R.array.d300kp_move_mode, R.array.dc8600_move_mode};
        spMoveTo = view.findViewById(R.id.sp_1);
        String[] items = context.getResources().getStringArray(ids[serial.ordinal()]);
        spMoveTo.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
    }

    Spinner spMoveTo;

    @Override
    public void run() {
        super.run();
        showDialog(R.layout.layout_dialog_item1);
        if (isOk.get() < 0) {
            return;
        }

        int moveTo = spMoveTo.getSelectedItemPosition();
        try {
            api.cardOp(new MoveCard(moveTo));
            mainHandler.obtainMessage(MOVE_CARD, context.getString(R.string.op_successfully, context.getString(R.string.move_paper))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(MOVE_CARD, context.getString(R.string.op_failed, context.getString(R.string.move_paper), e.getMessage())).sendToTarget();
        }
    }
}
