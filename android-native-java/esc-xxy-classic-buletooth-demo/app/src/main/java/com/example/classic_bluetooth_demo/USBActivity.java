package com.example.classic_bluetooth_demo;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.esc.ESC;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.esc.args.ELocation;
import com.printer.psdk.esc.args.EPaperType;
import com.printer.psdk.esc.mark.Location;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;


public class USBActivity extends Activity {
  private static final String TAG = "USBActivity";
  private GenericESC esc;
  private USB usb;
  private Button switch_Usb;
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
  private EditText sampleEdit;
  private int sampleNumber;
  private final int ReceiveFLAG = 0x10;
  private final int StatusFLAG = 0x11;
  private final int PaperErrorFLAG = 0x12;
  private final int StartOrStopFLAG = 0x13;
  private ReadMark readMark = ReadMark.NONE;
  private boolean isSending = false;
  private Button bottom_stock, bottom_label, bottom_adhesive;
  private Handler usbHandler = new USBHandler();
  private boolean isOpen = false;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_usb);
    switch_Usb = (Button) findViewById(R.id.switch_usb);
    sampleEdit = (EditText) findViewById(R.id.sampleEdit);
    sampleEdit.setText("1");
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
    bottom_stock = (Button) findViewById(R.id.bottom_stock);
    bottom_label = (Button) findViewById(R.id.bottom_label);
    bottom_adhesive = (Button) findViewById(R.id.bottom_adhesive);
    usb = new USB(this, usbHandler);
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
            dataListen(usbConnectedDevice);
            switch_Usb.setText("关闭USB");
            isOpen = true;
          } else {
            show("打开失败，检查是否有可用的USB端口");
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
        if (!isSending) {
          new Thread(new Runnable() {
            @Override
            public void run() {
              for (int i = 0; i < sampleNumber; i++) {
                isSending = true;
                if (isOpen) {
                  //打印图片指令
                  InputStream is = getResources().openRawResource(R.raw.logo);
                  BitmapDrawable bmpDraw = new BitmapDrawable(is);
                  Bitmap bitmap = bmpDraw.getBitmap();
                  GenericESC _gesc = esc.enable()
                    .wakeup()
                    .location(ELocation.builder().location(Location.CENTER).build())
                    .lineDot(1)
                    .image(EImage.builder()
                      .image(bitmap2Bytes(bitmap))
                      .build())
                    .lineDot(10)
                    .stopJob();
                  safeWrite(_gesc);
                  try {
                    Thread.sleep(100);
                  } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                  }
                  if (i == (sampleNumber - 1)) {
                    isSending = false;
                  }
                }
              }
            }
          }).start();
        }
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
        if (!isSending) {
          isSending = true;
          new Thread(new Runnable() {
            @Override
            public void run() {
              for (int i = 0; i < sampleNumber; i++) {
                isSending = true;
                if (isOpen) {
                  //打印图片指令
                  InputStream is = getResources().openRawResource(R.raw.p3);
                  BitmapDrawable bmpDraw = new BitmapDrawable(is);
                  Bitmap bitmap = bmpDraw.getBitmap();
                  GenericESC _gesc = esc
                    .enable()
                    .wakeup()
                    .location(ELocation.builder().location(Location.CENTER).build())
                    .image(EImage.builder()
                      .image(bitmap2Bytes(bitmap))
                      .build())
                    .lineDot(0)
                    .position()//缝隙标签纸打印就是打印结束后多执行了这个指令
                    .stopJob();
                  safeWrite(_gesc);
                  try {
                    Thread.sleep(100);
                  } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                  }
                  if (i == (sampleNumber - 1)) {
                    isSending = false;
                  }
                }
              }
            }
          }).start();
        }
      }
    });

    //其他功能可以参考蓝牙的
    statusButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_STATUS;
        GenericESC _gesc = esc.state();
        safeWrite(_gesc);
      }
    });
    batteryVolButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BATVOL;
        GenericESC _gesc = esc.batteryVolume();
        safeWrite(_gesc);
      }
    });
    version_printerButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERVER;
        GenericESC _gesc = esc.printerVersion();
        safeWrite(_gesc);
      }
    });
    snButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERSN;
        GenericESC _gesc = esc.sn();
        safeWrite(_gesc);
      }
    });
    modelButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_PRINTERMODEL;
        GenericESC _gesc = esc.model();
        safeWrite(_gesc);
      }
    });
    macaddressButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTMAC;
        GenericESC _gesc = esc.mac();
        safeWrite(_gesc);
      }
    });
    bt_nameButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTNAME;
        GenericESC _gesc = esc.name();
        safeWrite(_gesc);
      }
    });
    version_btButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BTVER;
        GenericESC _gesc = esc.version();
        safeWrite(_gesc);
      }
    });
    printer_info.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_INFO;
        GenericESC _gesc = esc.info();
        safeWrite(_gesc);
      }
    });
    bottom_stock.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericESC _gesc = esc.paperType(EPaperType.builder().type(EPaperType.Type.CONTINUOUS_REEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    bottom_label.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericESC _gesc = esc.paperType(EPaperType.builder().type(EPaperType.Type.FOLDED_BLACK_LABEL_PAPER).build());
        safeWrite(_gesc);
      }
    });
    bottom_adhesive.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericESC _gesc = esc.paperType(EPaperType.builder().type(EPaperType.Type.NO_DRY_ADHESIVE_PAPER).build());
        safeWrite(_gesc);
      }
    });
  }

  private void dataListen(ConnectedDevice connectedDevice) {
    DataListenerRunner dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
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
        String mac_address = null;
        mac_address = ByteArrToHex(bytes);
        show(mac_address);
        Log.e(TAG, "mac地址: " + mac_address);

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
      default:
        if (ByteArrToHex(bytes).equals("4F4B")) {//固件一些其他的返回在这里处理 比如成功失败
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

  private class USBHandler extends Handler {
    @Override
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case USB.OPEN:
          show("USB已打开！");
          switch_Usb.setText("关闭USB");
          isOpen = true;
          break;
        case USB.ATTACHED:
          show("监测到设备！");
          break;
        case USB.DETACHED:
          show("设备已移除！");
          switch_Usb.setText("打开USB");
          isOpen = false;
          break;

      }
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

  private void show(String s) {
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
