package com.printer.demo.task;

import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.util.Log;

import com.dsj.printer.log.L;
import com.hjq.permissions.XXPermissions;
import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.utils.ThreadLockUtils;
import com.printer.sdk.utils.ThreadUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

public class OpenBleScanTask extends BaseTask {

    private static final String TAG=EnumPrinterTask.class.getSimpleName();
    public static final int ENUM_PRINTER = 1;
    private final CardPrinterAPI api;
    public Context myContext;

    public OpenBleScanTask(Context context,Handler mainHandler, CardPrinterAPI api) {
        super(api.getContext(), mainHandler);
        this.api = api;
        this.myContext=context;
    }



    @Override
    public void run() {
        super.run();
        try {
            mainHandler.obtainMessage(0, context.getString(R.string.open_successfully)).sendToTarget();
        }  catch (OperationException e) {
            mainHandler.obtainMessage(0, context.getString(R.string.open_failed, e.getMessage())).sendToTarget();
        }

    }
}
