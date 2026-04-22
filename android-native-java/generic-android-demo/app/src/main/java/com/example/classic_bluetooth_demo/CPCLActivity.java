package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.*;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.example.classic_bluetooth_demo.util.ReadMark;
import com.example.classic_bluetooth_demo.util.Util;
import com.printer.psdk.compatible.cpcl.CTextCanvas;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.CodeRotation;
import com.printer.psdk.cpcl.mark.CodeType;
import com.printer.psdk.cpcl.mark.Font;
import com.printer.psdk.cpcl.mark.Rotation;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import comprinter.psdk.frame.ota.types.cpcl.UpdatePrinterCPCL;
import comprinter.psdk.frame.ota.types.mark.UpgradeMarker;

import java.io.UnsupportedEncodingException;


public class CPCLActivity extends Activity {
  private static final String TAG = "CPCLActivity";
  private Connection connection;
  private TextView tv_connect_status;
  private EditText etMsg;
  private Button btnText, btnBitmap, btnStatus, btnBarCode, btnQRCode, btnModel, btnWfModel, btnPDF, btnOta;
  private EditText sampleEdit;
  private int sampleNumber;
  private boolean isSending = false;
  private ReadMark readMark = ReadMark.NONE;
  private final int ReceiveFLAG = 0x10;
  private final int StatusFLAG = 0x11;
  private ProgressDialog progressDialog;
  private DataListenerRunner dataListenerRunner;
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
    btnWfModel = findViewById(R.id.btnWfModel);
    btnPDF = findViewById(R.id.btnPDF);
    btnOta = findViewById(R.id.btnOta);
    sampleEdit = findViewById(R.id.sampleEdit);
    sampleEdit.setText("1");
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        PrintUtil.getInstance().init(connectedDevice);
        dataListen(connectedDevice);
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
    etMsg = findViewById(R.id.etMsg);
    btnText.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(100).height(100).build())
          .text(CText.builder().font(Font.TSS32).content(etMsg.getText().toString()).build())
          .print(CPrint.builder().build());
        boolean result = safeWrite(_gcpcl);
        Util.show(CPCLActivity.this, result ? "成功" : "失败");
      }

    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.raw.logo);
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(608).height(600).build())
          .image(CImage.builder()
            .image(new AndroidSourceImage(bitmap))
//            .compress(true)//支持压缩的打印机可以走压缩
            .build()
          )
          .print(CPrint.builder().build());
        boolean result = safeWrite(_gcpcl);
        Util.show(CPCLActivity.this, result ? "成功" : "失败");
      }
    });

    btnStatus.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        readMark = ReadMark.OPERATE_STATUS;
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().status();
        boolean result = safeWrite(_gcpcl);
        Util.show(CPCLActivity.this, result ? "成功" : "失败");
      }
    });

    btnBarCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(500).height(100).build())
          .bar(CBar.builder().x(10).y(10).content("1236549879").height(50).lineWidth(2).build())
          .print(CPrint.builder().build());
        boolean result = safeWrite(_gcpcl);
        Util.show(CPCLActivity.this, result ? "成功" : "失败");
      }
    });
    btnQRCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(100).height(100).build())
          .qrcode(CQRCode.builder().x(10).y(10).content("1236549879").width(2).build())
          .print(CPrint.builder().build());
        boolean result = safeWrite(_gcpcl);
        Util.show(CPCLActivity.this, result ? "成功" : "失败");
      }
    });
    btnModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
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
    btnWfModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Toast.makeText(CPCLActivity.this, "请先连接设备", Toast.LENGTH_SHORT).show();
          return;
        }
        if (sampleEdit.getText().toString().trim().equals("")) {
          sampleNumber = 1;
        } else {
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
        }
        if (!isSending) {
          new Thread(new Runnable() {
            @Override
            public void run() {
              try {
                printWf();
              } catch (Exception e) {
                e.printStackTrace();
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
    btnOta.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        progressDialog = new ProgressDialog(CPCLActivity.this);
        progressDialog.setMessage("打印机正在进入升级模式，此过程可能需要几分钟，请耐心等待......");
        progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        progressDialog.setCancelable(true);
        progressDialog.setCanceledOnTouchOutside(false);
        progressDialog.setIcon(R.mipmap.ic_launcher);
        progressDialog.setTitle("提示");
        progressDialog.show();
        //调用更新方法前一定要先调用该方法停止
        dataListenerRunner.stop();
        UpdatePrinterCPCL updatePrinter = new UpdatePrinterCPCL(connection, Util.readResources(CPCLActivity.this, R.raw.mc240v219), otaHandler);
        updatePrinter.startUpdate();
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
      .text(CTextCanvas.builder().textX(52 + 20).textY(88 + 128 + 80 + 24 + 32).font(Font.TSS24_MAX1).bold(true).content("南京市浦口区威尼斯水城七街区七街区").alpha(255).build())//文字用canvas画 支持各国语言
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
    boolean result = safeWrite(_gcpcl);
    Util.show(CPCLActivity.this, result ? "成功" : "失败");
  }

  private void printWf() {
    int dpi = 8; //1mm=8dot(分辨率203) 1mm=12dot(分辨率300)
    GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl()
            .page(CPage.builder().width(200 * dpi).height(200 * dpi).copies(sampleNumber).build())
            .mag(CMag.builder().font(Font.TSS24_MAX1).build())//字体放大1倍
            .text(CText.builder().textX(45 * dpi).textY(33 * dpi).font(Font.TSS24_MAX1).bold(true).content("废物名称内容").build())
            .text(CText.builder().textX(45 * dpi).textY(44 * dpi).font(Font.TSS24_MAX1).bold(true).content("废物类别内容").build())
            .text(CText.builder().textX(45 * dpi).textY(55 * dpi).font(Font.TSS24_MAX1).bold(true).content("废物代码内容").build())
            .text(CText.builder().textX(105 * dpi).textY(55 * dpi).font(Font.TSS24_MAX1).bold(true).content("废物形态内容").build())
            .text(CText.builder().textX(45 * dpi).textY(68 * dpi).font(Font.TSS24_MAX1).bold(true).content("主要成分内容").build())
            .text(CText.builder().textX(45 * dpi).textY(91 * dpi).font(Font.TSS24_MAX1).bold(true).content("有害成分内容").build())
            .text(CText.builder().textX(45 * dpi).textY(114 * dpi).font(Font.TSS24_MAX1).bold(true).content("注意事项内容").build())
            .text(CText.builder().textX(48 * dpi).textY(138 * dpi).font(Font.TSS24_MAX1).bold(true).content("数字识别码内容").build())
            .text(CText.builder().textX(55 * dpi).textY(148 * dpi).font(Font.TSS24_MAX1).bold(true).content("产生/收集单位内容").build())
            .text(CText.builder().textX(66 * dpi).textY(160 * dpi).font(Font.TSS24_MAX1).bold(true).content("联系人和联系方式内容").build())
            .text(CText.builder().textX(40 * dpi).textY(172 * dpi).font(Font.TSS24_MAX1).bold(true).content("产生日期内容").build())
            .text(CText.builder().textX(102 * dpi).textY(172 * dpi).font(Font.TSS24_MAX1).bold(true).content("废物重量内容").build())
            .mag(CMag.builder().font(Font.TSS24).build())//字体还原
            .text(CText.builder().textX(27 * dpi).textY(184 * dpi).font(Font.TSS24).bold(false).content("备注内容").build())
            .qrcode(CQRCode.builder().x(148 * dpi).y(148 * dpi).width(10).content("https://wfqr.qrprt.com/id=00000000000000000").build())
            .form()//标签定位指令
            .print(CPrint.builder().build());
    boolean result = safeWrite(_gcpcl);
    Util.show(CPCLActivity.this, result ? "成功" : "失败");
  }

  //打印机固件升级部分
  private final Handler otaHandler = new Handler(Looper.getMainLooper()) {
    @Override
    public void handleMessage(Message msg) {
      UpgradeMarker transactionTypeEnum = UpgradeMarker.getByCode(msg.what);
      switch (transactionTypeEnum) {
        case MSG_UPDATE_PROGRESS_BAR_PRINTER: {
          int progress = (int) msg.obj;
          if (progressDialog != null) {
            progressDialog.setProgress(progress);
          }
          break;
        }
        case MSG_OTA_DATA_COMMAND_SEND_FAILED_PRINTER: {
          if (progressDialog != null) {
            progressDialog.dismiss();
          }
          Toast.makeText(CPCLActivity.this, "打印机升级失败", Toast.LENGTH_SHORT).show();
          break;
        }
        case MSG_OTA_DATA_START_PRINTER: {
          if (progressDialog != null) {
            progressDialog.setMessage("开始升级打印机");
          }
          break;
        }
        case MSG_OTA_FINISHED_PRINTER: {
          if (progressDialog != null) {
            progressDialog.setProgress(100);
            progressDialog.dismiss();
            progressDialog = null;
          }
          Toast.makeText(CPCLActivity.this, "打印机升级完成", Toast.LENGTH_SHORT).show();
          break;
        }
      }
    }
  };

  private final Handler myHandler = new Handler(Looper.getMainLooper()) {
    @Override
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case ReceiveFLAG:
          onReceive((byte[]) msg.obj);
          break;
        case StatusFLAG:
          byte[] bytes = (byte[]) msg.obj;
          String hexStr = Util.ByteArrToHex(bytes);
          switch (hexStr) {
            case "AAFF01FF55":
              Util.show(CPCLActivity.this, "正常");
              break;
            case "AAFF010155":
              Util.show(CPCLActivity.this, "纸舱盖打开");
              break;
            case "AAFF010255":
              Util.show(CPCLActivity.this, "缺纸");
              break;
            case "AAFF010355":
              Util.show(CPCLActivity.this, "卡纸");
              break;
            case "AAFF010455":
              Util.show(CPCLActivity.this, "低电压");
              break;
            case "AAFF010555":
              Util.show(CPCLActivity.this, "打印头过热");
              break;
          }
          break;
      }
    }
  };

  public void onReceive(byte[] bytes) {
    switch (readMark) {
      case OPERATE_STATUS:
        readMark = ReadMark.NONE;
        String status = printerStatus(bytes);
        Util.show(CPCLActivity.this, status);
        break;
      case OPERATE_PRINTERSN:
        readMark = ReadMark.NONE;
        String sn_printer = null;
        try {
          sn_printer = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(CPCLActivity.this, sn_printer);
        Log.e(TAG, "SN号: " + sn_printer);
        break;
      case OPERATE_PRINTERMODEL:
        readMark = ReadMark.NONE;
        String model_printer = null;
        try {
          model_printer = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Log.e(TAG, model_printer);
        Util.show(CPCLActivity.this, model_printer);
        Log.e(TAG, "打印机型号: " + model_printer);
        break;
      case OPERATE_PRINTERVER:
        readMark = ReadMark.NONE;
        String version_printer = null;
        try {
          version_printer = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(CPCLActivity.this, version_printer);
        Log.e(TAG, "软件版本号: " + version_printer);
        break;
      default:
        break;
    }
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    dataListenerRunner = DataListener.with(connectedDevice).listen(new ListenAction() {
      @Override
      public void action(byte[] bytes) {
        if (bytes.length == 5) {
          if (bytes[0] == (byte) 0xAA && bytes[1] == (byte) 0xFF) {
            Message message = new Message();
            message.what = StatusFLAG;
            message.obj = bytes;
            myHandler.sendMessage(message);
            return;
          }
        }
        Message message = new Message();
        message.what = ReceiveFLAG;
        message.obj = bytes;
        myHandler.sendMessage(message);
      }
    }).start();
  }

  private boolean safeWrite(PSDK psdk) {
    try {
      WroteReporter reporter = psdk.write();
      return reporter.isOk();
    } catch (Exception e) {
      e.printStackTrace();
      return false;
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

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

  private boolean isConnected() {
    try {
      return connection != null && connection.isConnected();
    } catch (Exception e) {
      return false;
    }
  }
}
