package com.printer.demo.utils;

// LoadingDialog.java
import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.LayoutInflater;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.printer.demo.R;

public class LoadingDialog {

    private Dialog dialog;
    private TextView tvMessage;

    public LoadingDialog(@NonNull Context context) {
        dialog = new Dialog(context);
        dialog.setContentView(R.layout.dialog_loading);

        // 设置窗口属性
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        dialog.setCanceledOnTouchOutside(false); // 点击外部不关闭
        dialog.setCancelable(false); // 按返回键不关闭

        tvMessage = dialog.findViewById(R.id.tv_loading_message);
    }

    /**
     * 显示弹窗
     */
    public void show() {
        if (!dialog.isShowing()) {
            dialog.show();
        }
    }

    /**
     * 隐藏弹窗
     */
    public void dismiss() {
        if (dialog.isShowing()) {
            dialog.dismiss();
        }
    }

    /**
     * 设置加载提示文字
     */
    public void setMessage(@Nullable String message) {
        if (tvMessage != null && message != null) {
            tvMessage.setText(message);
        }
    }

    /**
     * 是否正在显示
     */
    public boolean isShowing() {
        return dialog.isShowing();
    }
}
