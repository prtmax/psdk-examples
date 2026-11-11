package com.printer.demo.task;

import static android.os.Build.VERSION.SDK_INT;

import android.Manifest;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.util.Log;
import android.widget.Toast;

import com.dsj.printer.log.L;
import com.hjq.permissions.XXPermissions;
import com.printer.demo.R;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.utils.ThreadLockUtils;
import com.printer.sdk.utils.ThreadUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

public class EnumPrinterTask extends BaseTask {
    private static final String TAG=EnumPrinterTask.class.getSimpleName();
    public static final int ENUM_PRINTER = 1;
    private final CardPrinterAPI api;
    private final int type;

    public Context myContext;

    public EnumPrinterTask(Context context,Handler mainHandler, CardPrinterAPI api, int type) {
        super(api.getContext(), mainHandler);
        this.api = api;
        this.type = type;
        this.myContext=context;
    }

    @Override
    public void run() {
        super.run();

        AtomicReference<List<Printer>> printers=new AtomicReference<>();
        switch (type){
            case 0:
                printers.set(api.findUsbPrinter());
                break;
            case 1:
                printers.set(api.findNetWorkPrinter());
                break;
            case 2:
                ThreadUtils.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        List<String> permission = new ArrayList<>();
                        permission.add(Manifest.permission.BLUETOOTH);
                        permission.add(Manifest.permission.BLUETOOTH_ADMIN);
                        permission.add(Manifest.permission.ACCESS_COARSE_LOCATION);
                        permission.add(Manifest.permission.ACCESS_FINE_LOCATION);

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            permission.add(Manifest.permission.BLUETOOTH_CONNECT);
                            permission.add(Manifest.permission.BLUETOOTH_SCAN);
                            permission.add(Manifest.permission.BLUETOOTH_ADVERTISE);
                        }
                        Log.i(TAG, "run: 请求权限");
                        XXPermissions.with(myContext)
                                .permission(permission)
                                .unchecked()
                                .request((p, allGranted) -> {
                                    Log.i(TAG, "run: XXPermissions request");
                                    if (allGranted) {
                                        printers.set(api.findBluetoothPrinter(myContext));
                                    } else {
                                        printers.set(new ArrayList<>());
                                        Log.e(TAG, "No Bluetooth Permission" );
                                        L.l0(TAG,"No Bluetooth Permission");
                                    }
                                    ThreadLockUtils.getLock().unlock();
                                });
                    }
                });
                ThreadLockUtils.getLock().lock(1000);
                break;
            default:
                printers.set(new ArrayList<>());
                break;
        }
        if (printers.get().isEmpty()) {
            mainHandler.obtainMessage(0, context.getString(R.string.no_printer)).sendToTarget();
        } else {
            mainHandler.obtainMessage(ENUM_PRINTER, printers.get()).sendToTarget();
            mainHandler.obtainMessage(0, context.getString(R.string.op_successfully, context.getString(R.string.enum_printer))).sendToTarget();
        }
    }
}
