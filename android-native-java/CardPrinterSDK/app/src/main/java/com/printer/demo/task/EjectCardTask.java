package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.Spinner;
import android.widget.TextView;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.EjectCard;

public class EjectCardTask extends BaseTask implements Runnable {
    public static final int EJECT_CARD = 7;
    private final CardPrinterAPI api;
    private final Printer.Serial serial;

    public EjectCardTask(Context context, Handler mainHandler, CardPrinterAPI api) {
        super(context, mainHandler);
        this.api = api;
        this.serial = api.getPrinterSerial();
    }

    @Override
    protected void onDialogShown(View view) {
        if (serial == Printer.Serial.DC8600) {
            ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.eject_mode);
            spEjectMode = view.findViewById(R.id.sp_1);
            String[] items = context.getResources().getStringArray(R.array.dc8600_eject_mode);
            spEjectMode.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView) view.findViewById(R.id.tv_label2)).setText(R.string.eject_action);
            spEjectAction = view.findViewById(R.id.sp_2);
            items = context.getResources().getStringArray(R.array.dc8600_eject_action);
            spEjectAction.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
            ((TextView) view.findViewById(R.id.tv_label3)).setText(R.string.paper_face);
            spEjectSide = view.findViewById(R.id.sp_3);
            items = context.getResources().getStringArray(R.array.dc8600_eject_side);
            spEjectSide.setAdapter(new ArrayAdapter<>(context, android.R.layout.simple_list_item_1, items));
        } else {
            // 保留“出纸模式”标题，只显示强制退纸选项，不显示下拉框。
            ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.eject_mode);
            cbForceEject = view.findViewById(R.id.cb_force_eject);
            cbForceEject.setChecked(false);
        }
    }

    private Spinner spEjectMode, spEjectAction, spEjectSide;
    private CheckBox cbForceEject;
    @Override
    public void run() {
        super.run();
        int layout = serial == Printer.Serial.DC8600
                ? R.layout.layout_dialog_item3
                : R.layout.layout_dialog_eject_card;
        showDialog(layout);
        if (isOk.get() < 0) {
            return;
        }

        try {
            // 不再读取已取消的出纸口选项，保留正常/强制退纸选择。
            EjectCard ejectCard=new EjectCard(0, 0, 0,0);
            ejectCard.setEjectType(cbForceEject != null && cbForceEject.isChecked() ? 1 : 0);
            api.cardOp(ejectCard);

            mainHandler.obtainMessage(EJECT_CARD, context.getString(R.string.op_successfully, context.getString(R.string.paper_output))).sendToTarget();
        } catch (OperationException e) {
            mainHandler.obtainMessage(EJECT_CARD, context.getString(R.string.op_failed, context.getString(R.string.paper_output), e.getMessage())).sendToTarget();
        }
    }
}
