package com.printer.demo.fragments;

import static android.os.Build.VERSION.SDK_INT;

import android.Manifest;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.text.TextUtils;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.hjq.permissions.XXPermissions;
import com.printer.demo.ConfigPreference;
import com.printer.demo.GlobalPara;
import com.printer.demo.MainActivity;
import com.printer.demo.R;
import com.printer.demo.activities.SelectFileActivity;
import com.printer.demo.task.CardPositionTask;
import com.printer.demo.task.ClearCacheTask;
import com.printer.demo.task.ClosePrinterTask;
import com.printer.demo.task.EjectCardTask;
import com.printer.demo.task.EnumPrinterTask;
import com.printer.demo.task.InitPrinterTask;
import com.printer.demo.task.InjectCardTask;
import com.printer.demo.task.OpenPrinterTask;
import com.printer.demo.task.ShowStatusTask;
import com.printer.demo.view.BluetoothNetworkConfigView;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.LogConfig;
import com.printer.sdk.Printer;
import com.printer.sdk.operate.PrintData;
import com.printer.sdk.operate.UpdateFirmware;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class FragmentBase extends Fragment {


    private final Handler mainHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(@NonNull Message msg) {
            switch (msg.what) {
                case EnumPrinterTask.ENUM_PRINTER:
                    // noinspection unchecked
                    List<Printer> printers = (List<Printer>) msg.obj;
                    if (!printers.isEmpty()) {
                        printerAdapter.addAll(printers);
                    }
                    break;
                case ShowStatusTask.SHOW_STATUS:
                    if (msg.arg1 < 0) {
                        swShowStatus.setChecked(false);
                    }
                    tvStatus.setText((CharSequence) msg.obj);
                    break;
                default:
                    tvMsg.setText((CharSequence) msg.obj);
            }
        }
    };

    private static final String TAG = FragmentBase.class.getSimpleName();

    private ExecutorService executor;
    private ExecutorService statusExe;
    private Spinner spEnumType, spPrinter, spPrinterType;
    private ArrayAdapter<Printer> printerAdapter;
    private TextView tvStatus, tvMsg, tvScanTitle, tvScanDes, tvWifiModeTitle;
    private Button btOpenPrinter;
    private CheckBox useIpPrinterCheckBox;
    private EditText ipPort;
    private CardPrinterAPI api;
    private ShowStatusTask showStatusTask;
    private SwitchCompat swShowStatus, swSavePrnFile;
    private static final int PERMISSIONS_REQUEST_CODE = 100;
    private static final int REQUEST_PERMISSIONS_CODE = 1001;

    private BluetoothNetworkConfigView bluetoothNetworkConfigView;

    public FragmentBase() {
        super(R.layout.fragment_base);
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        api = ((MainActivity) context).api;
        showStatusTask = new ShowStatusTask(mainHandler, api);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        executor = Executors.newSingleThreadExecutor();
        statusExe = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            String logPath = ConfigPreference.with(requireContext()).getString(GlobalPara.KEY_LOG_PATH, null);
            if (TextUtils.isEmpty(logPath)){
                logPath=Environment.getExternalStorageDirectory()+ "/DsLog" +File.separator;
            }
            int overDay = ConfigPreference.with(requireContext()).getInt(GlobalPara.KEY_LOG_TIMEOUT, 7);
            int level = ConfigPreference.with(requireContext()).getInt(GlobalPara.KEY_LOG_LEVEL, 3);
            api.setLogConfig(new LogConfig(logPath, overDay, level));
        });
    }

    @Override
    public void onDestroy() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException ignore) {
        }
        statusExe.shutdown();
        try {
            if (!statusExe.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                statusExe.shutdownNow();
            }
        } catch (InterruptedException ignore) {
        }

        if (bluetoothNetworkConfigView != null) {
            bluetoothNetworkConfigView.release();
        }

        super.onDestroy();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        swShowStatus = view.findViewById(R.id.sw_printer_status);
        swShowStatus.setOnCheckedChangeListener((buttonView, isChecked) -> {
            showStatusTask.show(isChecked);
            if (isChecked) {
                statusExe.execute(showStatusTask);
            }
        });
        swSavePrnFile = view.findViewById(R.id.sw_save_prn);
        swSavePrnFile.setChecked(ConfigPreference.with(requireContext()).getString(GlobalPara.KEY_PRN_PATH, null) != null);
        swSavePrnFile.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                List<String> permission = new ArrayList<>();
                permission.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    permission.add(Manifest.permission.MANAGE_EXTERNAL_STORAGE);
                }
                XXPermissions.with(requireContext())
                        .permission(permission)
                        .unchecked()
                        .request((p, allGranted) -> {
                            if (allGranted) {
                                String path = Environment.getExternalStorageDirectory() + "/CardPrintPrn";
                                ConfigPreference.with(requireContext()).edit()
                                        .putString(GlobalPara.KEY_PRN_PATH, path)
                                        .apply();
                                Toast.makeText(requireContext(), getString(R.string.file_path) + path, Toast.LENGTH_LONG).show();
                            }
                        });
            } else {
                ConfigPreference.with(requireContext()).edit()
                        .putString(GlobalPara.KEY_PRN_PATH, null)
                        .apply();
                Toast.makeText(requireContext(), getString(R.string.setup_successful), Toast.LENGTH_SHORT).show();
            }
        });
        //sh,2026.08.03 add 固件升级按钮: 跳转选择文件 -> 回调中调用固件升级接口
        view.findViewById(R.id.bt_firmware_update).setOnClickListener(v ->
                SelectFileActivity.startSelectedFirmware(FragmentBase.this, this::onFirmwareSelected));

        initSpinner(view);
        tvStatus = view.findViewById(R.id.tv_status);
        tvMsg = view.findViewById(R.id.tv_msg);
        tvScanTitle = view.findViewById(R.id.tv_scan_title);
        tvScanDes = view.findViewById(R.id.tv_scan_des);
        tvWifiModeTitle = view.findViewById(R.id.tv_wifi_mode_title);

        view.findViewById(R.id.bt_enum_printer).setOnClickListener(v -> {
            printerAdapter.clear();
            executor.execute(new EnumPrinterTask(getContext(),mainHandler, api, spEnumType.getSelectedItemPosition()));
        });



        useIpPrinterCheckBox = view.findViewById(R.id.cb_use_ip);
        ipPort = view.findViewById(R.id.et_ip_port);
        btOpenPrinter = view.findViewById(R.id.bt_open_printer);

        btOpenPrinter.setOnClickListener(v -> {
            boolean useIpPrinter = useIpPrinterCheckBox.isChecked();
            if (useIpPrinter) {
                if (ipPort.getText() != null) {
                    String[] data = ipPort.getText().toString().split(":");
                    Printer printer = new Printer.NetworkPrinter(data[0], data[1]);
                    executor.execute(new OpenPrinterTask(mainHandler, api, printer));
                }
            } else {
                executor.execute(new OpenPrinterTask(mainHandler, api, (Printer) spPrinter.getSelectedItem()));
            }
        });
        view.findViewById(R.id.bt_close_printer).setOnClickListener(v -> new Thread(new ClosePrinterTask(mainHandler, api)).start());
        view.findViewById(R.id.bt_card_position).setOnClickListener(v -> executor.execute(new CardPositionTask(mainHandler, api)));
        view.findViewById(R.id.bt_inject_card).setOnClickListener(v -> executor.execute(new InjectCardTask(requireContext(), mainHandler, api)));
        view.findViewById(R.id.bt_eject_card).setOnClickListener(v -> executor.execute(new EjectCardTask(requireContext(), mainHandler, api)));

        view.findViewById(R.id.bt_init_printer).setOnClickListener(v -> new Thread(new InitPrinterTask(requireContext(), mainHandler, api)).start());
        view.findViewById(R.id.bt_clear_cache).setOnClickListener(v -> new Thread(new ClearCacheTask(requireContext(), mainHandler, api)).start());
        view.findViewById(R.id.bt_log_config).setOnClickListener(v -> {
            AlertDialog dialog = new AlertDialog.Builder(requireContext())
                    .setTitle(getString(R.string.log_config))
                    .setView(R.layout.log_config)
                    .setPositiveButton(getString(R.string.ok), (dlg, which) -> storeLogConfig())
                    .create();
            dialog.setOnShowListener(dlg -> prepareLogConfig(Objects.requireNonNull(((AlertDialog) dlg).getWindow()).getDecorView()));
            if (dialog.getWindow() != null) {
                dialog.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
            }
            dialog.show();
        });
        view.findViewById(R.id.bt_print_setting).setOnClickListener(v -> {
            AlertDialog dialog = new AlertDialog.Builder(requireContext())
                    .setTitle(getString(R.string.print_setting))
                    .setView(R.layout.layout_dialog_item3)
                    .setPositiveButton(getString(R.string.ok), (dlg, which) -> storeSetting())
                    .create();
            dialog.setOnShowListener(dlg -> prepareSetting(Objects.requireNonNull(((AlertDialog) dlg).getWindow()).getDecorView()));
            dialog.show();
        });

        // 初始化蓝牙配网view
        bluetoothNetworkConfigView = view.findViewById(R.id.bluetooth_config_view);
        // 设置蓝牙配置成功监听器
        bluetoothNetworkConfigView.setOnConfigSuccessListener(new BluetoothNetworkConfigView.OnConfigSuccessListener() {
            @Override
            public void onConfigSuccess(String ip, String port) {
                // 配置成功，更新IP和端口
                runOnUiThread(() -> {
                    useIpPrinterCheckBox.setChecked(true);
                    ipPort.setText(ip + ":" + port);

                    // 给打开打印机按钮添加动画
                    openPrinterBtnAnimation();
                    if (bluetoothNetworkConfigView.bleBluetoothHelper != null) {
                        bluetoothNetworkConfigView.bleBluetoothHelper.release();
                    }
                });
            }

            @Override
            public void onStatusUpdate(int state, String message) {
                // 更新状态消息
                runOnUiThread(() -> {
                    tvMsg.setText("状态：" + state + ", 消息：" + message);
                });
            }
        });
    }

    private Spinner spYmcDpi, spKDpi, spCMS;

    private void prepareSetting(View view) {
        SharedPreferences sharedPreferences = ConfigPreference.with(requireContext());
        int id = api.getPrinterSerial() == Printer.Serial.D300Kp ? R.array.d300kp_dpi : R.array.r600_dpi;
        ((TextView) view.findViewById(R.id.tv_label1)).setText(R.string.dpi_ymc);
        spYmcDpi = view.findViewById(R.id.sp_1);
        String[] items = getResources().getStringArray(id);
        spYmcDpi.setAdapter(new ArrayAdapter<>(requireContext(), android.R.layout.simple_list_item_1, Arrays.copyOf(items, Math.min(2, items.length))));
        ((TextView) view.findViewById(R.id.tv_label2)).setText(R.string.dpi_k);
        spKDpi = view.findViewById(R.id.sp_2);
        spKDpi.setAdapter(new ArrayAdapter<>(requireContext(), android.R.layout.simple_list_item_1, getResources().getStringArray(id)));
        if (api.getPrinterSerial() == Printer.Serial.D300Kp) {
            spYmcDpi.setSelection(sharedPreferences.getInt(GlobalPara.KEY_LAYER_COLOR_DPI, PrintData.PrintDpi.DPI300_300.ordinal()));
            spKDpi.setSelection(sharedPreferences.getInt(GlobalPara.KEY_LAYER_BLACK_DPI, PrintData.PrintDpi.DPI300_600.ordinal()));
        }
        ((TextView) view.findViewById(R.id.tv_label3)).setText(R.string.cms);
        items = new String[]{"OFF", "ON"};
        spCMS = view.findViewById(R.id.sp_3);
        spCMS.setAdapter(new ArrayAdapter<>(requireContext(), android.R.layout.simple_list_item_1, items));
        spCMS.setSelection(sharedPreferences.getInt(GlobalPara.KEY_CMS_ENABLED, 1));
    }

    private void storeSetting() {
        SharedPreferences.Editor editor = ConfigPreference.with(requireContext()).edit();
        if (api.getPrinterSerial() == Printer.Serial.D300Kp) {
            editor.putInt(GlobalPara.KEY_LAYER_COLOR_DPI, spYmcDpi.getSelectedItemPosition())
                    .putInt(GlobalPara.KEY_LAYER_BLACK_DPI, spKDpi.getSelectedItemPosition());
        }
        editor.putInt(GlobalPara.KEY_CMS_ENABLED, spCMS.getSelectedItemPosition()).apply();
        spYmcDpi = spKDpi = spCMS = null;
    }

    private EditText etLogPath, etLogOverDay;
    private Spinner spLogLevel;

    private void prepareLogConfig(View view) {
        etLogPath = view.findViewById(R.id.et_log_path);
        etLogOverDay = view.findViewById(R.id.et_over_day);
        spLogLevel = view.findViewById(R.id.sp_log_level);

        String logPath = ConfigPreference.with(requireContext()).getString(GlobalPara.KEY_LOG_PATH, "");
        if (logPath.isEmpty()) {
//            File file = new File(requireContext().getExternalFilesDir(""), "CardPrinter");
//            logPath = file.getAbsolutePath();


            logPath=Environment.getExternalStorageDirectory()+ "/DsLog" +File.separator;

            ConfigPreference.with(requireContext()).edit().putString(GlobalPara.KEY_LOG_PATH, logPath).apply();
        }
        etLogPath.setText(logPath);
        int overDay = ConfigPreference.with(requireContext()).getInt(GlobalPara.KEY_LOG_TIMEOUT, 7);
        etLogOverDay.setText(String.valueOf(overDay));
        int level = ConfigPreference.with(requireContext()).getInt(GlobalPara.KEY_LOG_LEVEL, 3);
        spLogLevel.setSelection(level);
    }


    private boolean checkExternalStoragePermission(){
        if (SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager();
        } else {
            int result =
                    ContextCompat.checkSelfPermission(getContext(), Manifest.permission.READ_EXTERNAL_STORAGE);
            int result1 =
                    ContextCompat.checkSelfPermission(getContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE);
            return result == PackageManager.PERMISSION_GRANTED && result1 == PackageManager.PERMISSION_GRANTED;
        }
    }


    private void storeLogConfig() {
        if (etLogOverDay.getText().length() == 0) {
            tvMsg.setText(getString(R.string.days_null));
            return;
        }
        if (etLogPath.getText().length() == 0) {
            tvMsg.setText(getString(R.string.path_null));
            return;
        }

        List<String> permission = new ArrayList<>();
        permission.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            permission.add(Manifest.permission.MANAGE_EXTERNAL_STORAGE);
        }
        XXPermissions.with(requireContext())
                .permission(permission)
                .unchecked()
                .request((p, allGranted) -> {
                    if (allGranted) {
                        ConfigPreference.with(requireContext()).edit()
                                .putString(GlobalPara.KEY_LOG_PATH, etLogPath.getText().toString())
                                .putInt(GlobalPara.KEY_LOG_TIMEOUT, Integer.parseInt(etLogOverDay.getText().toString()))
                                .putInt(GlobalPara.KEY_LOG_LEVEL, spLogLevel.getSelectedItemPosition())
                                .apply();
                        api.setLogConfig(new LogConfig(etLogPath.getText().toString(), Integer.parseInt(etLogOverDay.getText().toString()), spLogLevel.getSelectedItemPosition()));
                        tvMsg.setText(getString(R.string.log_set_ok));
                    } else {
                        tvMsg.setText(getString(R.string.permission_denied));
                    }
                    etLogPath = etLogOverDay = null;
                    spLogLevel = null;
                });
    }

    private void initSpinner(View view) {

        spEnumType = view.findViewById(R.id.sp_enum_type);
        printerAdapter = new ArrayAdapter<>(requireContext(), android.R.layout.simple_list_item_1);
        spPrinter = view.findViewById(R.id.sp_printer);
        spPrinter.setAdapter(printerAdapter);
    }





    private void openPrinterBtnAnimation() {
        ScaleAnimation scaleAnimation = new ScaleAnimation(
                1.0f, // 初始缩放X
                1.5f, // 结束缩放X
                1.0f, // 初始缩放Y
                1.5f, // 结束缩放Y
                Animation.RELATIVE_TO_SELF, 0.5f, // 缩放中心点X
                Animation.RELATIVE_TO_SELF, 0.5f  // 缩放中心点Y
        );
        scaleAnimation.setDuration(1000); // 动画持续时间
        scaleAnimation.setRepeatCount(1); // 重复一次
        scaleAnimation.setRepeatMode(Animation.REVERSE); // 倒序重复

        // 启动动画
        btOpenPrinter.startAnimation(scaleAnimation);
    }


    //sh,2026.08.03 add 固件文件选择回调: 在后台线程读文件为字节数组并调用固件升级接口
    private void onFirmwareSelected(String path) {
        executor.execute(() -> {
            try {
                mainHandler.post(() -> tvMsg.setText(""));
                File file = new File(path);
                byte[] firmware = readFileToBytes(file);
                api.printerOp(new UpdateFirmware(firmware));
                mainHandler.post(() -> tvMsg.setText(getString(R.string.firmware_update_success)));
            } catch (Exception e) {
                mainHandler.post(() -> tvMsg.setText(getString(R.string.firmware_update_fail) + e.getMessage()));
            }
        });
    }

    //sh,2026.08.17 add 读取固件文件为字节数组(约2MB, WiFi 传输, 不分包)
    private byte[] readFileToBytes(File file) throws Exception {
        byte[] firmware = new byte[(int) file.length()];
        try (java.io.InputStream in = new java.io.FileInputStream(file)) {
            int offset = 0;
            int read;
            while (offset < firmware.length
                    && (read = in.read(firmware, offset, firmware.length - offset)) != -1) {
                offset += read;
            }
        }
        return firmware;
    }

    private void runOnUiThread(Runnable runnable) {
        requireActivity().runOnUiThread(runnable);
    }

}
