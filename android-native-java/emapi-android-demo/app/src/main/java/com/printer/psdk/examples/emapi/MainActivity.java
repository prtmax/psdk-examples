package com.printer.psdk.examples.emapi;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.InputType;
import android.widget.Toast;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.List;

public final class MainActivity extends Activity implements EmapiDemoController.Listener {
    private static final int PICK_WIFI_FILE = 1;
    private static final int PICK_OTA_FILE = 2;
    private static final int PICK_ESC_IMAGE = 3;
    private static final int REQUEST_BLUETOOTH_PERMISSIONS = 100;

    private EmapiDemoController controller;
    private LinearLayout root;
    private LinearLayout content;
    private LinearLayout bottomPanel;
    private boolean operationExpanded = true;
    private int page = 0;
    private int logTab = 0;
    private EditText activePathField;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        controller = new EmapiDemoController(this);
        controller.init(this);
        render();
    }

    @Override
    protected void onDestroy() {
        controller.destroy();
        super.onDestroy();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_BLUETOOTH_PERMISSIONS) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                Toast.makeText(this, "蓝牙权限已获取", Toast.LENGTH_SHORT).show();
                // 权限获取后自动开始扫描
                controller.startScan(this);
            } else {
                Toast.makeText(this, "缺少蓝牙权限，扫描可能失败", Toast.LENGTH_LONG).show();
            }
        }
    }

    private boolean checkBluetoothPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            // Android 11 及以下需要定位权限
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION},
                        REQUEST_BLUETOOTH_PERMISSIONS);
                return false;
            }
            return true;
        }
        // Android 12+ 需要 BLUETOOTH_SCAN 和 BLUETOOTH_CONNECT 权限
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                != PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.BLUETOOTH_SCAN,
                            Manifest.permission.BLUETOOTH_CONNECT},
                    REQUEST_BLUETOOTH_PERMISSIONS);
            return false;
        }
        return true;
    }

    @Override
    public void onChanged() {
        render();
    }

    private void render() {
        if (root == null) {
            root = new LinearLayout(this);
            root.setOrientation(LinearLayout.VERTICAL);
            root.setBackgroundColor(0xfff6f7f2);
            setContentView(root);
        }
        root.removeAllViews();
        root.addView(topBar());
        ScrollView scrollView = new ScrollView(this);
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(16), dp(12), dp(16), dp(16));
        scrollView.addView(content);
        root.addView(scrollView, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        if (page == 1) {
            renderSettingsPage();
        } else if (controller.connected) {
            renderFunctionPage(scrollView);
        } else {
            renderScanPage();
        }
    }

    private View topBar() {
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(16), dp(10), dp(16), dp(10));
        bar.setBackgroundColor(0xffffffff);
        TextView title = new TextView(this);
        title.setText("EMAPI Android Demo");
        title.setTextSize(20);
        title.setTextColor(0xff18201d);
        title.setGravity(Gravity.CENTER_VERTICAL);
        bar.addView(title, new LinearLayout.LayoutParams(0, dp(44), 1));
        Button settings = compactButton(page == 1 ? "返回" : "设置");
        settings.setEnabled(!controller.busy());
        settings.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                page = page == 1 ? 0 : 1;
                render();
            }
        });
        bar.addView(settings);
        if (controller.connected) {
            Button disconnect = compactButton("断开");
            disconnect.setEnabled(!controller.busy());
            disconnect.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    controller.disconnect();
                }
            });
            bar.addView(disconnect);
        }
        return bar;
    }

    private void renderScanPage() {
        addPanel(controller.simulationMode ? "模拟测试台" : "蓝牙设备", controller.simulationMode
            ? "生成模拟蓝牙设备，并使用模拟 EMAPI 操作结果完成全流程。"
            : (controller.bluetoothEnabled ? "扫描附近或已配对的蓝牙打印机。" : "蓝牙未开启，开启后可扫描真实设备。"));
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        Button start = button(controller.scanning ? "扫描中" : "开始扫描");
        start.setEnabled(!controller.busy() && !controller.scanning);
        start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // 先检查蓝牙权限
                if (checkBluetoothPermissions()) {
                    controller.startScan(MainActivity.this);
                }
            }
        });
        row.addView(start, new LinearLayout.LayoutParams(0, dp(48), 1));
        Button stop = button("停止");
        stop.setEnabled(controller.scanning && !controller.busy());
        stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                controller.stopScan();
            }
        });
        row.addView(stop, new LinearLayout.LayoutParams(0, dp(48), 1));
        content.addView(row);
        sectionTitle("设备列表");
        if (controller.devices.isEmpty()) {
            TextView empty = body("暂无设备，点击开始扫描。");
            empty.setGravity(Gravity.CENTER);
            content.addView(empty, matchWrap());
        } else {
            for (final DeviceModel device : controller.devices) {
                LinearLayout item = card();
                item.setOrientation(LinearLayout.HORIZONTAL);
                TextView text = body(device.name + "\n" + device.protocol + " / " + device.address);
                item.addView(text, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
                Button connect = compactButton("连接");
                connect.setEnabled(!controller.busy());
                connect.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        controller.connect(device);
                    }
                });
                item.addView(connect);
                content.addView(item);
            }
        }
    }

    private void renderSettingsPage() {
        sectionTitle("设置");
        LinearLayout panel = card();
        panel.setOrientation(LinearLayout.VERTICAL);
        TextView title = title("测试模式");
        panel.addView(title);
        CheckBox simulation = new CheckBox(this);
        simulation.setText("模拟模式");
        simulation.setTextSize(16);
        simulation.setChecked(controller.simulationMode);
        simulation.setEnabled(!controller.busy());
        simulation.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                controller.setSimulationMode(isChecked);
            }
        });
        panel.addView(simulation);
        panel.addView(body("开启后会生成模拟蓝牙设备，并返回模拟 EMAPI 操作结果；切换模式会断开当前设备并重置扫描状态。"));
        content.addView(panel);
    }

    private void renderFunctionPage(ScrollView scrollView) {
        addPanel(controller.connectedDeviceName == null ? "EMAPI printer" : controller.connectedDeviceName,
            (controller.pendingActionLabel == null ? "等待操作" : "正在执行：" + controller.pendingActionLabel) + "\n" + (controller.simulationMode ? "模拟模式" : "真实蓝牙连接"));
        renderLogTabs();

        // 底部功能区，可收起展开
        if (bottomPanel != null) {
            root.removeView(bottomPanel);
        }
        bottomPanel = new LinearLayout(this);
        bottomPanel.setOrientation(LinearLayout.VERTICAL);
        bottomPanel.setBackgroundColor(0xffffffff);

        // 切换按钮
        final Button toggleBtn = compactButton(operationExpanded ? "功能区 ▲" : "功能区 ▼");
        toggleBtn.setBackgroundColor(0xffe8e8e8);
        toggleBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                operationExpanded = !operationExpanded;
                render();
            }
        });
        bottomPanel.addView(toggleBtn);

        // 功能区内容
        if (operationExpanded) {
            LinearLayout wrapper = new LinearLayout(this);
            wrapper.setOrientation(LinearLayout.VERTICAL);
            wrapper.setPadding(dp(12), dp(8), dp(12), dp(12));
            renderOperationArea(wrapper);
            bottomPanel.addView(wrapper);
        }

        root.addView(bottomPanel, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
    }

    private void renderLogTabs() {
        LinearLayout tabs = new LinearLayout(this);
        tabs.setOrientation(LinearLayout.HORIZONTAL);
        String[] labels = {"发送指令", "命令结果", "上报解析"};
        for (int i = 0; i < labels.length; i++) {
            final int index = i;
            Button tab = compactButton(labels[i]);
            tab.setEnabled(logTab != index);
            tab.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    logTab = index;
                    render();
                }
            });
            tabs.addView(tab, new LinearLayout.LayoutParams(0, dp(42), 1));
        }
        content.addView(tabs);
        List<LogEntry> logs = logTab == 0 ? controller.requestLogs : logTab == 1 ? controller.commandLogs : controller.reportLogs;
        if (logs.isEmpty()) {
            content.addView(body("暂无日志"));
            return;
        }
        for (LogEntry entry : logs) {
            LinearLayout card = card();
            card.setOrientation(LinearLayout.VERTICAL);
            card.addView(title(entry.title));
            card.addView(body(entry.message));
            if (entry.bytes != null) {
                TextView bytes = body(Hex.command(entry.bytes));
                bytes.setTextSize(12);
                card.addView(bytes);
            }
            content.addView(card);
        }
    }

    private void renderOperationArea(ViewGroup parent) {
        TextView title = title("功能区");
        title.setPadding(0, 0, 0, dp(6));
        parent.addView(title);
        String[] labels = {"休眠关机", "打印自检页", "设置关机时间", "RFID UID", "RFID 信息", "纸张长度", "RFID 失败处理", "配网信息", "WIFI 状态", "热点信息", "WiFi 文件传输", "基本参数", "打印状态", "ESC 打印", "OTA 升级"};
        View.OnClickListener[] handlers = {
            new View.OnClickListener() { public void onClick(View v) { controller.sleepShutdown(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.printSelfTestPage(); } },
            new View.OnClickListener() { public void onClick(View v) { showShutdownDialog(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryRfidUid(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryRfidCardInfo(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryRfidPaperLength(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.setRfidAuthFailureHandling(); } },
            new View.OnClickListener() { public void onClick(View v) { showWifiDialog(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryWifiConnectionState(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryWifiHotspotInfo(); } },
            new View.OnClickListener() { public void onClick(View v) { showWifiFileDialog(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryDeviceInfo(); } },
            new View.OnClickListener() { public void onClick(View v) { controller.queryPrintStatus(); } },
            new View.OnClickListener() { public void onClick(View v) { showEscDialog(); } },
            new View.OnClickListener() { public void onClick(View v) { showOtaDialog(); } }
        };
        for (int i = 0; i < labels.length; i += 3) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            for (int j = i; j < Math.min(i + 3, labels.length); j++) {
                Button item = compactButton(labels[j]);
                item.setEnabled(!controller.busy());
                item.setOnClickListener(handlers[j]);
                row.addView(item, new LinearLayout.LayoutParams(0, dp(54), 1));
            }
            parent.addView(row);
        }
        TextView progress = body(controller.transferProgress());
        progress.setGravity(Gravity.CENTER);
        parent.addView(progress);
        ProgressBar bar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        bar.setMax(Math.max(controller.transferTotalBytes, 1));
        bar.setProgress(controller.transferSentBytes);
        parent.addView(bar, matchWrap());
    }

    private void showShutdownDialog() {
        final String[] values = {"15", "30", "60"};
        new AlertDialog.Builder(this)
            .setTitle("设置关机时间")
            .setSingleChoiceItems(values, 1, null)
            .setPositiveButton("提交", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    int selected = ((AlertDialog) dialog).getListView().getCheckedItemPosition();
                    controller.setShutdownTime(Integer.parseInt(values[selected < 0 ? 1 : selected]));
                }
            })
            .setNegativeButton("取消", null)
            .show();
    }

    private void showWifiDialog() {
        LinearLayout form = form();
        final EditText ssid = field("WiFi SSID", false);
        final EditText password = field("WiFi 密码", true);
        form.addView(ssid);
        form.addView(password);
        new AlertDialog.Builder(this)
            .setTitle("配网信息")
            .setView(form)
            .setPositiveButton("提交", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    controller.setWifiConfig(ssid.getText().toString(), password.getText().toString());
                }
            })
            .setNegativeButton("取消", null)
            .show();
    }

    private void showWifiFileDialog() {
        LinearLayout form = form();
        final EditText path = field("文件路径", false);
        final Spinner type = new Spinner(this);
        type.setAdapter(new ArrayAdapter<String>(this, android.R.layout.simple_spinner_dropdown_item, new String[]{
            "0x0001 WiFi主控升级文件(.bin)",
            "0x0002 日历图像文件",
            "0x0003 待机图像文件"
        }));
        Button pick = button("选择文件");
        pick.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                activePathField = path;
                pickFile(PICK_WIFI_FILE);
            }
        });
        form.addView(path);
        form.addView(type);
        form.addView(pick);
        new AlertDialog.Builder(this)
            .setTitle("WiFi 文件传输")
            .setView(form)
            .setPositiveButton("开始传输", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    controller.performWifiFileTransfer(path.getText().toString(), type.getSelectedItemPosition() + 1);
                }
            })
            .setNegativeButton("取消", null)
            .show();
    }

    private void showOtaDialog() {
        LinearLayout form = form();
        final EditText path = field("OTA 文件路径", false);
        Button pick = button("选择 OTA 文件");
        pick.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                activePathField = path;
                pickFile(PICK_OTA_FILE);
            }
        });
        form.addView(path);
        form.addView(pick);
        new AlertDialog.Builder(this)
            .setTitle("OTA 升级")
            .setView(form)
            .setPositiveButton("开始 OTA 升级", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    controller.performOta(path.getText().toString());
                }
            })
            .setNegativeButton("取消", null)
            .show();
    }

    private void showEscDialog() {
        LinearLayout form = form();
        final EditText path = field("图片路径", false);
        Button pick = button("选择图片");
        pick.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                activePathField = path;
                pickFile(PICK_ESC_IMAGE);
            }
        });
        final RadioGroup paper = radioGroup(new String[]{"连续", "间隙", "黑标"});
        final RadioGroup mode = radioGroup(new String[]{"普通", "双重", "灰阶"});
        final SeekBar thickness = new SeekBar(this);
        thickness.setMax(15);
        thickness.setProgress(8);
        final TextView thicknessLabel = body("厚度：8");
        thickness.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) { thicknessLabel.setText("厚度：" + progress); }
            @Override public void onStartTrackingTouch(SeekBar seekBar) { }
            @Override public void onStopTrackingTouch(SeekBar seekBar) { }
        });
        final CheckBox compress = new CheckBox(this);
        compress.setText("图像压缩");
        compress.setChecked(false);
        form.addView(path);
        form.addView(pick);
        form.addView(body("纸张类型"));
        form.addView(paper);
        form.addView(body("打印模式"));
        form.addView(mode);
        form.addView(thicknessLabel);
        form.addView(thickness);
        form.addView(compress);
        new AlertDialog.Builder(this)
            .setTitle("ESC 打印")
            .setView(form)
            .setPositiveButton("开始打印", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    EscPrintOptions options = new EscPrintOptions();
                    options.paperType = selectedRadioIndex(paper);
                    options.printMode = selectedRadioIndex(mode);
                    options.thickness = thickness.getProgress();
                    options.compress = compress.isChecked();
                    controller.performEscPrint(path.getText().toString(), options);
                }
            })
            .setNegativeButton("取消", null)
            .show();
    }

    private void pickFile(int requestCode) {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        startActivityForResult(intent, requestCode);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode != RESULT_OK || data == null || activePathField == null) {
            return;
        }
        Uri uri = data.getData();
        if (uri == null) {
            return;
        }
        try {
            File file = new File(getCacheDir(), "emapi-selected-" + requestCode + ".bin");
            InputStream input = getContentResolver().openInputStream(uri);
            FileOutputStream output = new FileOutputStream(file);
            byte[] buffer = new byte[8192];
            int count;
            while (input != null && (count = input.read(buffer)) >= 0) {
                output.write(buffer, 0, count);
            }
            if (input != null) {
                input.close();
            }
            output.close();
            activePathField.setText(file.getAbsolutePath());
        } catch (Exception error) {
            activePathField.setText(uri.toString());
        }
    }

    private void addPanel(String title, String message) {
        LinearLayout panel = card();
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.addView(title(title));
        panel.addView(body(message));
        content.addView(panel);
    }

    private void sectionTitle(String text) {
        TextView view = title(text);
        view.setPadding(0, dp(18), 0, dp(8));
        content.addView(view);
    }

    private LinearLayout card() {
        LinearLayout card = new LinearLayout(this);
        card.setPadding(dp(12), dp(12), dp(12), dp(12));
        card.setBackgroundColor(0xffffffff);
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, 0, 0, dp(10));
        card.setLayoutParams(params);
        return card;
    }

    private TextView title(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextColor(0xff18201d);
        view.setTextSize(18);
        view.setGravity(Gravity.CENTER_VERTICAL);
        return view;
    }

    private TextView body(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextColor(0xff39433e);
        view.setTextSize(14);
        view.setPadding(0, dp(4), 0, dp(4));
        return view;
    }

    private Button button(String text) {
        Button view = new Button(this);
        view.setText(text);
        view.setAllCaps(false);
        return view;
    }

    private Button compactButton(String text) {
        Button view = button(text);
        view.setMinHeight(0);
        view.setMinWidth(0);
        view.setPadding(dp(8), 0, dp(8), 0);
        return view;
    }

    private EditText field(String hint, boolean password) {
        EditText field = new EditText(this);
        field.setHint(hint);
        field.setSingleLine(true);
        if (password) {
            field.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        }
        return field;
    }

    private LinearLayout form() {
        LinearLayout form = new LinearLayout(this);
        form.setOrientation(LinearLayout.VERTICAL);
        form.setPadding(dp(8), dp(8), dp(8), 0);
        return form;
    }

    private RadioGroup radioGroup(String[] labels) {
        RadioGroup group = new RadioGroup(this);
        group.setOrientation(RadioGroup.HORIZONTAL);
        for (int i = 0; i < labels.length; i++) {
            RadioButton item = new RadioButton(this);
            item.setText(labels[i]);
            item.setId(100 + i);
            group.addView(item);
        }
        group.check(100);
        return group;
    }

    private int selectedRadioIndex(RadioGroup group) {
        return Math.max(0, group.getCheckedRadioButtonId() - 100);
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }
}
