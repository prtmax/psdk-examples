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
import com.printer.sdk.operate.RecycleCard;

public class RecycleCardTask extends BaseTask {
    public static final int RECYCLE_CARD = 8;
    private final CardPrinterAPI api;
    private final Printer.Serial serial;

    public RecycleCardTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    @Override
    protected void onDialogShown(View view) {
        ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.recycle_eject_position);
        spPosition = view.findViewById(R.id.sp_1);
        int[] ids = {R.array.d300kp_recycle_mode, R.array.r600_recycle_mode, R.array.dc8600_recycle_mode};
        String[] items = context.getResources().getStringArray(ids[serial.ordinal()]);
        spPosition.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
    }

    private Spinner spPosition;

    @Override
    public void run() {
        super.run();
        showDialog(R.layout.layout_dialog_item1);
        if (isOk.get() < 0) {
            return;
        }

        int position = spPosition.getSelectedItemPosition();
        try {
            api.cardOp(new RecycleCard(position));
            mainHandler.obtainMessage(RECYCLE_CARD, context.getString(R.string.op_successfully, context.getString(R.string.recycle_paper))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(RECYCLE_CARD, context.getString(R.string.op_failed, context.getString(R.string.recycle_paper), e.getMessage())).sendToTarget();
        }
    }
}
