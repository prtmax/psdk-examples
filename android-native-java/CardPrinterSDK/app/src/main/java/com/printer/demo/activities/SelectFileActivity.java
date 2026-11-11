package com.printer.demo.activities;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.hjq.permissions.OnPermissionCallback;
import com.hjq.permissions.XXPermissions;
import com.printer.demo.R;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import me.rosuh.filepicker.bean.FileItemBeanImpl;
import me.rosuh.filepicker.config.AbstractFileFilter;
import me.rosuh.filepicker.config.FilePickerConfig;
import me.rosuh.filepicker.config.FilePickerManager;
import me.rosuh.filepicker.config.ILog;
import me.rosuh.filepicker.filetype.FileType;
import me.rosuh.filepicker.filetype.RasterImageFileType;

public class SelectFileActivity extends AppCompatActivity {

    private static Callback callback;
    private static int type = 0;
    private final AbstractFileFilter imageFilter = new AbstractFileFilter() {
        @NonNull
        @Override
        public ArrayList<FileItemBeanImpl> doFilter(@NonNull final ArrayList<FileItemBeanImpl> arrayList) {
            ArrayList<FileItemBeanImpl> itemBeans = new ArrayList<>();
            for (final FileItemBeanImpl fileItemBean : arrayList) {
                if (fileItemBean.isDir() || fileItemBean.getFileType() instanceof RasterImageFileType) {
                    itemBeans.add(fileItemBean);
                }
            }
            return itemBeans;
        }
    };

    public static void startSelectedImage(Activity activity, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 0;
        activity.startActivity(new Intent(activity, SelectFileActivity.class));
    }

    public static void startSelectedImage(Fragment fragment, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 0;
        fragment.startActivity(new Intent(fragment.requireContext(), SelectFileActivity.class));
    }

    public static void startSelectedFont(Activity activity, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 1;
        activity.startActivity(new Intent(activity, SelectFileActivity.class));
    }

    public static void startSelectedFont(Fragment fragment, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 1;
        fragment.startActivity(new Intent(fragment.requireContext(), SelectFileActivity.class));
    }

    //sh,2026.08.03 add 选择固件升级文件(type=2, 仅显示 .mot 文件)
    public static void startSelectedFirmware(Activity activity, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 2;
        activity.startActivity(new Intent(activity, SelectFileActivity.class));
    }

    public static void startSelectedFirmware(Fragment fragment, Callback callback) {
        SelectFileActivity.callback = callback;
        SelectFileActivity.type = 2;
        fragment.startActivity(new Intent(fragment.requireContext(), SelectFileActivity.class));
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        List<String> permission = new ArrayList<>();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permission.add(Manifest.permission.READ_MEDIA_IMAGES);
        } else {
            permission.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            permission.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            permission.add(Manifest.permission.MANAGE_EXTERNAL_STORAGE);
        }
        XXPermissions.with(SelectFileActivity.this)
                     .permission(permission)
                     .unchecked()
                     .request(new OnPermissionCallback() {
                         @Override
                         public void onGranted(@NonNull List<String> permission, boolean allGranted) {
                             if (allGranted) {
                                 selectFile();
                             }
                         }

                         @Override
                         public void onDenied(@NonNull List<String> permissions, boolean doNotAskAgain) {
                             finish();
                         }
                     });
    }

    protected void selectFile() {
        FilePickerConfig config = FilePickerManager
                .from(this)
                .log(new ILog() {
                    @Override
                    public void d(@NonNull String s, @NonNull String s1) {
                        Log.d(s, s1);
                    }

                    @Override
                    public void e(@NonNull String s, @NonNull String s1, @Nullable Throwable throwable) {
                        Log.e(s, s1, throwable);
                    }

                    @Override
                    public void i(@NonNull String s, @NonNull String s1) {
                        Log.i(s, s1);
                    }

                    @Override
                    public void v(@NonNull String s, @NonNull String s1) {
                        Log.v(s, s1);
                    }

                    @Override
                    public void w(@NonNull String s, @NonNull String s1) {
                        Log.w(s, s1);
                    }

                    @Override
                    public void wtf(@NonNull String s, @NonNull String s1) {
                        Log.wtf(s, s1);
                    }
                })
                .enableSingleChoice();
        if (type == 0) {
            config.filter(imageFilter);
        } else if (type == 1) {
            ArrayList<FileType> fileTypes = new ArrayList<>();
            fileTypes.add(new FontType());
            config.registerFileType(fileTypes, true);
        } else if (type == 2) {
            //sh,2026.08.03 add 固件升级文件: 仅显示 .mot 文件
            ArrayList<FileType> fileTypes = new ArrayList<>();
            fileTypes.add(new MotFileType());
            config.registerFileType(fileTypes, true);
        }
        config.forResult(FilePickerManager.REQUEST_CODE);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == FilePickerManager.REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                String filePath = FilePickerManager.obtainData().get(0);
                Log.i("SelectFileActivity", "Selected File:" + filePath);
                if (callback != null) {
                    callback.onSelected(filePath);
                }
            }
            finish();
        } else {
            super.onActivityResult(requestCode, resultCode, data);
            finish();
        }
    }

    public interface Callback {
        void onSelected(String path);
    }

    static class FontType implements FileType {

        @Override
        public int getFileIconResId() {
            return R.drawable.drawable_font;
        }

        @NonNull
        @Override
        public String getFileType() {
            return "Font";
        }

        @Override
        public boolean verify(@NonNull final String s) {
            return s.toLowerCase().endsWith(".ttf") ||
                   s.toLowerCase().endsWith(".ttc") ||
                   s.toLowerCase().endsWith(".otf");
        }
    }

    //sh,2026.08.03 add 固件升级文件类型: 仅匹配 .mot
    static class MotFileType implements FileType {

        @Override
        public int getFileIconResId() {
            return R.drawable.drawable_font;
        }

        @NonNull
        @Override
        public String getFileType() {
            return "Firmware";
        }

        @Override
        public boolean verify(@NonNull final String s) {
            return s.toLowerCase().endsWith(".mot");
        }
    }
}
