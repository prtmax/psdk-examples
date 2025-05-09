package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.CodeRotation;
import com.printer.psdk.cpcl.mark.CodeType;
import com.printer.psdk.cpcl.mark.CorrectLevel;
import com.printer.psdk.cpcl.mark.Font;
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


public class CPCLActivity extends Activity {
  private Connection connection;
  private TextView tv_connect_status;
  private EditText etMsg;
  private Button btnText, btnBitmap, btnStatus, btnBarCode, btnQRCode, btnModel, btnPDF;
  private EditText sampleEdit;
  private int sampleNumber;
  private boolean isSending = false;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_cpcl);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    etMsg = findViewById(R.id.etMsg);
    btnText = findViewById(R.id.btnText);
    btnBitmap = findViewById(R.id.btnBitmap);
    btnStatus = findViewById(R.id.btnStatus);
    btnBarCode = findViewById(R.id.btnBarCode);
    btnQRCode = findViewById(R.id.btnQRCode);
    btnModel = findViewById(R.id.btnModel);
    btnPDF = findViewById(R.id.btnPDF);
    sampleEdit = (EditText) findViewById(R.id.sampleEdit);
    sampleEdit.setText("1");
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        PrintUtil.getInstance().init(connectedDevice);
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
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(100).height(100).build())
          .text(CText.builder().font(Font.TSS32).content(etMsg.getText().toString()).build())
          .print(CPrint.builder().build());
        String result = safeWriteAndRead(_gcpcl);
        show(result);
      }

    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.raw.logo);
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(608).height(600).build())
          .image(CImage.builder()
            .image(new AndroidSourceImage(bitmap))
//            .compress(true)//支持压缩的打印机可以走压缩
            .build()
          )
          .print(CPrint.builder().build());
        String result = safeWriteAndRead(_gcpcl);
        show(result);
      }
    });


    btnStatus.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().status();
        byte[] result = safeWriteAndReadByte(_gcpcl);
        show(printerStatus(result));
      }
    });

    btnBarCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(500).height(100).build())
          .bar(CBar.builder().x(10).y(10).content("1236549879").height(50).lineWidth(2).build())
          .print(CPrint.builder().build());
        String result = safeWriteAndRead(_gcpcl);
        show(result);
      }
    });
    btnQRCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(100).height(100).build())
          .qrcode(CQRCode.builder().x(10).y(10).content("1236549879").width(2).build())
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
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
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
                  e.printStackTrace();
                }
                try {
                  Thread.sleep(500);
                } catch (InterruptedException e) {
                  e.printStackTrace();
                }
                if (i == (sampleNumber - 1)) {
                  isSending = false;
                }

              }

            }
          }).start();
        }

      }
    });
    btnPDF.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Intent intent = new Intent(CPCLActivity.this, PDFActivity.class);
        startActivity(intent);
      }
    });
  }

  /**
   * 说明：1.以下单位都是dot 1mm=8dot(分辨率203) 1mm=12dot(分辨率300) 开发者根据自己使用的打印机来适配
   * 2.字体问题，当使用到例如Font.TSS24_MAX1 带MAX这类的字体时需要.font(Font.TSS24_MAX1).mag(true)才会生效 .mag(true)是允许倍数放大
   * 3.一个完整的指令.page()是指令头 .print()是指令尾必不可少的
   * 4.需要整个页面旋转的时候.print(CPrint.builder().mode(CPrint.Mode.MIRROR).build());
   */
  private void printNow() {
    GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(608).height(1040).copies(sampleNumber).build())
      .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(664).lineWidth(2).build())
      .line(CLine.builder().startX(0).startY(88).endX(598).endY(88).lineWidth(2).build())
      .line(CLine.builder().startX(0).startY(88 + 128).endX(598).endY(88 + 128).lineWidth(2).build())
      .line(CLine.builder().startX(0).startY(88 + 128 + 80).endX(598).endY(88 + 128 + 80).lineWidth(2).build())
      .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144).lineWidth(2).build())
      .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144 + 128).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
      .line(CLine.builder().startX(52).startY(88 + 128 + 80).endX(52).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
      .line(CLine.builder().startX(598 - 56 - 16).startY(88 + 128 + 80).endX(598 - 56 - 16).endY(664).lineWidth(2).build())
      .bar(CBar.builder().x(120).y(88 + 12).lineWidth(1).height(80).content("1234567890").codeType(CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
      .text(CText.builder().textX(120 + 12).textY(88 + 20 + 76).font(Font.TSS24_MAX1).content("1234567890").build())
      .text(CText.builder().textX(12).textY(88 + 128 + 80 + 32).font(Font.TSS24).content("收").build())
      .text(CText.builder().textX(12).textY(88 + 128 + 80 + 96).font(Font.TSS24).content("件").build())
      .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 32).font(Font.TSS24).content("发").build())
      .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 80).font(Font.TSS24).content("件").build())
      .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 128 + 16).font(Font.TSS24).content("签收人/签收时间").build())
      .text(CText.builder().textX(430).textY(88 + 128 + 80 + 144 + 128 + 36).font(Font.TSS24).content("月").build())
      .text(CText.builder().textX(490).textY(88 + 128 + 80 + 144 + 128 + 36).font(Font.TSS24).content("日").build())
      .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24).font(Font.TSS24).content("收姓名" + " " + "13777777777").build())
      .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24 + 32).font(Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
      .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24).font(Font.TSS24).content("名字" + " " + "13777777777").build())
      .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24 + 32).font(Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
      .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 104).font(Font.TSS24).content("派").build())
      .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 160).font(Font.TSS24).content("件").build())
      .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 208).font(Font.TSS24).content("联").build())
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
      .mag(CMag.builder().font(Font.TSS24_MAX1).build())//放大倍数
      .text(CText.builder().textX(598 - 56 - 16 - 120 + 17).textY(696 + 80 + 136 + 11 + 6).font(Font.TSS24_MAX1).bold(true).content("已验视").build())
      .mag(CMag.builder().font(Font.TSS24).build())//还原
      .form()//标签定位指令
      .print(CPrint.builder().mode(CPrint.Mode.MIRROR).build());
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
      return psdk.read(ReadOptions.builder().timeout(2000).build());
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
    if (message == null) {
      return;
    }
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
