package com.sf;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;


import java.io.ByteArrayOutputStream;
import java.io.IOException;

import android_serialport_api.GetSerialPort;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.serialport.android.SAConnectedDevice;
import com.printer.psdk.device.serialport.android.SADevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.types.lifecycle.Lifecycle;
import com.printer.psdk.frame.logger.PLog;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;


public class MainActivity extends Activity {

    private Button open, close, print, download, delete, barCode, QRCode, getinfor, printbmp;
    private TextView tv_port;
    private GenericTSPL tspl;
    private SADevice device;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        GetSerialPort getSerialPort = new GetSerialPort();
        String port = getSerialPort.QiRui_GetCOM();
        open = (Button) findViewById(R.id.power_on);
        tv_port = findViewById(R.id.tv_port);
        tv_port.setText("当前可用串口：" + port);
        open.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                boolean open = openPort(port, 115200);
                showMessage(open ? "成功" : "失败");
            }
        });
        close = (Button) findViewById(R.id.power_off);
        close.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                boolean close =closePort();
                showMessage(close ? "成功" : "失败");
            }
        });

        printbmp = (Button) findViewById(R.id.printbmp);
        printbmp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.raw.logo);
                GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
                        .direction(
                                TDirection.builder()
                                        .direction(TDirection.Direction.UP_OUT)
                                        .mirror(TDirection.Mirror.NO_MIRROR)
                                        .build()
                        )
                        .gap(true)
                        .cut(true)
                        .cls()
                        .image(
                                TImage.builder()
                                        .image(bitmap2Bytes(bitmap))
                                        .compress(true)
                                        .build()
                        )
                        .print(1);
                String result = safeWriteAndRead(_gtspl);
                showMessage(result);
            }
        });
        barCode = (Button) findViewById(R.id.barCode);
        barCode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
                        .direction(
                                TDirection.builder()
                                        .direction(TDirection.Direction.UP_OUT)
                                        .mirror(TDirection.Mirror.NO_MIRROR)
                                        .build()
                        )
                        .gap(true)
                        .cut(true)
                        .cls()
                        .barcode(TBarCode.builder().content("1234556890").height(50).x(10).y(10).cellwidth(2).build())
                        .print(1);
                String result = safeWriteAndRead(_gtspl);
                showMessage(result);
            }
        });
        QRCode = (Button) findViewById(R.id.QRCode);
        QRCode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
                        .direction(
                                TDirection.builder()
                                        .direction(TDirection.Direction.UP_OUT)
                                        .mirror(TDirection.Mirror.NO_MIRROR)
                                        .build()
                        )
                        .gap(true)
                        .cut(true)
                        .cls()
                        .qrcode(TQRCode.builder().x(10).y(10).content("1234556890").cellWidth(4).build())
                        .print(1);
                String result = safeWriteAndRead(_gtspl);
                showMessage(result);
            }
        });
        getinfor = (Button) findViewById(R.id.getInfor);
        getinfor.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                GenericTSPL _gtspl = tspl.version();
                String result = safeWriteAndRead(_gtspl);
                showMessage(result);

            }
        });
    }

    public boolean openPort(String portPath, int baudrate) {
        try {
            //获得串口端点名称
            device = new SADevice(portPath, baudrate);
            SAConnectedDevice connectedDevice = device.open();
            Lifecycle lifecycle = Lifecycle.builder()
                    .connectedDevice(connectedDevice)
                    .build();
            GenericTSPL tspl = TSPL.generic(lifecycle);
            String str = this.safeWriteAndRead(tspl.state());
            if (str != null && str.contains("READSTA")) {
                this.tspl = tspl;
                return true;
            }
        } catch (Exception e) {
            return false;
        }
        return false;
    }
    public boolean closePort() {
        try {
            device.close();
            return true;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
    private void showMessage(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
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
            PLog.error("Write data error: " + e.getMessage());
            return null;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private byte[] bitmap2Bytes(Bitmap bm) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
        return baos.toByteArray();
    }

}
