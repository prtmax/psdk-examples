package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.printer.psdk.compatible.external.inkjet.*;
import com.printer.psdk.compatible.external.inkjet.mark.ShutdownTime;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.frame.father.types.lifecycle.Lifecycle;
import com.printer.psdk.imagep.android.AndroidSourceImage;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

public class MainActivity extends Activity {
  private static final String TAG = "MainActivity";
  private Connection connection;
  private TextView tv_connect_status;
  private Button continueButton;
  private Button labelButton;
  private Button statusButton;
  private Button batteryVolButton;
  private Button printer_info;
  private Button set_off_time;
  private Button ink_box_info;
  private Button updatePrinterButton;
  private EditText sampleEdit;
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
  private CompatibleInkJet compatibleInkJet;
  private static final int[] STATUS_MASKS = {
    0x00000001, 0x00000002, 0x00000004, 0x00000008,
    0x00000040, 0x00000100, 0x00000200, 0x00000400,
    0x00000800, 0x00001000
  };
  private static final String[] STATUS_DESCRIPTIONS = {
    "开盖", "卡纸", "缺纸", "缺墨",
    "低压", "正在取消", "数据异常", "机电错误",
    "纸道有纸", "无墨盒"
  };

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    sampleEdit = (EditText) findViewById(R.id.sampleEdit);
    continueButton = (Button) findViewById(R.id.print_continue);
    labelButton = (Button) findViewById(R.id.printer_label);
    statusButton = (Button) findViewById(R.id.printer_status);
    batteryVolButton = (Button) findViewById(R.id.printer_BatteryVol);
    printer_info = (Button) findViewById(R.id.printer_info);
    set_off_time = (Button) findViewById(R.id.set_off_time);
    ink_box_info = (Button) findViewById(R.id.ink_box_info);
    updatePrinterButton = (Button) findViewById(R.id.updatePrinter);
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        compatibleInkJet = new CompatibleInkJet(Lifecycle.builder().connectedDevice(connectedDevice).build());
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
              //打印图片指令
              InputStream is = getResources().openRawResource(R.raw.logo);
              BitmapDrawable bmpDraw = new BitmapDrawable(is);
              Bitmap bitmap = bmpDraw.getBitmap();
              readMark = ReadMark.OPERATE_PRINT;
              CompatibleInkJet _compatibleInkJet = compatibleInkJet.page(IPage.builder().width(100).height(100).build())
                .cls()
                .image(IImage.builder().image(new AndroidSourceImage(bitmap)).build())
                .print(1);
              safeWrite(_compatibleInkJet);
              sampleNumber--;
            }
          }
        }).start();
      }
    });
    statusButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_STATUS;
        CompatibleInkJet _compatibleInkJet = compatibleInkJet.state();
        safeWrite(_compatibleInkJet);
      }
    });
    batteryVolButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BATVOL;
        CompatibleInkJet _compatibleInkJet = compatibleInkJet.batteryVolume();
        safeWrite(_compatibleInkJet);
      }
    });
    printer_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_INFO;
        CompatibleInkJet _compatibleInkJet = compatibleInkJet.info();
        safeWrite(_compatibleInkJet);
      }
    });
    set_off_time.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_SHUTDOWN_TIME;
        CompatibleInkJet _compatibleInkJet = compatibleInkJet.setShutdownTime(ISetShutdownTime.builder().time(ShutdownTime.min15).build());
        safeWrite(_compatibleInkJet);
      }
    });
    ink_box_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_INK_BOX_INFO;
        CompatibleInkJet _compatibleInkJet = compatibleInkJet.inkBoxInfo();
        safeWrite(_compatibleInkJet);
      }
    });
    updatePrinterButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        progressDialog = new ProgressDialog(MainActivity.this);
        progressDialog.setMessage("打印机正在进入升级模式，此过程可能需要几分钟，请耐心等待......");
        showprogress();
        readMark = ReadMark.OPERATE_OTA;
//        CompatibleInkJet _compatibleInkJet = compatibleInkJet.ota(IOta.builder().data(readResources(R.raw.x8prov1099hd2024423)).build());
//        safeWrite(_compatibleInkJet);
      }
    });
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
          if (received.length == 0) return;
          Log.e("action", ByteArrToHex(received));
          // 根据数据类型处理
          switch (received[0]) {
            case (byte) 0xFF:
              Message messageStatus = new Message();
              messageStatus.what = StatusFLAG;
              messageStatus.obj = received;
              myHandler.sendMessage(messageStatus);
              break;
            case (byte) 0xFD:
              Message messageBatteryStatus = new Message();
              messageBatteryStatus.what = BatteryStatusFLAG;
              messageBatteryStatus.obj = received;
              myHandler.sendMessage(messageBatteryStatus);
              break;
            default:
              Message message = new Message();
              message.what = ReceiveFLAG;
              message.obj = received;
              myHandler.sendMessage(message);
              break;
          }
        }
      })
      .start();
  }

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
        case BatteryStatusFLAG:
          onBatteryStatus((byte[]) msg.obj);
          break;
      }
    }
  };

  public void onPrintStatus(byte[] data) {
    Log.e("onPrintStatus", ByteArrToHex(data));
    byte[] statusBytes = Arrays.copyOfRange(data, 1, 5);
    int status = ByteBuffer.wrap(statusBytes)
      .order(ByteOrder.BIG_ENDIAN)
      .getInt();

    List<String> statusList = new ArrayList<>();
    for (int i = 0; i < STATUS_MASKS.length; i++) {
      if ((status & STATUS_MASKS[i]) != 0) {
        statusList.add(STATUS_DESCRIPTIONS[i]);
      }
    }
    show(TextUtils.join(", ", statusList));
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
    onCancelPrint();
  }

  public void onStartOrStopSend(byte[] bytes) {
    switch (bytes[1]) {
      case 0x01:
        Log.e(TAG, "onStartOrStopSend: 终止命令");
        show("终止命令:FD 01");
        onCancelPrint();
        break;
      case 0x02:
        Log.e(TAG, "onStartOrStopSend: 继续开始命令");
        show("继续开始命令:FD 02");
        break;
    }
  }

  public void onBatteryStatus(byte[] bytes) {
    switch (bytes[1]) {
      case 0x00:
        show("电池状态:正常");
        break;
      case 0x01:
        show("电池状态:低电");
        break;
      case 0x02:
        show("电池状态:充电中");
        break;
      case 0x03:
        show("电池状态:充电完成");
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
      case OPERATE_OTA:
        readMark = ReadMark.NONE;
        progressDialog.dismiss();
        String ota = "";
        try {
          ota = new String(bytes, "GB2312");
        } catch (UnsupportedEncodingException e) {
          e.printStackTrace();
        }
        if (ota.contains("Error")) {
          show("升级失败");
        } else {
          show("升级成功");
        }
        break;
      case OPERATE_PRINT:
        readMark = ReadMark.NONE;
        if (ByteArrToHex(bytes).contains("AA")) {//打印成功 比如标签纸打印完成会返回4F4B 连续纸打印完成会返回AA
          if (connection.isConnected() && sampleNumber > 0) {
            new Thread(new Runnable() {
              @Override
              public void run() {
                //打印图片指令
                InputStream is = getResources().openRawResource(R.raw.logo);
                BitmapDrawable bmpDraw = new BitmapDrawable(is);
                Bitmap bitmap = bmpDraw.getBitmap();
                readMark = ReadMark.OPERATE_PRINT;
                CompatibleInkJet _compatibleInkJet = compatibleInkJet.page(IPage.builder().width(100).height(100).build())
                  .cls()
                  .image(IImage.builder().image(new AndroidSourceImage(bitmap)).build())
                  .print(1);
                safeWrite(_compatibleInkJet);
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
