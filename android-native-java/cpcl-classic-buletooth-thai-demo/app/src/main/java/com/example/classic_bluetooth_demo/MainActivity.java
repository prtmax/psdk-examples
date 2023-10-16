package com.example.classic_bluetooth_demo;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import com.print.psdk.canvas.conversion.CommandToBitmap;
import com.print.psdk.canvas.mark.Line;
import com.print.psdk.canvas.types.FcBoxDrawException;
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
import com.printer.psdk.imagep.android.AndroidSourceImage;

import java.io.IOException;
import java.nio.charset.Charset;


public class MainActivity extends AppCompatActivity {
    private Connection connection;
    private TextView tv_connect_status;
    private EditText etMsg;
    private Button btnText, btnBitmap, btnStatus, btnBarCode, btnQRCode, btn_cmd, btn_bitmap;
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
        btn_cmd = findViewById(R.id.btn_cmd);
        btn_bitmap = findViewById(R.id.btn_bitmap);
        sampleEdit = (EditText) findViewById(R.id.sampleEdit);
        sampleEdit.setText("1");
        BluetoothDevice device = getIntent().getParcelableExtra("device");

        connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
            @Override
            public void onConnectSuccess(ConnectedDevice connectedDevice) {
                cpcl = CPCL.generic(connectedDevice);
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
                                .image(new AndroidSourceImage(bitmap))
                                .compress(true)
                                .build()
                        )
                        .print(CPrint.builder().build());
                Log.e("jcz", _gcpcl.command().string());
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
                        .bar(CBar.builder().x(10).y(10).content("1236549879").height(50).lineWidth(3).build())
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
        btn_cmd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (sampleEdit.getText().toString().trim().equals("")) {
                    sampleNumber = 1;
                } else {
                    sampleNumber = Integer.valueOf(sampleEdit.getText().toString().trim());
                }
                printNow();

            }
        });
        btn_bitmap.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (sampleEdit.getText().toString().trim().equals("")) {
                    sampleNumber = 1;
                } else {
                    sampleNumber = Integer.valueOf(sampleEdit.getText().toString().trim());
                }
                printNowByBitmap();

            }
        });
    }

    private void printNow() {
        int lineHeight = 30;
        GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1080).copies(sampleNumber).build())
                .text(CText.builder().textX(160).textY(10).font(Font.TSS24).content("ใบเสร็จรับเงิน/ใบกำกับภาษี").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(240).textY(10 + lineHeight).font(Font.TSS24).content("(สำเนา)").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 2).font(Font.TSS24).content("บริษัท แคชแวน แมนเนจเม้นท์ จำกัด สำนักงานใหญ่").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 3).font(Font.TSS24).content("1 อาคารอีสท์ วอเตอร์ ชั้นที่ 17").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 4).font(Font.TSS24).content("ซ.วิภาวดีรังสิต5 ถ.วิภาวดีรังสิต แขวงจอมพล").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 5).font(Font.TSS24).content("เขตจตุจักร กรุงเทพมหานคร 10900").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 6).font(Font.TSS24).content("เลขประจำตัวผู้เสียภาษี: 0105558037724").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 7).font(Font.TSS24).content("ใบกำกับภาษีเลขที่: 4910250004290395").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 8).font(Font.TSS24).content("22/02/2022").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 9).font(Font.TSS24).content("ได้รับเงินจาก เพ็ญ").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 10).font(Font.TSS24).content("5/9 ซ.เอกมัย30 ถ.สุขุมวิท71 แขวงคลองตันเหนือ").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 11).font(Font.TSS24).content("เขตวัฒนา กรุงเทพมหานคร 10110").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 12).font(Font.TSS24).content("เลขประจำตัวผู้เสียภาษี:").charset(Charset.defaultCharset()).build())
                .line(CLine.builder().startX(10).startY(20 + lineHeight * 13).endX(598).endY(20 + lineHeight * 13).isSolidLine(false).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 14).font(Font.TSS24).content("จำนวน       สินค้า         ราคาต่อหน่วย    จำนวนเงิน").charset(Charset.defaultCharset()).build())
                .line(CLine.builder().startX(10).startY(20 + lineHeight * 15).endX(598).endY(20 + lineHeight * 15).isSolidLine(false).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 16).font(Font.TSS24).content("2 โหล    ขาว40เล็ก-รง.กระทิงแดง 633.00   1,266.00").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 17).font(Font.TSS24).content("2 โหล    เสือดำ28 175          516.00   1,032.00").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 18).font(Font.TSS24).content("6 ขวด    หงส์ทอง350แบน(SBP)    132.00     792.00").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 19).font(Font.TSS24).content("1 โหล    ขาว40ใหญ่-รง.กระทิงแดง").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 20).font(Font.TSS24).content("                            1,218.00   1,218.00").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 22).font(Font.TSS24).content("      มูลค่าสินค้ารวมภาษีมูลค่าเพิ่ม        4,308.00 บาท").charset(Charset.defaultCharset()).build())
                .line(CLine.builder().startX(10).startY(20 + lineHeight * 23).endX(598).endY(20 + lineHeight * 23).isSolidLine(false).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 24).font(Font.TSS24).content("จำนวนเงินก่อนคิดภาษี                   4,026.17 บาท").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 25).font(Font.TSS24).content("จำนวนเงินหลังหักส่วนลด                 4,026.17 บาท").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 26).font(Font.TSS24).content("ภาษีมูลค่าเพิ่ม 7%                        281.83 บาท").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 27).font(Font.TSS24).content("ยอดเงินรวม                          4,308.00 บาท").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 29).font(Font.TSS24).content("ชำระโดย เงินสด").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 30).font(Font.TSS24).content("ผู้รับเงิน สุชาติ ศานติยุกต์").charset(Charset.defaultCharset()).build())
                .text(CText.builder().textX(10).textY(10 + lineHeight * 31).font(Font.TSS24).content("ลายมือชื่อ").charset(Charset.defaultCharset()).build())
                .line(CLine.builder().startX(10).startY(20 + lineHeight * 34).endX(598).endY(20 + lineHeight * 34).isSolidLine(false).build())
                .print(CPrint.builder().build());
        String cmd = _gcpcl.command().string(Charset.defaultCharset());
        Log.e("jcz", cmd);
        String result = safeWriteAndRead(_gcpcl);
        show(result);
    }

    private void printNowByBitmap() {
        int lineHeight = 30;
        CommandToBitmap command = new CommandToBitmap();
        command.setPage(608, 1080);
        try {
            command.drawText(160, 10, "ใบเสร็จรับเงิน/ใบกำกับภาษี", 2, false);
            command.drawText(240, 10 + lineHeight, "(สำเนา)", 2, false);
            command.drawText(10, 10 + lineHeight * 2, "บริษัท แคชแวน แมนเนจเม้นท์ จำกัด สำนักงานใหญ่", 2, false);
            command.drawText(10, 10 + lineHeight * 3, "1 อาคารอีสท์ วอเตอร์ ชั้นที่ 17", 2, false);
            command.drawText(10, 10 + lineHeight * 4, "ซ.วิภาวดีรังสิต5 ถ.วิภาวดีรังสิต แขวงจอมพล", 2, false);
            command.drawText(10, 10 + lineHeight * 5, "เขตจตุจักร กรุงเทพมหานคร 10900", 2, false);
            command.drawText(10, 10 + lineHeight * 6, "เลขประจำตัวผู้เสียภาษี: 0105558037724", 2, false);
            command.drawText(10, 10 + lineHeight * 7, "ใบกำกับภาษีเลขที่: 4910250004290395", 2, false);
            command.drawText(10, 10 + lineHeight * 8, "22/02/2022", 2, false);
            command.drawText(10, 10 + lineHeight * 9, "ได้รับเงินจาก เพ็ญ", 2, false);
            command.drawText(10, 10 + lineHeight * 10, "5/9 ซ.เอกมัย30 ถ.สุขุมวิท71 แขวงคลองตันเหนือ", 2, false);
            command.drawText(10, 10 + lineHeight * 11, "เขตวัฒนา กรุงเทพมหานคร 10110", 2, false);
            command.drawText(10, 10 + lineHeight * 12, "เลขประจำตัวผู้เสียภาษี:", 2, false);
            command.drawLine(10, 20 + lineHeight * 13, 598, 20 + lineHeight * 13, 2, Line.DOTTED_LINE);
            command.drawText(10, 10 + lineHeight * 14, "จำนวน          สินค้า            ราคาต่อหน่วย       จำนวนเงิน", 2, false);
            command.drawLine(10, 20 + lineHeight * 15, 598, 20 + lineHeight * 15, 2, Line.DOTTED_LINE);
            command.drawText(10, 10 + lineHeight * 16, "2 โหล    ขาว40เล็ก-รง.กระทิงแดง  633.00     1,266.00", 2, false);
            command.drawText(10, 10 + lineHeight * 17, "2 โหล    เสือดำ28 175                   516.00     1,032.00", 2, false);
            command.drawText(10, 10 + lineHeight * 18, "6 ขวด    หงส์ทอง350แบน(SBP)      132.00       792.00", 2, false);
            command.drawText(10, 10 + lineHeight * 19, "1 โหล    ขาว40ใหญ่-รง.กระทิงแดง", 2, false);
            command.drawText(10, 10 + lineHeight * 20, "                                                  1,218.00     1,218.00", 2, false);
            command.drawText(10, 10 + lineHeight * 22, "      มูลค่าสินค้ารวมภาษีมูลค่าเพิ่ม            4,308.00 บาท", 2, false);
            command.drawLine(10, 20 + lineHeight * 23, 598, 20 + lineHeight * 23, 2, Line.DOTTED_LINE);
            command.drawText(10, 10 + lineHeight * 24, "จำนวนเงินก่อนคิดภาษี                              4,026.17 บาท", 2, false);
            command.drawText(10, 10 + lineHeight * 25, "จำนวนเงินหลังหักส่วนลด                          4,026.17 บาท", 2, false);
            command.drawText(10, 10 + lineHeight * 26, "ภาษีมูลค่าเพิ่ม 7%                                      281.83 บาท", 2, false);
            command.drawText(10, 10 + lineHeight * 27, "ยอดเงินรวม                                           4,308.00 บาท", 2, false);
            command.drawText(10, 10 + lineHeight * 29, "ชำระโดย เงินสด", 2, false);
            command.drawText(10, 10 + lineHeight * 30, "รับเงิน สุชาติ ศานติยุกต์", 2, false);
            command.drawText(10, 10 + lineHeight * 31, "ลายมือชื่อ", 2, false);
            command.drawLine(10, 20 + lineHeight * 34, 598, 20 + lineHeight * 34, 2, Line.DOTTED_LINE);

        } catch (FcBoxDrawException e) {
            e.printStackTrace();
        }

        GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1080).copies(sampleNumber).build())
                .image(CImage.builder()
                        .startX(0)
                        .startY(0)
                        .compress(true)
                        .image(command.render().getBitmap()).build())
                .print(CPrint.builder().build());
        String cmd = _gcpcl.command().string(Charset.defaultCharset());
        Log.e("jcz", cmd);
        String result = safeWriteAndRead(_gcpcl);
        show(result);
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
