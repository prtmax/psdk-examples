package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
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
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.*;
import com.printer.psdk.esc.args.ESetStandbyImage.ESetStandbyImageException;
import com.printer.psdk.esc.mark.Location;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import comprinter.psdk.frame.ota.types.esc.UpdatePrinterESC;
import comprinter.psdk.frame.ota.types.mark.UpgradeMarker;
import android.content.Intent;
import android.net.Uri;

import java.io.*;
import java.util.Arrays;

public class ESCActivity extends Activity {
  private static final String TAG = "ESCActivity";
  private Connection connection;
  private TextView tv_connect_status;
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
  private Button printer_info;
  private Button set_off_time;
  private Button get_off_time;
  private Button bottom_stock;
  private Button bottom_label;
  private Button paper_info, paper_uid, paper_used_length, paper_rest_length, setThickness, updatePrinterButton, printGray;
  private Button setStandbyModeBtn, setSystemLanguageBtn, getSystemLanguageBtn, setStandbyImageBtn, setCalendarModeBtn;
  private Button getDeviceInfoBtn, bindDeviceBtn;
  private EditText sampleEdit, thickness;
  private int sampleNumber;
  private final int ReceiveFLAG = 0x10;
  private final int StatusFLAG = 0x11;
  private final int PaperErrorFLAG = 0x12;
  private final int StartOrStopFLAG = 0x13;
  private final int BatteryStatusFLAG = 0x14;
  private ReadMark readMark = ReadMark.NONE;
  private boolean isSending = false;
  private ProgressDialog progressDialog;
  private DataListenerRunner dataListenerRunner;
  private static final int REQUEST_CODE_PICK_FIRMWARE = 1001;
  private static final int REQUEST_CODE_PICK_STANDBY_IMAGE = 1002;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_esc);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    sampleEdit = findViewById(R.id.sampleEdit);
    thickness = findViewById(R.id.thickness);
    sampleEdit.setText("1");
    setThickness = findViewById(R.id.setThickness);
    continueButton = findViewById(R.id.print_continue);
    labelButton = findViewById(R.id.printer_label);
    statusButton = findViewById(R.id.printer_status);
    batteryVolButton = findViewById(R.id.printer_BatteryVol);
    version_printerButton = findViewById(R.id.printer_version);
    snButton = findViewById(R.id.printer_SN);
    modelButton = findViewById(R.id.printer_model);
    macaddressButton = findViewById(R.id.mac_address);
    bt_nameButton = findViewById(R.id.bt_name);
    version_btButton = findViewById(R.id.bt_version);
    printer_info = findViewById(R.id.printer_info);
    set_off_time = findViewById(R.id.set_off_time);
    get_off_time = findViewById(R.id.get_off_time);
    bottom_stock = findViewById(R.id.bottom_stock);
    bottom_label = findViewById(R.id.bottom_label);
    paper_info = findViewById(R.id.paper_info);
    paper_uid = findViewById(R.id.paper_uid);
    paper_used_length = findViewById(R.id.paper_used_length);
    paper_rest_length = findViewById(R.id.paper_rest_length);
    updatePrinterButton = findViewById(R.id.updatePrinter);
    printGray = findViewById(R.id.printGray);
    // AI打印机专属按钮
    setStandbyModeBtn = findViewById(R.id.set_standby_mode);
    setSystemLanguageBtn = findViewById(R.id.set_system_language);
    getSystemLanguageBtn = findViewById(R.id.get_system_language);
    setStandbyImageBtn = findViewById(R.id.set_standby_image);
    setCalendarModeBtn = findViewById(R.id.set_calendar_mode);
    getDeviceInfoBtn = findViewById(R.id.get_device_info);
    bindDeviceBtn = findViewById(R.id.bind_device);
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
    continueButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        if (sampleEdit.getText().toString().trim().equals("")) {
          sampleNumber = 1;
        } else {
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
        }
        new Thread(new Runnable() {
          @Override
          public void run() {
            if (connection.isConnected()) {
              readMark = ReadMark.OPERATE_PRINT;
              //打印图片指令
              InputStream is = getResources().openRawResource(R.raw.dog);
              BitmapDrawable bmpDraw = new BitmapDrawable(is);
              Bitmap bitmap = bmpDraw.getBitmap();
              GenericESC _gesc = PrintUtil.getInstance().esc().enable()
                .wakeup()
                .location(ELocation.builder().location(Location.CENTER).build())
                .lineDot(8)//走空白纸
                .image(EImage.builder()
                  .image(new AndroidSourceImage(bitmap))
//                  .compress(true)//支持压缩的打印机可以走压缩
                  .build())
                .lineDot(10)
                .stopJob();
              safeWrite(_gesc);
              sampleNumber--;
            }
          }
        }).start();
      }
    });
    labelButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        if (sampleEdit.getText().toString().trim().equals("")) {
          sampleNumber = 1;
        } else {
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
        }
        new Thread(new Runnable() {
          @Override
          public void run() {
            if (connection.isConnected()) {
              readMark = ReadMark.OPERATE_PRINT;
              //打印图片指令
              InputStream is = getResources().openRawResource(R.raw.dog);
              BitmapDrawable bmpDraw = new BitmapDrawable(is);
              Bitmap bitmap = bmpDraw.getBitmap();
              GenericESC _gesc = PrintUtil.getInstance().esc().enable()
                .wakeup()
                .location(ELocation.builder().location(Location.CENTER).build())
                .image(EImage.builder()
                  .image(new AndroidSourceImage(bitmap))
//                  .compress(true)//支持压缩的打印机可以走压缩
                  .build())
                .lineDot(10)
                .position()//缝隙标签纸打印就是打印结束后多执行了这个指令
                .stopJob();
              safeWrite(_gesc);
              sampleNumber--;
            }
          }
        }).start();
      }
    });
    printGray.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        if (sampleEdit.getText().toString().trim().equals("")) {
          sampleNumber = 1;
        } else {
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
        }
        new Thread(new Runnable() {
          @Override
          public void run() {
            if (connection.isConnected()) {
              readMark = ReadMark.OPERATE_PRINT;
              //打印图片指令
              InputStream is = getResources().openRawResource(R.raw.reba);
              BitmapDrawable bmpDraw = new BitmapDrawable(is);
              Bitmap bitmap = bmpDraw.getBitmap();
              GenericESC _gesc = PrintUtil.getInstance().esc()
                .enable()
                .wakeup()
                .location(ELocation.builder().location(Location.CENTER).build())
                .lineDot(8)//走空白纸
                .enableGray()
                .imageGray(EImageGray.builder()
                  .image(new AndroidSourceImage(bitmap))
                  .build())
                .lineDot(10)
                .stopJob();
              safeWrite(_gesc);
              sampleNumber--;
            }
          }
        }).start();
      }
    });
    setThickness.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        if (thickness.getText() != null && thickness.length() != 0) {
          String nongduzhi = thickness.getText().toString().trim();
          int thickness = Integer.parseInt(nongduzhi);
          GenericESC _gesc = PrintUtil.getInstance().esc().thickness(thickness);
          safeWrite(_gesc);
        } else {
          Util.show(ESCActivity.this,"请先输入浓度值");
        }
      }
    });
    statusButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_STATUS;
        GenericESC _gesc = PrintUtil.getInstance().esc().state();
        safeWrite(_gesc);
      }
    });
    batteryVolButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BATVOL;
        GenericESC _gesc = PrintUtil.getInstance().esc().batteryVolume();
        safeWrite(_gesc);
      }
    });
    version_printerButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERVER;
        GenericESC _gesc = PrintUtil.getInstance().esc().printerVersion();
        safeWrite(_gesc);
      }
    });
    snButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERSN;
        GenericESC _gesc = PrintUtil.getInstance().esc().sn();
        safeWrite(_gesc);
      }
    });
    modelButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERMODEL;
        GenericESC _gesc = PrintUtil.getInstance().esc().model();
        safeWrite(_gesc);
      }
    });
    macaddressButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTMAC;
        GenericESC _gesc = PrintUtil.getInstance().esc().mac();
        safeWrite(_gesc);
      }
    });
    bt_nameButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTNAME;
        GenericESC _gesc = PrintUtil.getInstance().esc().name();
        safeWrite(_gesc);
      }
    });
    version_btButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTVER;
        GenericESC _gesc = PrintUtil.getInstance().esc().version();
        safeWrite(_gesc);
      }
    });
    printer_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_INFO;
        GenericESC _gesc = PrintUtil.getInstance().esc().info();
        safeWrite(_gesc);
      }
    });
    set_off_time.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.NONE;
        GenericESC _gesc = PrintUtil.getInstance().esc().setShutdownTime(60);
        safeWrite(_gesc);
      }
    });
    get_off_time.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_TIME;
        GenericESC _gesc = PrintUtil.getInstance().esc().getShutdownTime();
        safeWrite(_gesc);
      }
    });
    bottom_stock.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_PAPERTYPE;
        GenericESC _gesc = PrintUtil.getInstance().esc().paperType(EPaperType.builder().type(EPaperType.Type.CONTINUOUS_REEL_PAPER).build());
        //半寸口袋用这个
//        GenericESC _gesc = PrintUtil.getInstance().esc().paperTypeQ3(EPaperTypeQ3.builder().type(EPaperTypeQ3.TypeQ3.CONTINUOUS_REEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    bottom_label.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_PAPERTYPE;
        GenericESC _gesc = PrintUtil.getInstance().esc().paperType(EPaperType.builder().type(EPaperType.Type.FOLDED_BLACK_LABEL_PAPER).build());
        //半寸口袋用这个
//        GenericESC _gesc = PrintUtil.getInstance().esc().paperTypeQ3(EPaperTypeQ3.builder().type(EPaperTypeQ3.TypeQ3.TRANSPARENT_BLACK_LABEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    paper_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_NFC_PAPER;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcPaper();
        safeWrite(_gesc);
      }
    });
    paper_uid.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_NFC_UID;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcUID();
        safeWrite(_gesc);
      }
    });
    paper_used_length.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_NFC_USED_LENGTH;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcUsedLength();
        safeWrite(_gesc);
      }
    });
    paper_rest_length.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_NFC_REST_LENGTH;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcRestLength();
        safeWrite(_gesc);
      }
    });
    updatePrinterButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        // 打开文件选择器选择固件文件
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.setType("*/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, REQUEST_CODE_PICK_FIRMWARE);
      }
    });
    // ─────────── AI打印机专属功能 ───────────
    setStandbyModeBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        final String[] items = {"图片(1)", "日历(2)"};
        final int[] modes = {1, 2};
        final String[] labels = {"图片", "日历"};
        new AlertDialog.Builder(ESCActivity.this)
          .setTitle("选择待机样式")
          .setItems(items, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
              GenericESC _gesc = PrintUtil.getInstance().esc().setStandbyMode(modes[which]);
              safeWrite(_gesc);
              Util.show(ESCActivity.this, "已发送设置待机样式(" + labels[which] + ")");
            }
          })
          .show();
      }
    });
    setSystemLanguageBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        final String[] items = {"英文(1)", "中文(2)"};
        final int[] values = {1, 2};
        new AlertDialog.Builder(ESCActivity.this)
          .setTitle("选择系统语言")
          .setItems(items, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
              GenericESC _gesc = PrintUtil.getInstance().esc().setSystemLanguage(values[which]);
              safeWrite(_gesc);
              Util.show(ESCActivity.this, "已发送设置系统语言(" + items[which] + ")");
            }
          })
          .show();
      }
    });
    getSystemLanguageBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_GET_SYSTEM_LANGUAGE;
        GenericESC _gesc = PrintUtil.getInstance().esc().getSystemLanguage();
        safeWrite(_gesc);
      }
    });
    setStandbyImageBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        // 打开文件选择器选择待机图片
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.setType("image/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, REQUEST_CODE_PICK_STANDBY_IMAGE);
      }
    });
    setCalendarModeBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        final String[] items = {"图案1", "图案2", "图案3"};
        new AlertDialog.Builder(ESCActivity.this)
          .setTitle("选择日历图案类型")
          .setItems(items, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
              int calMode = which + 1;
              GenericESC _gesc = PrintUtil.getInstance().esc().setCalendarMode(calMode);
              safeWrite(_gesc);
              Util.show(ESCActivity.this, "已发送设置日历样式(图案" + calMode + ")");
            }
          })
          .show();
      }
    });
    // ─────────── 查询设备信息 / 绑定设备 ───────────
    getDeviceInfoBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        readMark = ReadMark.OPERATE_GET_DEVICE_INFO;
        GenericESC _gesc = PrintUtil.getInstance().esc().getDeviceInfo();
        safeWrite(_gesc);
      }
    });
    bindDeviceBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected()) {
          Util.show(ESCActivity.this, "请先连接设备");
          return;
        }
        // 值先写死，时间戳按字符串传
        EBindDevice bindArg = EBindDevice.builder()
          .onceCode("123456")
          .serverBaseUrl("https://api.example.com")
          .bindExpireTime("1719980000000")
          .build();
        GenericESC _gesc = PrintUtil.getInstance().esc()
          .bindDevice(bindArg);
        safeWrite(_gesc);
        Util.show(ESCActivity.this, "已发送绑定设备");
      }
    });
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (requestCode == REQUEST_CODE_PICK_FIRMWARE && resultCode == RESULT_OK) {
      if (data != null && data.getData() != null) {
        Uri uri = data.getData();
        progressDialog = new ProgressDialog(ESCActivity.this);
        progressDialog.setMessage("打印机正在进入升级模式，此过程可能需要几分钟，请耐心等待......");
        showprogress();
        byte[] firmwareData = Util.readUri(ESCActivity.this, uri);
        if (firmwareData != null) {
          //调用更新方法前一定要先调用该方法停止
          dataListenerRunner.stop();
          UpdatePrinterESC updatePrinter = new UpdatePrinterESC(connection, firmwareData, otaHandler);
          updatePrinter.setStartAddress(0x1020000);
          updatePrinter.startUpdate();
        } else {
          Util.show(ESCActivity.this, "读取固件文件失败");
          if (progressDialog != null) {
            progressDialog.dismiss();
            progressDialog = null;
          }
        }
      }
    } else if (requestCode == REQUEST_CODE_PICK_STANDBY_IMAGE && resultCode == RESULT_OK) {
      if (data != null && data.getData() != null) {
        final Uri uri = data.getData();
        // 停止监听，避免与 setStandbyImage 内部读写互抢
        dataListenerRunner.stop();
        new Thread(new Runnable() {
          @Override
          public void run() {
            try {
              InputStream is = getContentResolver().openInputStream(uri);
              Bitmap original = BitmapFactory.decodeStream(is);
              if (is != null) is.close();
              if (original == null) {
                runOnUiThread(new Runnable() {
                  @Override
                  public void run() { Util.show(ESCActivity.this, "无法解码图片"); }
                });
                return;
              }
              // 缩放到目标分辨率 792x528
              Bitmap scaled = Bitmap.createScaledBitmap(original, 792, 528, true);
              if (scaled != original) original.recycle();
              PrintUtil.getInstance().esc().setStandbyImage(new AndroidSourceImage(scaled));
              scaled.recycle();
              runOnUiThread(new Runnable() {
                @Override
                public void run() { Util.show(ESCActivity.this, "待机图片发送完成 (792x528)"); }
              });
            } catch (IOException e) {
              runOnUiThread(new Runnable() {
                @Override
                public void run() { Util.show(ESCActivity.this, "待机图片发送失败: " + e.getMessage()); }
              });
            } catch (ESetStandbyImageException e) {
              runOnUiThread(new Runnable() {
                @Override
                public void run() { Util.show(ESCActivity.this, "待机图片协议错误: " + e.getMessage()); }
              });
            } finally {
              dataListen(PrintUtil.getInstance().connectedDevice());
            }
          }
        }).start();
      }
    }
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
          if (received.length == 0) return;
          Log.e("action", Util.ByteArrToHex(received));
          // 检查是否是粘包数据
          if (received[0] == (byte) 0xFF || received[0] == (byte) 0xFB ||
            received[0] == (byte) 0xFE || received[0] == (byte) 0xFD) {
            int index = 0;
            while (index < received.length) {
              if (received.length - index >= 2) {
                // 提取前两个字节
                byte[] value = Arrays.copyOfRange(received, index, index + 2);
                index += 2; // 移除前两位
                // 根据数据类型处理
                switch (value[0]) {
                  case (byte) 0xFE:
                    Message messagePaperError = new Message();
                    messagePaperError.what = PaperErrorFLAG;
                    messagePaperError.obj = value;
                    myHandler.sendMessage(messagePaperError);
                    break;
                  case (byte) 0xFD:
                    Message messageStartOrStop = new Message();
                    messageStartOrStop.what = StartOrStopFLAG;
                    messageStartOrStop.obj = value;
                    myHandler.sendMessage(messageStartOrStop);
                    break;
                  case (byte) 0xFF:
                    Message messageStatus = new Message();
                    messageStatus.what = StatusFLAG;
                    messageStatus.obj = value;
                    myHandler.sendMessage(messageStatus);
                    break;
                  case (byte) 0xFB:
                    Message messageBatteryStatus = new Message();
                    messageBatteryStatus.what = BatteryStatusFLAG;
                    messageBatteryStatus.obj = value;
                    myHandler.sendMessage(messageBatteryStatus);
                    break;
                  default:
                    Message message = new Message();
                    message.what = ReceiveFLAG;
                    message.obj = value;
                    myHandler.sendMessage(message);
                    break;
                }
              } else {
                // 如果不足两个字节，直接处理剩余数据
                byte[] value = Arrays.copyOfRange(received, index, received.length);
                Message message = new Message();
                message.what = ReceiveFLAG;
                message.obj = value;
                myHandler.sendMessage(message);
                index = received.length; // 结束循环
              }
            }
          } else {
            // 如果不是粘包数据，直接处理
            Message message = new Message();
            message.what = ReceiveFLAG;
            message.obj = received;
            myHandler.sendMessage(message);
          }
        }
      })
      .start();
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
          Util.show(ESCActivity.this, "打印机升级失败");
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
          Util.show(ESCActivity.this, "打印机升级完成");
          break;
        }
      }
    }
  };

  //打印机上报状态数据
  private final Handler myHandler = new Handler(Looper.getMainLooper()) {
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case ReceiveFLAG:
          onReceive((byte[]) msg.obj);
          break;
        case StatusFLAG:
          onPrintStatus((byte[]) msg.obj);
          break;
        case PaperErrorFLAG:
          onPaperError((byte[]) msg.obj);
          break;
        case StartOrStopFLAG:
          onStartOrStopSend((byte[]) msg.obj);
          break;
        case BatteryStatusFLAG:
          onBatteryStatus((byte[]) msg.obj);
          break;
      }
    }
  };

  public void onPrintStatus(byte[] bytes) {
    Log.e("onPrintStatus", Util.ByteArrToHex(bytes));
    if (bytes[1] == 0x00) {
      Log.e(TAG, "正常");
      Util.show(ESCActivity.this,"正常");
    }
    if ((bytes[1] & 0x01) == 0x01) {
      Log.e(TAG, "过热");
      Util.show(ESCActivity.this,"过热");
    }
    if ((bytes[1] & 0x02) == 0x02) {
      Log.e(TAG, "开盖");
      Util.show(ESCActivity.this,"开盖");
      //开盖 缺纸 固件会取消打印
      onCancelPrint();
    }
    if ((bytes[1] & 0x04) == 0x04) {
      Log.e(TAG, "缺纸");
      Util.show(ESCActivity.this,"缺纸");
      //开盖 缺纸 固件会取消打印
      onCancelPrint();
    }
    if ((bytes[1] & 0x08) == 0x08) {
      Log.e(TAG, "低压");
      Util.show(ESCActivity.this,"低压");
    }
  }

  public void onPaperError(byte[] bytes) {
    switch (bytes[1]) {
      case 0x01:
        Log.e(TAG, "onPaperError: 折叠黑标纸");
        Util.show(ESCActivity.this,"onPaperError: 折叠黑标纸");
        break;
      case 0x02:
        Log.e(TAG, "onPaperError: 连续卷筒纸");
        Util.show(ESCActivity.this,"onPaperError: 连续卷筒纸");
        break;
      case 0x03:
        Log.e(TAG, "onPaperError: 不干胶缝隙纸");
        Util.show(ESCActivity.this,"onPaperError: 不干胶缝隙纸");
        break;
    }
    onCancelPrint();
  }

  public void onStartOrStopSend(byte[] bytes) {
    switch (bytes[1]) {
      case 0x01:
        Log.e(TAG, "onStartOrStopSend: 终止命令");
        Util.show(ESCActivity.this,"终止命令:FD 01");
        onCancelPrint();
        break;
      case 0x02:
        Log.e(TAG, "onStartOrStopSend: 继续开始命令");
        Util.show(ESCActivity.this,"继续开始命令:FD 02");
        break;
    }
  }

  public void onBatteryStatus(byte[] bytes) {
    switch (bytes[1]) {
      case 0x00:
        Util.show(ESCActivity.this,"电池状态:正常");
        break;
      case 0x01:
        Util.show(ESCActivity.this,"电池状态:低电");
        break;
      case 0x02:
        Util.show(ESCActivity.this,"电池状态:充电中");
        break;
      case 0x03:
        Util.show(ESCActivity.this,"电池状态:充电完成");
        break;
    }
  }

  public void onCancelPrint() {
    Log.e(TAG, "取消打印");
    if (readMark == ReadMark.OPERATE_PRINT) {
      readMark = ReadMark.NONE;
    }
  }

  public void onReceive(byte[] bytes) {
    Log.e("onReceive", Util.ByteArrToHex(bytes));
    switch (readMark) {
      case OPERATE_STATUS://主动查询状态的时候走这里
        readMark = ReadMark.NONE;
        Util.show(ESCActivity.this, Util.parseEscStatus(bytes));
        break;
      case OPERATE_BATVOL:
        readMark = ReadMark.NONE;
        if (bytes.length == 2) {
          String s = "电量：" + (int) bytes[1];
          Util.show(ESCActivity.this, s);
          Log.e(TAG, "电量: " + s);
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
        Util.show(ESCActivity.this, sn_printer);
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
        Util.show(ESCActivity.this, model_printer);
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
        Util.show(ESCActivity.this, version_printer);
        Log.e(TAG, "软件版本号: " + version_printer);

        break;
      case OPERATE_BTMAC:
        readMark = ReadMark.NONE;
        String mac_address;
        mac_address = Util.ByteArrToHex(bytes);
        Util.show(ESCActivity.this, mac_address);
        Log.e(TAG, "mac地址: " + mac_address);

        break;
      case OPERATE_TIME:
        readMark = ReadMark.NONE;
        String time = "关机时间: " + Long.parseLong(Util.ByteArrToHex(bytes), 16) + "分钟";
        Util.show(ESCActivity.this, time);
        Log.e(TAG, time);

        break;
      case OPERATE_BTVER:
        readMark = ReadMark.NONE;
        String version_bt = null;
        try {
          version_bt = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(ESCActivity.this, version_bt);
        Log.e(TAG, "蓝牙软件版本号: " + version_bt);

        break;
      case OPERATE_BTNAME:
        readMark = ReadMark.NONE;
        String name_bt = null;
        try {
          name_bt = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(ESCActivity.this, name_bt);
        Log.e(TAG, "蓝牙名称: " + name_bt);
        break;
      case OPERATE_INFO:
        readMark = ReadMark.NONE;
        String info = null;
        try {
          info = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(ESCActivity.this, info);
        Log.e(TAG, "设备信息: " + info);
        break;
      case OPERATE_PAPERTYPE:
        readMark = ReadMark.NONE;
        String paper_type = null;
        try {
          paper_type = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        Util.show(ESCActivity.this, paper_type);
        Log.e(TAG, "纸张类型设置: " + paper_type);
        break;
      case OPERATE_NFC_PAPER:
        readMark = ReadMark.NONE;
        String paper_info;
        String[] infos;
        try {
          paper_info = new String(bytes, "GB2312");
          infos = paper_info.split("\\|");
          if (infos.length >= 4) {
            //颜色:1 代表白色
            String i = "型号: " + infos[0] + "宽度: " + infos[1] + "高度: " + infos[2] + "颜色: " + infos[3];
            Util.show(ESCActivity.this, i);
            Log.e(TAG, "纸张信息: " + i);
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
        break;
      case OPERATE_NFC_UID:
        readMark = ReadMark.NONE;
        String paper_uid = Util.ByteArrToHex(bytes);
        Util.show(ESCActivity.this, paper_uid);
        Log.e(TAG, "纸张uid: " + paper_uid);
        break;
      case OPERATE_NFC_USED_LENGTH:
        readMark = ReadMark.NONE;
        String used_length = String.valueOf(Long.parseLong(Util.ByteArrToHex(bytes), 16));
        Util.show(ESCActivity.this, used_length);
        Log.e(TAG, "纸张已使用长度: " + used_length);
        break;
      case OPERATE_NFC_REST_LENGTH:
        readMark = ReadMark.NONE;
        String rest_length = String.valueOf(Long.parseLong(Util.ByteArrToHex(bytes), 16));
        Util.show(ESCActivity.this, rest_length);
        Log.e(TAG, "纸张剩余长度: " + rest_length);
        break;
      // ─────────── AI打印机专属 ───────────
      case OPERATE_GET_SYSTEM_LANGUAGE:
        readMark = ReadMark.NONE;
        if (bytes.length >= 2) {
          int lang = bytes[1] & 0xFF;
          String langStr = lang == 0 ? "中文" : "英文(" + lang + ")";
          Util.show(ESCActivity.this, "当前语言: " + langStr);
          Log.e(TAG, "当前语言: " + langStr);
        } else {
          Util.show(ESCActivity.this, "当前语言: " + Util.ByteArrToHex(bytes));
        }
        break;
      // ─────────── 查询设备信息 ───────────
      case OPERATE_GET_DEVICE_INFO:
        readMark = ReadMark.NONE;
        String deviceInfoRaw;
        try {
          deviceInfoRaw = new String(bytes, "UTF-8");
        } catch (UnsupportedEncodingException e) {
          deviceInfoRaw = Util.ByteArrToHex(bytes);
        }
        Util.show(ESCActivity.this, "设备信息:\n" + deviceInfoRaw);
        Log.e(TAG, "设备信息: " + deviceInfoRaw);
        break;
      case OPERATE_PRINT:
        readMark = ReadMark.NONE;
        if (Util.ByteArrToHex(bytes).contains("4F4B") || Util.ByteArrToHex(bytes).contains("AA")) {//打印成功 比如标签纸打印完成会返回4F4B 连续纸打印完成会返回AA
          if (connection.isConnected() && sampleNumber > 0) {
            new Thread(new Runnable() {
              @Override
              public void run() {
                readMark = ReadMark.OPERATE_PRINT;
                InputStream is = getResources().openRawResource(R.raw.dog);
                BitmapDrawable bmpDraw = new BitmapDrawable(is);
                Bitmap bitmap = bmpDraw.getBitmap();
                GenericESC _gesc = PrintUtil.getInstance().esc().enable()
                  .wakeup()
                  .lineDot(10)
                  .image(EImage.builder()
                    .image(new AndroidSourceImage(bitmap))
                    .build())
                  .lineDot(10)
                  .stopJob();
                safeWrite(_gesc);
                sampleNumber--;
              }
            }).start();
          }
        }
        break;
      default:
        readMark = ReadMark.NONE;
        if (Util.ByteArrToHex(bytes).equals("4F4B")) {//固件一些其他的返回在这里处理
          Util.show(ESCActivity.this, "成功");
          Log.e(TAG, "成功");
        }
        if (new String(bytes).equals("ER")) {
          Util.show(ESCActivity.this, "失败");
          Log.e(TAG, "失败");
        }
        break;
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

  private boolean isConnected() {
    try {
      return connection != null && connection.isConnected();
    } catch (Exception e) {
      return false;
    }
  }

  private void showprogress() {
    progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);// 设置水平进度条
    progressDialog.setCancelable(true);// 设置是否可以通过点击Back键取消
    progressDialog.setCanceledOnTouchOutside(false);// 设置在点击Dialog外是否取消Dialog进度条
    progressDialog.setIcon(R.mipmap.ic_launcher);// 设置提示的title的图标，默认是没有的
    progressDialog.setTitle("提示");
    progressDialog.setMax(100);
    progressDialog.show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
