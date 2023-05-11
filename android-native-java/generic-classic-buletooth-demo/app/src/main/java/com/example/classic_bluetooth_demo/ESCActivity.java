package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.frame.father.PSDK;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class ESCActivity extends Activity {
    private Connection connection;
    private TextView tv_connect_status;
    private GenericESC esc;
    private Button continueButton;
    private Button labelButton;
    private Button statusButton;
    private Button batteryVolButton;
    private Button version_printerButton;
    private Button snButton;
    private Button modelButton;
    private Button macaddressButton;
    private Button bt_nameButton;
    private Button version_btButton;
    private EditText sampleEdit;
    private int sampleNumber;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_esc);
        tv_connect_status = findViewById(R.id.tv_connect_status);
        sampleEdit = (EditText) findViewById(R.id.sampleEdit);
        sampleEdit.setText("1");
        continueButton = (Button) findViewById(R.id.print_continue);
        labelButton = (Button) findViewById(R.id.printer_label);
        statusButton = (Button) findViewById(R.id.printer_status);
        batteryVolButton = (Button) findViewById(R.id.printer_BatteryVol);
        version_printerButton = (Button) findViewById(R.id.printer_version);
        snButton = (Button) findViewById(R.id.printer_SN);
        modelButton = (Button) findViewById(R.id.printer_model);
        macaddressButton = (Button) findViewById(R.id.mac_address);
        bt_nameButton = (Button) findViewById(R.id.bt_name);
        version_btButton = (Button) findViewById(R.id.bt_version);
        BluetoothDevice device = getIntent().getParcelableExtra("device");

        connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
            @Override
            public void onConnectSuccess(ConnectedDevice connectedDevice) {
                esc = ESC.generic(connectedDevice);
            }

            @Override
            public void onConnectFail(String errMsg, Throwable e) {
            }

            @Override
            public void onConnectionStateChanged(BluetoothDevice device, int state) {
                String msg;
                switch (state) {
                    case Connection.STATE_CONNECTING:
                        msg = "连接中";
                        break;
                    case Connection.STATE_PAIRING:
                        msg = "配对中...";
                        break;
                    case Connection.STATE_PAIRED:
                        msg = "配对成功";
                        break;
                    case Connection.STATE_CONNECTED:
                        msg = "连接成功";
                        break;
                    case Connection.STATE_DISCONNECTED:
                        msg = "连接断开";
                        break;
                    case Connection.STATE_RELEASED:
                        msg = "连接已销毁";
                        break;
                    default:
                        msg = "";
                }
                if (!msg.isEmpty()) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            tv_connect_status.setText(device.getName() + msg);
                        }
                    });
                }
            }
        });
        if (connection == null) {
            finish();
            return;
        }
        new Thread(new Runnable() {
            @Override
            public void run() {
                connection.connect(null);
            }
        }).start();
        continueButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (sampleEdit.getText().toString().trim().equals("")) {
                    sampleNumber = 1;
                } else {
                    sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
                }
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        for (int i = 0; i < sampleNumber; i++) {
                            if (connection.isConnected()) {
                                //打印图片指令
                                BitmapFactory.Options mOptions = new BitmapFactory.Options();
                                mOptions.inScaled = false;
                                Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.test, mOptions);
                                GenericESC _gesc = esc.enable()
                                        .wakeup()
                                        .lineDot(1)
                                        .image(EImage.builder()
                                                .image(bitmap2Bytes(bitmap))
                                                .build())
                                        .lineDot(1)
                                        .stopJob();
                                safeWriteAndRead(_gesc);
                            }
                        }
                    }
                }).start();
            }
        });
        labelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (sampleEdit.getText().toString().trim().equals("")) {
                    sampleNumber = 1;
                } else {
                    sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
                }
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        for (int i = 0; i < sampleNumber; i++) {
                            if (connection.isConnected()) {
                                //打印图片指令
                                BitmapFactory.Options mOptions = new BitmapFactory.Options();
                                mOptions.inScaled = false;
                                Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.test, mOptions);
                                GenericESC _gesc = esc.enable()
                                        .wakeup()
                                        .lineDot(1)
                                        .image(EImage.builder()
                                                .image(bitmap2Bytes(bitmap))
                                                .build())
                                        .lineDot(1)
                                        .stopJob()
                                        .position();//标签纸打印就是打印结束后多执行了这个指令
                                safeWriteAndRead(_gesc);
                            }
                        }
                    }
                }).start();
            }
        });
        statusButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.state();
                byte[] result = safeWriteAndRead(_gesc);
                if (result==null) return;
                if (result.length == 1) {//状态返回值根据具体机型判断 不同机型有差异
                    String s = "状态：";
                    boolean isok = true;
                    if (result[0] == 0x01) {
                        s += "正在打印 ";
                        isok = false;
                    }
                    if (result[0] == 0x02) {
                        s += "纸舱盖开 ";
                        isok = false;
                    }
                    if (result[0] == 0x04) {
                        s += "缺纸 ";
                        isok = false;
                    }
                    if (result[0] == 0x08) {
                        s += "电池电压低 ";
                        isok = false;
                    }
                    if (result[0] == 0x10) {
                        s += "打印头过热 ";
                        isok = false;
                    }
                    if (isok) {
                        s += "良好";
                    }
                    show(s);
                }
            }
        });
        batteryVolButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.batteryVolume();
                byte[] result = safeWriteAndRead(_gesc);
                if (result==null) return;
                if (result.length == 2) {
                    String s = "电量：" + (int) result[1];
                    show(s);
                }
            }
        });
        version_printerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.printerVersion();
                byte[] result = safeWriteAndRead(_gesc);
                show(new String(result));
            }
        });
        snButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.sn();
                byte[] result = safeWriteAndRead(_gesc);
                show(new String(result));
            }
        });
        modelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.model();
                byte[] result = safeWriteAndRead(_gesc);
                show(new String(result));
            }
        });
        macaddressButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.mac();
                byte[] result = safeWriteAndRead(_gesc);
                if (result==null) return;
                show( ByteArrToHex(result));
            }
        });
        bt_nameButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.name();
                byte[] result = safeWriteAndRead(_gesc);
                show(new String(result));
            }
        });
        version_btButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericESC _gesc = esc.version();
                byte[] result = safeWriteAndRead(_gesc);
                show(new String(result));
            }
        });
    }
    private String Byte2Hex(Byte inByte) {
        return String.format("%02x", inByte).toUpperCase();
    }

    private String ByteArrToHex(byte[] inBytArr) {
        StringBuilder strBuilder = new StringBuilder();
        int j = inBytArr.length;
        for (int i = 0; i < j; i++) {
            strBuilder.append(Byte2Hex(inBytArr[i]));
            strBuilder.append(" ");
        }
        return strBuilder.toString();
    }
    private byte[] bitmap2Bytes(Bitmap bm) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
        return baos.toByteArray();
    }

    private byte[] safeWriteAndRead(PSDK psdk) {
        try {
            WroteReporter reporter = psdk.write();
            if (!reporter.isOk()) {
                throw new IOException("写入数据失败", reporter.getException());
            }
            Thread.sleep(200);
            return psdk.read(ReadOptions.builder().timeout(2000).build());
        } catch (Exception e) {
            return null;
        }
    }

    private void show(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        connection.disconnect();
    }

}
