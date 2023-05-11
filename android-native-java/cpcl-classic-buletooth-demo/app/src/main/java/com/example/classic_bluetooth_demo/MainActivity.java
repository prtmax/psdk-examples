package com.example.classic_bluetooth_demo;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import com.printer.psdk.cpcl.CPCL;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.*;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.logger.PLog;

import java.io.ByteArrayOutputStream;
import java.io.IOException;


public class MainActivity extends AppCompatActivity {
    private Connection connection;
    private TextView tv_connect_status;
    private EditText etMsg;
    private Button btnText, btnBitmap, btnStatus, btnBarCode, btnQRCode, btnModel;
    private GenericCPCL cpcl;
    private EditText sampleEdit;
    private int sampleNumber;
    private boolean isSending = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        tv_connect_status = findViewById(R.id.tv_connect_status);
        etMsg = findViewById(R.id.etMsg);
        btnText = findViewById(R.id.btnText);
        btnBitmap = findViewById(R.id.btnBitmap);
        btnStatus = findViewById(R.id.btnStatus);
        btnBarCode = findViewById(R.id.btnBarCode);
        btnQRCode = findViewById(R.id.btnQRCode);
        btnModel = findViewById(R.id.btnModel);
        sampleEdit = (EditText) findViewById(R.id.sampleEdit);
        sampleEdit.setText("1");
        BluetoothDevice device = getIntent().getParcelableExtra("device");

        connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
            @Override
            public void onConnectSuccess(ConnectedDevice connectedDevice) {
                cpcl = CPCL.generic(connection);
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
        EditText etMsg = findViewById(R.id.etMsg);
        btnText.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(100).height(100).build())
                        .text(CText.builder().content(etMsg.getText().toString()).build())
                        .print(CPrint.builder().build());
                String result = safeWriteAndRead(_gcpcl);
                show(result);
            }

        });
        btnBitmap.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                BitmapFactory.Options mOptions = new BitmapFactory.Options();
                mOptions.inScaled = false;
                Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.logo, mOptions);
                GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(400).height(320).build())
                        .image(CImage.builder()
                                .startX(10)
                                .startY(0)
                                .image(bitmap2Bytes(bitmap))
                                .compress(true)
                                .build()
                        )
                        .print(CPrint.builder().build());
                Log.e("jcz",_gcpcl.command().string());
                String result = safeWriteAndRead(_gcpcl);
                show(result);
            }
        });


        btnStatus.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericCPCL _gcpcl = cpcl.status();
                byte[] result = safeWriteAndReadByte(_gcpcl);
                show(printerStatus(result));
            }
        });

        btnBarCode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(350).build())
                        .bar(CBar.builder().x(10).y(10).content("1236549879").height(50).lineWidth(4).build())
//                        .raw(Raw.builder().command("CENTER").build())
//                        .push(BarImage.builder()
//                                .startX(0)
//                                .startY(50)
//                                .text("K0101003000000027-110-20")
//                                .height(80)
//                                .ratio(1)
//                                .compress(false)//打印机如果支持zlib压缩 参数就可以设置成true
//                                .build())
//                        .raw(Raw.builder().command("LEFT").build())
                        .print(CPrint.builder().build());
                String result = safeWriteAndRead(_gcpcl);
                show(result);
            }
        });
        btnQRCode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(350).build())
//                        .raw(Raw.builder().command("CENTER").build())
//                        .push(QRImage.builder()
//                                .startX(50)
//                                .startY(50)
//                                .text("{\"filePath\":\"http://115.239.138.184:18081/v1/saferycom/n/zjdx/ocr/downloadTemplate?scannerId=66b74ce605284727bb0cc773f2e38c18\",\"filePathType\":\"manager_attachment\",\"fileName\":\"aaaa\",\"cust-order-token\":\"11\",\"x-auth-token\":\"f41d8f86-78ec-4272-bbfb-f27d5b3b49c7\",\"X-orgId\":\"786452672\",\"X-SysUserCode\":\"18069824284\"}")
//                                .size(300)
//                                .compress(false)//打印机如果支持zlib压缩 参数就可以设置成true
//                                .build())
//                        .raw(Raw.builder().command("LEFT").build())
                        .qrcode(CQRCode.builder().content("zhongwen中午").build())
                        .print(CPrint.builder().build());
                String result = safeWriteAndRead(_gcpcl);
                show(result);
            }
        });
        btnModel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (sampleEdit.getText().toString().trim().equals("")) {
                    sampleNumber = 1;
                } else {
                    sampleNumber = Integer.valueOf(sampleEdit.getText().toString().trim());
                }
                if (!isSending) {
                    new Thread(new Runnable() {
                        @Override
                        public void run() {
                            for (int i = 0; i < sampleNumber; i++) {
                                isSending = true;
                                try {
                                    printNow();
                                } catch (Exception e) {

                                }
//                        try {
//                            Thread.sleep(1000);
//                        } catch (InterruptedException e) {
//                            e.printStackTrace();
//                        }
                                if (i == (sampleNumber - 1)) {
                                    isSending = false;
                                }

                            }

                        }
                    }).start();
                }

            }
        });
    }
    private void printNow() {
        GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1040).copies(1).build())
                .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(664).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(88).endX(598).endY(88).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(88+128).endX(598).endY(88+128).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(88+128+80).endX(598).endY(88+128+80).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(88+128+80+144).endX(598-56-16).endY(88+128+80+144).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(88+128+80+144+128).endX(598-56-16).endY(88+128+80+144+128).lineWidth(2).build())
                .line(CLine.builder().startX(52).startY(88+128+80).endX(52).endY(88+128+80+144+128).lineWidth(2).build())
                .line(CLine.builder().startX(598-56-16).startY(88+128+80).endX(598-56-16).endY(664).lineWidth(2).build())
                .bar(CBar.builder().x(120).y(88+12).lineWidth(1).height(80).content("1234567890").codeType(CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
                .text(CText.builder().textX(120+12).textY(88+20+76).font(Font.TSS24).content("1234567890").build())
                .text(CText.builder().textX(12).textY(88 +128 + 80 +32).font(Font.TSS24).content("收").build())
                .text(CText.builder().textX(12).textY(88 +128 + 80 +96).font(Font.TSS24).content("件").build())
                .text(CText.builder().textX(12).textY(88+128+80+144+32).font(Font.TSS24).content("发").build())
                .text(CText.builder().textX(12).textY(88+128+80+144+80).font(Font.TSS24).content("件").build())
                .text(CText.builder().textX(52+20).textY(88+128+80+144+128+16).font(Font.TSS24).content("签收人/签收时间").build())
                .text(CText.builder().textX(430).textY(88+128+80+144+128+36).font(Font.TSS24).content("月").build())
                .text(CText.builder().textX(490).textY(88+128+80+144+128+36).font(Font.TSS24).content("日").build())
                .text(CText.builder().textX(52+20).textY(88+128+80+24).font(Font.TSS24).content("收姓名"+" "+"13777777777").build())
                .text(CText.builder().textX(52+20).textY(88 +128+80+24+32).font(Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
                .text(CText.builder().textX(52+20).textY(88+128+80+144+24).font(Font.TSS24).content("名字"+" "+"13777777777").build())
                .text(CText.builder().textX(52+20).textY(88+128+80+144+24+32).font(Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
                .text(CText.builder().textX(598-56-5).textY(88 +128+80+104).font(Font.TSS24).content("派").build())
                .text(CText.builder().textX(598-56-5).textY(88 +128+80+160).font(Font.TSS24).content("件").build())
                .text(CText.builder().textX(598-56-5).textY(88 +128+80+208).font(Font.TSS24).content("联").build())
                .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(968).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(696 + 80).endX(598).endY(696 + 80).lineWidth(2).build())
                .line(CLine.builder().startX(0).startY(696 + 80 + 136).endX(598 - 56 - 16).endY(696 + 80 + 136).lineWidth(2).build())
                .line(CLine.builder().startX(52).startY(80).endX(52).endY(696 + 80 + 136).lineWidth(2).build())
                .line(CLine.builder().startX(598 - 56 - 16).startY(80).endX(598 - 56 - 16).endY(968).lineWidth(2).build())
                .bar(CBar.builder().x(320).y(696 - 4).lineWidth(1).height(56).content("1234567890").codeType(CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
                .text(CText.builder().textX(320 + 8).textY(696 + 54).font(Font.TSS16).content("1234567890").build())
                .text(CText.builder().textX(12).textY(696 + 80 + 35).font(Font.TSS24).content("发").build())
                .text(CText.builder().textX(12).textY(696 + 80 + 84).font(Font.TSS24).content("件").build())
                .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28).font(Font.TSS24).content("名字" + " " + "13777777777").build())
                .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28 + 32).font(Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
                .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 50).font(Font.TSS24).content("客").build())
                .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 82).font(Font.TSS24).content("户").build())
                .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 106).font(Font.TSS24).content("联").build())
                .text(CText.builder().textX(12 + 8).textY(696 + 80 + 136 + 22 - 5).font(Font.TSS24).content("物品：" + "几个快递" + " " + "12kg").build())
                .box(CBox.builder().topLeftX(598 - 56 - 16 - 120).topLeftY(696 + 80 + 136 + 11).bottomRightX(598 - 56 - 16 - 16).bottomRightY(968 - 11).lineWidth(2).build())
                .text(CText.builder().textX(598 - 56 - 16 - 120 + 17).textY(696 + 80 + 136 + 11 + 6).font(Font.TSS24).content("已验视").build())
                .print(CPrint.builder().build())
                .feed();
        String result = safeWriteAndRead(_gcpcl);
        show(result);
    }

    private byte[] bitmap2Bytes(Bitmap bm) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
        return baos.toByteArray();
    }

    private String safeWriteAndRead(PSDK psdk) {
        try {
            WroteReporter reporter = psdk.write();
            if (!reporter.isOk()) {
                throw new IOException("写入数据失败", reporter.getException());
            }
            Thread.sleep(200);
            byte[] bytes = psdk.read(ReadOptions.builder().timeout(2000).build());
            return new String(bytes);
        } catch (Exception e) {
            return null;
        }
    }

    private byte[] safeWriteAndReadByte(PSDK psdk) {
        try {
            WroteReporter reporter = psdk.write();
            if (!reporter.isOk()) {
                throw new IOException("写入数据失败", reporter.getException());
            }
            Thread.sleep(200);
            byte[] bytes = psdk.read(ReadOptions.builder().timeout(2000).build());
            return bytes;
        } catch (Exception e) {
            PLog.error("Write data error: " + e.getMessage());
            return null;
        }
    }

    /**
     * 查询打印机状态
     *
     * @return OK：准备就绪  CoverOpened：纸舱盖打开 NoPaper：缺纸  Printing：正在打印中 BatteryLow：低电压
     */
    public String printerStatus(byte[] Rep) {
        if (Rep == null) {
            return "失败";
        }
        if (Rep[0] == 0x00) {
            return "OK";
        }
        if ((Rep[0] == 0x4f) && (Rep[1] == 0x4b)) {
            return "OK";
        }

        if ((Rep[0] & 16) != 0) {
            return "CoverOpened";
        }
        if ((Rep[0] & 1) != 0) {

            return "NoPaper";
        }

        if ((Rep[0] & 8) != 0) {

            return "Printing";
        }
        if ((Rep[0] & 4) != 0) {
            return "BatteryLow";
        }
        return "OK";
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
