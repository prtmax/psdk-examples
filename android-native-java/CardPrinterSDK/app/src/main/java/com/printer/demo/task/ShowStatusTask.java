package com.printer.demo.task;

import android.os.Handler;
import android.util.Log;

import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.PrinterStatus;

import java.util.concurrent.atomic.AtomicBoolean;

public class ShowStatusTask extends BaseTask {
    public static final int SHOW_STATUS = 2;
    private final CardPrinterAPI api;
    private final AtomicBoolean isEnable = new AtomicBoolean();
    private Thread thread;

    public ShowStatusTask(Handler mainHandler, CardPrinterAPI api) {
        super(api.getContext(), mainHandler);
        this.api = api;
    }

    public void show(boolean enable) {
        isEnable.set(enable);
        if (this.thread != null) {
            this.thread.interrupt();
        }
    }

    @Override
    public void run() {
        super.run();
        this.thread = Thread.currentThread();
        PrinterStatus printerStatus = new PrinterStatus();
        while (isEnable.get()) {
            StringBuilder result = new StringBuilder();
            try {
                api.getDataOp(printerStatus);
                result.append(context.getString(R.string.temp_chassis, printerStatus.getChassisTemperature())).append(",")
                      .append(context.getString(R.string.temp_print_head, printerStatus.getPrintHeadTemperature())).append("\n");
                if (printerStatus.getHeatingRollerTemperature() != null) {
                    result.append(context.getString(R.string.temp_heating_roller, printerStatus.getHeatingRollerTemperature())).append(",");
                }
                result.append(context.getString(R.string.status_main, printerStatus.getMainStatusInfo())).append("\n")
                      .append(context.getString(R.string.status_warn, printerStatus.getWarningStatusInfo())).append(",")
                      .append(context.getString(R.string.status_error, printerStatus.getErrorStatusInfo())).append("\n");
                if (printerStatus.getPrintStatusInfo() != null) {
                    result.append(context.getString(R.string.status_print, printerStatus.getPrintStatusInfo())).append(",");
                }
                if (printerStatus.getCardStatusInfo() != null) {
                    result.append(context.getString(R.string.status_paper, printerStatus.getCardStatusInfo()));
                }

                if (printerStatus.getPrintBattVolt()!= null){
                    result.append(context.getString(R.string.battery_remaining, printerStatus.getPrintBattVolt())).append("\n");
                }
                result.append(context.getString(R.string.charging_status, printerStatus.getCharging() ? "充电中" : "放电")).append("\n");

                mainHandler.obtainMessage(SHOW_STATUS, result.toString()).sendToTarget();
            } catch (OperationException e) {
                result.append(context.getString(R.string.get_status_error, e.getMessage()));
                mainHandler.obtainMessage(SHOW_STATUS, -1, -1, result.toString()).sendToTarget();
                break;
            }
            try {
                // noinspection BusyWait
                Thread.sleep(500);
            } catch (InterruptedException ignore) {
                break;
            }
        }
        if (!isEnable.get()) {
            mainHandler.obtainMessage(SHOW_STATUS, null).sendToTarget();
        }
        this.thread = null;
    }
}
