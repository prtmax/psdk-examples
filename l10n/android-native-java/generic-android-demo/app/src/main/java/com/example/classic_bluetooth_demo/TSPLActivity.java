package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
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
import com.example.classic_bluetooth_demo.util.LanguageUtil;
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
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CodeType;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;
import com.printer.psdk.tspl.mark.ShowType;
import comprinter.psdk.frame.ota.types.mark.UpgradeMarker;
import comprinter.psdk.frame.ota.types.tspl.UpdatePrinterTSPL;

import java.io.UnsupportedEncodingException;

public class TSPLActivity extends Activity {
  private static final String TAG = "TSPLActivity";
  private Connection connection;
  private TextView tv_connect_status;
  private EditText etMsg, etDensity;
  private Button btnText, btnDensity, btnSN, btnBitmap, btnVer, btnStatus, btnBarCode, btnQRCode, btnModel,
      btnDoubleColor, btnPDF, btnOta;
  private ReadMark readMark = ReadMark.NONE;
  private final int ReceiveFLAG = 0x10;
  private ProgressDialog progressDialog;
  private DataListenerRunner dataListenerRunner;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    // 应用语言设置
    LanguageUtil.applyLanguage(this);
    setContentView(R.layout.activity_tspl);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    etMsg = findViewById(R.id.etMsg);
    etDensity = findViewById(R.id.etDensity);
    btnText = findViewById(R.id.btnText);
    btnDensity = findViewById(R.id.btnDensity);
    btnSN = findViewById(R.id.btnSN);
    btnBitmap = findViewById(R.id.btnBitmap);
    btnVer = findViewById(R.id.btnVer);
    btnStatus = findViewById(R.id.btnStatus);
    btnBarCode = findViewById(R.id.btnBarCode);
    btnQRCode = findViewById(R.id.btnQRCode);
    btnModel = findViewById(R.id.btnModel);
    btnDoubleColor = findViewById(R.id.btnDoubleColor);
    btnPDF = findViewById(R.id.btnPDF);
    btnOta = findViewById(R.id.btnOta);
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
            msg = getString(R.string.connecting);
            break;
          case Connection.STATE_PAIRING:
            msg = getString(R.string.pairing);
            break;
          case Connection.STATE_PAIRED:
            msg = getString(R.string.pair_success);
            break;
          case Connection.STATE_CONNECTED:
            msg = getString(R.string.connect_success);
            break;
          case Connection.STATE_DISCONNECTED:
            msg = getString(R.string.connect_disconnected);
            break;
          case Connection.STATE_RELEASED:
            msg = getString(R.string.connect_released);
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
    btnText.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(100).height(100).build())
            .direction(
                TDirection.builder()
                    .direction(TDirection.Direction.UP_OUT)
                    .mirror(TDirection.Mirror.NO_MIRROR)
                    .build())
            .gap(true)
            .cut(true)
            .cls()
            .text(TText.builder().content(etMsg.getText().toString()).x(50).y(50).build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }

    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(100).height(100).build())
            .direction(
                TDirection.builder()
                    .direction(TDirection.Direction.UP_OUT)
                    .mirror(TDirection.Mirror.NO_MIRROR)
                    .build())
            .cut(true)
            .cls()
            .image(
                TImage.builder()
                    .image(new AndroidSourceImage(bitmap))
                    .compress(true)
                    .build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnSN.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERSN;
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().sn();
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnVer.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERVER;
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().version();
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnStatus.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_STATUS;
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().status();
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnDensity.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().density(Integer.parseInt(etDensity.getText().toString()));
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnBarCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(100).height(100).build())
            .direction(
                TDirection.builder()
                    .direction(TDirection.Direction.UP_OUT)
                    .mirror(TDirection.Mirror.NO_MIRROR)
                    .build())
            .gap(true)
            .cut(true)
            .cls()
            .barcode(TBarCode.builder().content("1234556890").height(50).x(10).y(10).cellWidth(2).build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnQRCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(100).height(100).build())
            .direction(
                TDirection.builder()
                    .direction(TDirection.Direction.UP_OUT)
                    .mirror(TDirection.Mirror.NO_MIRROR)
                    .build())
            .gap(true)
            .cut(true)
            .cls()
            .qrcode(TQRCode.builder().x(10).y(10).content("1234556890").cellWidth(4).build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnDoubleColor.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inScaled = false;
        Bitmap redBitmap = BitmapFactory.decodeResource(getResources(), R.raw.red, options);
        Bitmap blackBitmap = BitmapFactory.decodeResource(getResources(), R.raw.black, options);
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(50).height(40).build())
            .direction(
                TDirection.builder()
                    .direction(TDirection.Direction.UP_OUT)
                    .mirror(TDirection.Mirror.NO_MIRROR)
                    .build())
            .label()// 标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
            // .bline()//黑标纸打印
            // .continuous()//连续纸打印
            .cls()
            .setRed(8)// 设置红色打印 下面元素都是红色
            .image(
                TImage.builder()
                    .image(new AndroidSourceImage(redBitmap))
                    .compress(true)
                    .build())
            .text(TText.builder().content("我是红色").x(50).y(200).build())
            .setBlack()// 设置黑色打印 下面元素都是黑色
            .image(
                TImage.builder()
                    .image(new AndroidSourceImage(blackBitmap))
                    .compress(true)
                    .build())
            .text(TText.builder().content("我是黑色").x(50).y(250).build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        // page宽高的单位是mm 下面坐标的xy单位是dot 1mm=8dot(分辨率203) 1mm=12dot(分辨率300)
        // 开发者根据自己使用的打印机来适配
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().page(TPage.builder().width(100).height(180).build())
            .label()// 标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
            // .bline()//黑标纸打印
            // .continuous()//连续纸打印
            // .offset(0)//进纸
            // .ribbon(false)//热敏模式
            // .shift(0)//垂直偏移
            // .reference(0, 0)//相对偏移
            .direction(
                TDirection.builder().direction(TDirection.Direction.UP_OUT).mirror(TDirection.Mirror.NO_MIRROR).build())
            .cut(true)
            .speed(6)
            .density(6)
            .cls()
            .bar(TBar.builder().x(300).y(10).width(4).height(90).build())
            .bar(TBar.builder().x(30).y(100).width(740).height(4).build())
            .bar(TBar.builder().x(30).y(880).width(740).height(4).build())
            .bar(TBar.builder().x(30).y(1300).width(740).height(4).build())
            // .text(TText.builder().x(400).y(25).rawFont("SIMHEI.TTF").xmulti(14).ymulti(14).content("上海浦东").build())//使用自定义矢量字体放大倍数计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
            .text(TText.builder().x(400).y(25).font(Font.TSS24).xmulti(2).ymulti(3).content("上海浦东").build())
            .text(TText.builder().x(30).y(120).font(Font.TSS24).xmulti(1).ymulti(1).content("发  件  人：张三 (电话 874236021)")
                .build())
            .text(TText.builder().x(30).y(150).font(Font.TSS24).xmulti(1).ymulti(1)
                .content("发件人地址：广州省 深圳市 福田区 思创路123号\"工业园\"1栋2楼").build())
            .text(TText.builder().x(30).y(200).font(Font.TSS24).xmulti(1).ymulti(1)
                .content("收  件  人：李四 (电话 13899658435)").build())
            .text(TText.builder().x(30).y(230).font(Font.TSS24).xmulti(1).ymulti(1)
                .content("收件人地址：上海市 浦东区 太仓路司务小区9栋1105室").build())
            .text(TText.builder().x(30).y(700).font(Font.TSS16).xmulti(1).ymulti(1)
                .content("各類郵件禁寄、限寄的範圍，除上述規定外，還應參閱「中華人民共和國海關對").build())
            .text(TText.builder().x(30).y(720).font(Font.TSS16).xmulti(1).ymulti(1)
                .content("进出口邮递物品监管办法”和国家法令有关禁止和限制邮寄物品的规定，以及邮").build())
            .text(TText.builder().x(30).y(740).font(Font.TSS16).xmulti(1).ymulti(1)
                .content("寄物品的规定，以及邮电部转发的各国（地区）邮 政禁止和限制。").build())
            .text(
                TText.builder().x(30).y(760).font(Font.TSS16).xmulti(1).ymulti(1).content("寄件人承诺不含有法律规定的违禁物品。").build())
            .barcode(TBarCode.builder().x(80).y(300).codeType(CodeType.CODE_128).height(90)
                .showType(ShowType.SHOW_CENTER).cellWidth(4).content("873456093465").build())
            .barcode(TBarCode.builder().x(550).y(910).codeType(CodeType.CODE_128).height(50)
                .showType(ShowType.SHOW_CENTER).cellWidth(2).content("873456093465").build())
            .box(TBox.builder().startX(40).startY(500).endX(340).endY(650).width(4).radius(20).build())
            .text(TText.builder().x(60).y(520).font(Font.TSS24).xmulti(1).ymulti(1).content("寄件人签字：").build())
            .text(
                TText.builder().x(130).y(625).font(Font.TSS24).xmulti(1).ymulti(1).content("2015-10-30 09:09").build())
            .text(TText.builder().x(50).y(1000).font(Font.TSS32).xmulti(2).ymulti(3).content("广东 ---- 上海浦东").build())
            .circle(TCircle.builder().x(670).y(1170).width(6).radius(100).build())
            .text(TText.builder().x(670).y(1170).font(Font.TSS24).xmulti(3).ymulti(3).content("碎").build())
            .qrcode(TQRCode.builder().x(620).y(620).correctLevel(CorrectLevel.H).cellWidth(4)
                .content("www.qrprt.com   www.qrprt.com   www.qrprt.com").build())
            .print(1);
        boolean result = safeWrite(_gtspl);
        Util.show(TSPLActivity.this, result ? getString(R.string.success) : getString(R.string.failed));
      }
    });
    btnPDF.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Intent intent = new Intent(TSPLActivity.this, PDFActivity.class);
        startActivity(intent);
      }
    });
    btnOta.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        progressDialog = new ProgressDialog(TSPLActivity.this);
        progressDialog.setMessage(getString(R.string.ota_entering));
        progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        progressDialog.setCancelable(true);
        progressDialog.setCanceledOnTouchOutside(false);
        progressDialog.setIcon(R.mipmap.ic_launcher);
        progressDialog.setTitle(getString(R.string.dialog_tip));
        progressDialog.show();
        // 调用更新方法前一定要先调用该方法停止
        dataListenerRunner.stop();
        UpdatePrinterTSPL updatePrinter = new UpdatePrinterTSPL(connection,
            Util.readResources(TSPLActivity.this, R.raw.mc240v219), otaHandler);
        updatePrinter.startUpdate();
      }
    });
  }

  // 打印机固件升级部分
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
          Toast.makeText(TSPLActivity.this, getString(R.string.upgrade_failed), Toast.LENGTH_SHORT).show();
          break;
        }
        case MSG_OTA_DATA_START_PRINTER: {
          if (progressDialog != null) {
            progressDialog.setMessage(getString(R.string.upgrade_start));
          }
          break;
        }
        case MSG_OTA_FINISHED_PRINTER: {
          if (progressDialog != null) {
            progressDialog.setProgress(100);
            progressDialog.dismiss();
            progressDialog = null;
          }
          Toast.makeText(TSPLActivity.this, getString(R.string.upgrade_finished), Toast.LENGTH_SHORT).show();
          break;
        }
      }
    }
  };

  private final Handler myHandler = new Handler(Looper.getMainLooper()) {
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case ReceiveFLAG:
          onReceive((byte[]) msg.obj);
          break;
      }
    }
  };

  public void onReceive(byte[] bytes) {
    switch (readMark) {
      case OPERATE_STATUS:
        readMark = ReadMark.NONE;
        if (bytes.length == 1) {
          if (bytes[0] == 0x00) {
            Log.e("状态：", getString(R.string.printer_normal));
            Util.show(TSPLActivity.this, getString(R.string.printer_normal));
          }
          if ((bytes[0] & 0x01) == 0x01) {
            Log.e("状态：", getString(R.string.printer_open));
            Util.show(TSPLActivity.this, getString(R.string.printer_open));
          }
          if ((bytes[0] & 0x02) == 0x02) {
            Log.e("状态：", getString(R.string.paper_error));
            Util.show(TSPLActivity.this, getString(R.string.paper_error));
          }
          if ((bytes[0] & 0x04) == 0x04) {
            Log.e("状态：", getString(R.string.paper_empty));
            Util.show(TSPLActivity.this, getString(R.string.paper_empty));
          }
          if ((bytes[0] & 0x08) == 0x08) {
            Log.e("状态：", getString(R.string.printer_low_battery));
            Util.show(TSPLActivity.this, getString(R.string.printer_low_battery));
          }
          if ((bytes[0] & 0x20) == 0x20) {
            Log.e("状态：", getString(R.string.printer_printing));
            Util.show(TSPLActivity.this, getString(R.string.printer_printing));
          }
          if ((bytes[0] & 0x10) == 0x10) {
            Log.e("状态：", getString(R.string.printer_paused));
            Util.show(TSPLActivity.this, getString(R.string.printer_paused));
          }
          if ((bytes[0] & 0x80) == 0x80) {
            Log.e("状态：", getString(R.string.printer_overheat));
            Util.show(TSPLActivity.this, getString(R.string.printer_overheat));
          }
        }
        break;
      case OPERATE_PRINTERSN:
        readMark = ReadMark.NONE;
        String sn_printer = null;
        try {
          sn_printer = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(TSPLActivity.this, sn_printer);
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
        Util.show(TSPLActivity.this, model_printer);
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
        Util.show(TSPLActivity.this, version_printer);
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

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (connection != null) {
      connection.disconnect();
    }
  }

}