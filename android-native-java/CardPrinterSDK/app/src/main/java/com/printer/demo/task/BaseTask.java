package com.printer.demo.task;

import android.content.Context;
import android.os.Handler;
import android.view.View;

import androidx.appcompat.app.AlertDialog;

import com.printer.demo.R;

import java.util.Objects;
import java.util.concurrent.atomic.AtomicInteger;

class BaseTask implements Runnable {
    protected final Context context;
    protected final Handler mainHandler;

    public BaseTask(Context context, Handler mainHandler) {
        this.context = context;
        this.mainHandler = mainHandler;
    }

    protected final AtomicInteger isOk = new AtomicInteger();

    protected void showListDialog(String title, String[] items) {
        if (mainHandler == null) {
            return;
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title)
               .setItems(items, (dialog, which) -> {
                   isOk.set(which);
                   synchronized (isOk) {
                       isOk.notify();
                   }
                   View view = Objects.requireNonNull(((AlertDialog) dialog).getWindow()).getDecorView();
                   onDialogOk(view);
               })
               .setOnCancelListener(dialog -> {
                   isOk.set(-1);
                   synchronized (isOk) {
                       isOk.notify();
                   }
                   onDialogCancel();
               });
        mainHandler.post(() -> {
            AlertDialog alertDialog = builder.create();
            alertDialog.show();
            onDialogShown(Objects.requireNonNull(alertDialog.getWindow()).getDecorView());
        });
        isOk.set(-1);
        synchronized (isOk) {
            try {
                isOk.wait();
            } catch (InterruptedException ignore) {
            }
        }
    }

    protected void showDialog(int layout) {
        showDialog(null, layout);
    }

    protected void showDialog(String title, int layout) {
        if (mainHandler == null) {
            return;
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title)
               .setView(layout)
               .setPositiveButton(context.getString(R.string.ok), (dialog, which) -> {
                   isOk.set(1);
                   synchronized (isOk) {
                       isOk.notify();
                   }
                   View view = Objects.requireNonNull(((AlertDialog) dialog).getWindow()).getDecorView();
                   onDialogOk(view);
               })
               .setNegativeButton(context.getString(R.string.cancel), (dialog, which) -> {
                   isOk.set(-1);
                   synchronized (isOk) {
                       isOk.notify();
                   }
                   onDialogCancel();
               })
               .setOnCancelListener(dialog -> {
                   isOk.set(-1);
                   synchronized (isOk) {
                       isOk.notify();
                   }
                   onDialogCancel();
               });
        mainHandler.post(() -> {
            AlertDialog alertDialog = builder.create();
            alertDialog.show();
            onDialogShown(Objects.requireNonNull(alertDialog.getWindow()).getDecorView());
        });
        isOk.set(0);
        synchronized (isOk) {
            try {
                isOk.wait();
            } catch (InterruptedException ignore) {
            }
        }
    }

    protected void onDialogShown(View view) {}

    protected void onDialogOk(View view) {}

    protected void onDialogCancel() {}

    @Override
    public void run() {
        if (mainHandler != null) {
            mainHandler.obtainMessage(0, "").sendToTarget();
        }
    }
}
