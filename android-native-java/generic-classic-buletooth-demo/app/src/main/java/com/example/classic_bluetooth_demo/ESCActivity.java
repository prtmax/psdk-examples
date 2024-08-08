package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.example.classic_bluetooth_demo.util.ReadMark;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.esc.args.ELocation;
import com.printer.psdk.esc.args.EPaperType;
import com.printer.psdk.esc.mark.Location;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import comprinter.psdk.frame.ota.types.esc.UpdatePrinterESC;
import comprinter.psdk.frame.ota.types.mark.UpgradeMarker;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;

public class ESCActivity extends Activity {
  private static final String TAG = "MainActivity";
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
  private Button paper_info, paper_uid, paper_used_length, paper_rest_length, setThickness, updatePrinterButton;
  private EditText sampleEdit, thickness;
  private int sampleNumber;
  private final int ReceiveFLAG = 0x10;
  private final int StatusFLAG = 0x11;
  private final int PaperErrorFLAG = 0x12;
  private final int StartOrStopFLAG = 0x13;
  private ReadMark readMark = ReadMark.NONE;
  private boolean isSending = false;
  private ProgressDialog progressDialog;
  private DataListenerRunner dataListenerRunner;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_esc);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    sampleEdit = (EditText) findViewById(R.id.sampleEdit);
    thickness = (EditText) findViewById(R.id.thickness);
    sampleEdit.setText("1");
    setThickness = findViewById(R.id.setThickness);
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
    printer_info = (Button) findViewById(R.id.printer_info);
    set_off_time = (Button) findViewById(R.id.set_off_time);
    get_off_time = (Button) findViewById(R.id.get_off_time);
    bottom_stock = (Button) findViewById(R.id.bottom_stock);
    bottom_label = (Button) findViewById(R.id.bottom_label);
    paper_info = (Button) findViewById(R.id.paper_info);
    paper_uid = (Button) findViewById(R.id.paper_uid);
    paper_used_length = (Button) findViewById(R.id.paper_used_length);
    paper_rest_length = (Button) findViewById(R.id.paper_rest_length);
    updatePrinterButton = (Button) findViewById(R.id.updatePrinter);
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
                .lineDot(1)
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
    setThickness.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (thickness.getText() != null && thickness.length() != 0) {
          String nongduzhi = thickness.getText().toString().trim();
          int thickness = Integer.valueOf(nongduzhi);
          GenericESC _gesc = PrintUtil.getInstance().esc().thickness(thickness);
          safeWrite(_gesc);
        } else {
          show("请先输入浓度值");
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
        readMark = ReadMark.NONE;
        GenericESC _gesc = PrintUtil.getInstance().esc().setShutdownTime(60);
        safeWrite(_gesc);
      }
    });
    get_off_time.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_TIME;
        GenericESC _gesc = PrintUtil.getInstance().esc().getShutdownTime();
        safeWrite(_gesc);
      }
    });
    bottom_stock.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PAPERTYPE;
        GenericESC _gesc = PrintUtil.getInstance().esc().paperType(EPaperType.builder().type(EPaperType.Type.CONTINUOUS_REEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    bottom_label.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PAPERTYPE;
        GenericESC _gesc = PrintUtil.getInstance().esc().paperType(EPaperType.builder().type(EPaperType.Type.FOLDED_BLACK_LABEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    paper_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_NFC_PAPER;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcPaper();
        safeWrite(_gesc);
      }
    });
    paper_uid.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_NFC_UID;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcUID();
        safeWrite(_gesc);
      }
    });
    paper_used_length.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_NFC_USED_LENGTH;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcUsedLength();
        safeWrite(_gesc);
      }
    });
    paper_rest_length.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_NFC_REST_LENGTH;
        GenericESC _gesc = PrintUtil.getInstance().esc().getNfcRestLength();
        safeWrite(_gesc);
      }
    });
    updatePrinterButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        progressDialog = new ProgressDialog(ESCActivity.this);
        progressDialog.setMessage("打印机正在进入升级模式，此过程可能需要几分钟，请耐心等待......");
        showprogress();
        //调用更新方法前一定要先调用该方法停止
        dataListenerRunner.stop();
        UpdatePrinterESC updatePrinter = new UpdatePrinterESC(connection, readResources(R.raw.x8prov1099hd2024423), otaHandler);
//        updatePrinter.setStartAddress(0x1020000);
        updatePrinter.startUpdate();
      }
    });
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
          Log.e("action", ByteArrToHex(received));
          if (received[0] == (byte) 0xFE) {
            Message message = new Message();
            message.what = PaperErrorFLAG;
            message.obj = received;
            myHandler.sendMessage(message);
            return;
          }
          if (received[0] == (byte) 0xFD) {
            Message message = new Message();
            message.what = StartOrStopFLAG;
            message.obj = received;
            myHandler.sendMessage(message);
            return;
          }
          if (received.length == 2 && received[0] == (byte) 0xFF) {
            Message message = new Message();
            message.what = StatusFLAG;
            message.obj = received;
            myHandler.sendMessage(message);
            return;
          }
          Message message = new Message();
          message.what = ReceiveFLAG;
          message.obj = received;
          myHandler.sendMessage(message);
        }
      })
      .start();
  }

  //打印机固件升级部分
  private final Handler otaHandler = new Handler() {
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
          Toast.makeText(ESCActivity.this, "打印机升级失败", Toast.LENGTH_SHORT).show();
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
          Toast.makeText(ESCActivity.this, "打印机升级完成", Toast.LENGTH_SHORT).show();
          break;
        }
      }
    }
  };

  //打印机上报状态数据
  private final Handler myHandler = new Handler() {
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
      }
    }
  };

  public void onPrintStatus(byte[] bytes) {
    Log.e("onPrintStatus", ByteArrToHex(bytes));
    if (bytes[1] == 0x00) {
      Log.e(TAG, "正常");
      show("正常");
    }
    if ((bytes[1] & 0x01) == 0x01) {
      Log.e(TAG, "过热");
      show("过热");
    }
    if ((bytes[1] & 0x02) == 0x02) {
      Log.e(TAG, "开盖");
      show("开盖");
    }
    if ((bytes[1] & 0x04) == 0x04) {
      Log.e(TAG, "缺纸");
      show("缺纸");
    }
    if ((bytes[1] & 0x08) == 0x08) {
      Log.e(TAG, "低压");
      show("低压");
    }
  }

  public void onPaperError(byte[] bytes) {
    switch (bytes[1]) {
      case 0x01:
        Log.e(TAG, "onPaperError: 折叠黑标纸");
        show("onPaperError: 折叠黑标纸");
        break;
      case 0x02:
        Log.e(TAG, "onPaperError: 连续卷筒纸");
        show("onPaperError: 连续卷筒纸");
        break;
      case 0x03:
        Log.e(TAG, "onPaperError: 不干胶缝隙纸");
        show("onPaperError: 不干胶缝隙纸");
        break;
    }
  }

  public void onStartOrStopSend(byte[] bytes) {
    switch (bytes[1]) {
      case 0x01:
        Log.e(TAG, "onStartOrStopSend: 终止命令");
        show("终止命令:FD 01");
        break;
      case 0x02:
        Log.e(TAG, "onStartOrStopSend: 继续开始命令");
        show("继续开始命令:FD 02");
        break;
    }
  }

  public void onReceive(byte[] bytes) {
    Log.e("onReceive", ByteArrToHex(bytes));
    switch (readMark) {
      case OPERATE_STATUS://主动查询状态的时候走这里
        readMark = ReadMark.NONE;
        if (bytes.length == 1) {
          String s = "状态：";
          boolean isok = true;
          if ((bytes[0] & 0x01) == 0x01) {
            s += "正在打印 ";
            isok = false;
          }
          if ((bytes[0] & 0x02) == 0x02) {
            s += "纸舱盖开 ";
            isok = false;
          }
          if ((bytes[0] & 0x04) == 0x04) {
            s += "缺纸 ";
            isok = false;
          }
          if ((bytes[0] & 0x08) == 0x08) {
            s += "电池电压低 ";
            isok = false;
          }
          if ((bytes[0] & 0x10) == 0x10) {
            s += "打印头过热 ";
            isok = false;
          }
          if (isok) {
            s += "良好";
          }
          show(s);
        }

        break;
      case OPERATE_BATVOL:
        readMark = ReadMark.NONE;
        if (bytes.length == 2) {
          String s = "电量：" + (int) bytes[1];
          show(s);
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
        show(sn_printer);
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
        show(model_printer);
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
        show(version_printer);
        Log.e(TAG, "软件版本号: " + version_printer);

        break;
      case OPERATE_BTMAC:
        readMark = ReadMark.NONE;
        String mac_address;
        mac_address = ByteArrToHex(bytes);
        show(mac_address);
        Log.e(TAG, "mac地址: " + mac_address);

        break;
      case OPERATE_TIME:
        readMark = ReadMark.NONE;
        String time = "关机时间: " + Long.parseLong(ByteArrToHex(bytes), 16) + "分钟";
        show(time);
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
        show(version_bt);
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
        show(name_bt);
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
        show(info);
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
        show(paper_type);
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
            show(i);
            Log.e(TAG, "纸张信息: " + i);
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
        break;
      case OPERATE_NFC_UID:
        readMark = ReadMark.NONE;
        String paper_uid = ByteArrToHex(bytes);
        show(paper_uid);
        Log.e(TAG, "纸张uid: " + paper_uid);
        break;
      case OPERATE_NFC_USED_LENGTH:
        readMark = ReadMark.NONE;
        String used_length = String.valueOf(Long.parseLong(ByteArrToHex(bytes), 16));
        show(used_length);
        Log.e(TAG, "纸张已使用长度: " + used_length);
        break;
      case OPERATE_NFC_REST_LENGTH:
        readMark = ReadMark.NONE;
        String rest_length = String.valueOf(Long.parseLong(ByteArrToHex(bytes), 16));
        show(rest_length);
        Log.e(TAG, "纸张剩余长度: " + rest_length);
        break;
      case OPERATE_PRINT:
        readMark = ReadMark.NONE;
        if (ByteArrToHex(bytes).equals("4F4B") || ByteArrToHex(bytes).equals("AA")) {//打印成功 比如标签纸打印完成会返回4F4B 连续纸打印完成会返回AA
          if (connection.isConnected() && sampleNumber > 0) {
            new Thread(new Runnable() {
              @Override
              public void run() {
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
        if (ByteArrToHex(bytes).equals("4F4B")) {//固件一些其他的返回在这里处理
          show("成功");
          Log.e(TAG, "成功");
        }
        if (new String(bytes).equals("ER")) {
          show("失败");
          Log.e(TAG, "失败");
        }
        break;
    }

  }

  private String Byte2Hex(Byte inByte) {
    return String.format("%02x", inByte).toUpperCase();
  }

  private String ByteArrToHex(byte[] inBytArr) {
    StringBuilder strBuilder = new StringBuilder();
    int j = inBytArr.length;
    for (int i = 0; i < j; i++) {
      strBuilder.append(Byte2Hex(inBytArr[i]));
    }
    return strBuilder.toString();
  }

  private byte[] bitmap2Bytes(Bitmap bm) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
    return baos.toByteArray();
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

  private void show(String message) {
    if (message == null) {
      return;
    }
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
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

  private byte[] readResources(int ID) {
    try {
      InputStream in = getResources().openRawResource(ID);
      int length = in.available();
      byte[] buffer = new byte[length];
      in.read(buffer);
      in.close();
      return buffer;
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
