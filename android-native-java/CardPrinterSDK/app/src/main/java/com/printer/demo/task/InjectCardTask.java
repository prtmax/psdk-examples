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
import com.printer.sdk.operate.InjectCard;

public class InjectCardTask extends BaseTask {
    public static final int INJECT_CARD = 5;
    private final CardPrinterAPI api;
    private final Printer.Serial serial;

    public InjectCardTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    @Override
    protected void onDialogShown(View view) {
        ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.inject_model);
        if (serial == Printer.Serial.D300Kp) {
            spInjectModel = view.findViewById(R.id.sp_1);
            String[] items = context.getResources().getStringArray(R.array.d300kp_inject_mode);
            spInjectModel.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView) view.findViewById(R.id.tv_label2)).setText(R.string.destination);
            spDestination = view.findViewById(R.id.sp_2);
            items = context.getResources().getStringArray(R.array.d300kp_move_mode);
            spDestination.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
        } else if (serial == Printer.Serial.DC8600) {
            spInjectModel = view.findViewById(R.id.sp_1);
            String[] items = context.getResources().getStringArray(R.array.dc8600_inject_mode);
            spInjectModel.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView) view.findViewById(R.id.tv_label2)).setText(R.string.flip_or_not);
            spInjectFlip = view.findViewById(R.id.sp_2);
            items = context.getResources().getStringArray(R.array.inject_flip_paper);
            spInjectFlip.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView)view.findViewById(R.id.tv_label3)).setText(R.string.destination);;
            spDestination = view.findViewById(R.id.sp_3);
            items = context.getResources().getStringArray(R.array.dc8600_move_mode);
            spDestination.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
        } else if (serial == Printer.Serial.R600) {
            spInjectModel = view.findViewById(R.id.sp_1);
            String[] items = context.getResources().getStringArray(R.array.r600_inject_mode);
            spInjectModel.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView) view.findViewById(R.id.tv_label2)).setText(R.string.flip_or_not);
            spInjectFlip = view.findViewById(R.id.sp_2);
            items = context.getResources().getStringArray(R.array.inject_flip_paper);
            spInjectFlip.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView)view.findViewById(R.id.tv_label3)).setText(R.string.destination);
            spDestination = view.findViewById(R.id.sp_3);
            items = context.getResources().getStringArray(R.array.d300kp_move_mode);
            spDestination.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
        }
    }

    Spinner spInjectModel, spInjectFlip, spDestination;

    @Override
    public void run() {
        super.run();
//        int[] ids = {R.layout.layout_dialog_item2, R.layout.layout_dialog_item3, R.layout.layout_dialog_item3};
//        showDialog(ids[serial.ordinal()]);
//        if (isOk.get() < 0) {
//            return;
//        }
//
//        int injectModel, flipCard = 0, destination = 0;
//        injectModel = spInjectModel.getSelectedItemPosition();
//        if (spInjectFlip != null) {
//            flipCard = spInjectFlip.getSelectedItemPosition();
//        }
//        if (spDestination != null) {
//            destination = spDestination.getSelectedItemPosition();
//        }

        try {
            // api.cardOp(new InjectCard(injectModel, flipCard, destination));
            api.cardOp(new InjectCard(3, 0, 0));
            mainHandler.obtainMessage(INJECT_CARD, context.getString(R.string.op_successfully, context.getString(R.string.paper_feeding))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(INJECT_CARD, context.getString(R.string.op_failed, context.getString(R.string.paper_feeding), e.getMessage())).sendToTarget();
        }
    }
}
