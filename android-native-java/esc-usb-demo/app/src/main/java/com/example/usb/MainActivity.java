package com.example.usb;

import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

import android.bluetooth.BluetoothDevice;
import android.os.Bundle;


import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;

import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.esc.args.ELocation;
import com.printer.psdk.esc.mark.Location;
import com.printer.psdk.frame.father.PSDK;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;


public class MainActivity extends AppCompatActivity {
    private GenericESC esc;
    private USB usb;
    private Button switch_Usb;
    private Button continueButton;
    private EditText sampleEdit;
    private int sampleNumber;
    private Handler myHandler = new MyHandler();
    private boolean isOpen = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        switch_Usb = (Button) findViewById(R.id.switch_usb);
        sampleEdit = (EditText) findViewById(R.id.sampleEdit);
        sampleEdit.setText("1");
        continueButton = (Button) findViewById(R.id.print_continue);
        BluetoothDevice device = getIntent().getParcelableExtra("device");
        usb = new USB(this, myHandler);
        usb.register_USB();

        switch_Usb.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isOpen) {
                    usb.closeUsb();
                    switch_Usb.setText("打开USB");
                    isOpen = false;
                } else {
                    USBConnectedDevice usbConnectedDevice = usb.openUsb();
                    if (usbConnectedDevice != null) {
                        esc = ESC.generic(usbConnectedDevice);
                        switch_Usb.setText("关闭USB");
                        isOpen = true;
                    } else {
                        showMessage("打开失败，检查是否有可用的USB端口");
                    }

                }
            }

        });

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
                            if (isOpen) {
                                //打印图片指令
                                InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p2"));
                                BitmapDrawable bmpDraw = new BitmapDrawable(is);
                                Bitmap rawBitmap = bmpDraw.getBitmap();
                                rawBitmap = Bitmap.createScaledBitmap(rawBitmap, 500, 960, true);
                                GenericESC _gesc = esc
                                        .location(ELocation.builder().location(Location.CENTER).build())
                                        .image(EImage.builder()
                                                .image(bitmap2Bytes(rawBitmap))
                                                .build());
                                safeWrite(_gesc);
                            } else {
                                showMessage("请先打开串口！");
                            }
                        }
                    }
                }).start();
            }
        });


    }

    //第一个参数文件名称（不加后缀）， 第二个参数文件夹名称，第三个参数包名
    public int getImageID(String name) {
        return getResources().getIdentifier(name, "raw",
                getPackageName());
    }

    private class MyHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case USB.OPEN:
                    showMessage("USB已打开！");
                    switch_Usb.setText("关闭USB");
                    isOpen = true;
                    break;
                case USB.ATTACHED:
                    showMessage("监测到设备！");
                    usb.openUsb();
                    break;
                case USB.DETACHED:
                    showMessage("设备已移除！");
                    switch_Usb.setText("打开USB");
                    isOpen = false;
                    break;

            }
        }

    }

    //    private void dataListen(ConnectedDevice connectedDevice) {
//        DataListener.with(connectedDevice).listen(new ListenAction() {
//            @Override
//            public void action(byte[] bytes) {
//            //固件回传的数据
//            }
//        }).start();
//    }
    private byte[] bitmap2Bytes(Bitmap bm) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
        return baos.toByteArray();
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

    private void safeWrite(PSDK psdk) {
        try {
            WroteReporter reporter = psdk.write();
            if (!reporter.isOk()) {
                throw new IOException("写入数据失败", reporter.getException());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showMessage(String s) {
        Toast.makeText(this, s, Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (usb != null) {
            usb.unregister_USB();
        }
    }

}
