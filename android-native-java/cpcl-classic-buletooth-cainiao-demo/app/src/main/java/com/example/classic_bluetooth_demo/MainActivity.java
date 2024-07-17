package com.example.classic_bluetooth_demo;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Message;
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
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.listener.DataListener;
import com.printer.psdk.frame.father.listener.DataListenerRunner;
import com.printer.psdk.frame.father.listener.ListenAction;
import com.printer.psdk.imagep.android.AndroidSourceImage;

import java.io.IOException;


public class MainActivity extends AppCompatActivity {
  private Connection connection;
  private TextView tv_connect_status;
  private Button btn_cmd, btn_bitmap, btn_battery, btn_status;
  private GenericCPCL cpcl;
  private EditText sampleEdit;
  private int sampleNumber;
  private ReadMark readMark = ReadMark.NONE;
  private DataListenerRunner dataListenerRunner;
  private final int ReceiveFLAG = 0x10;
  private final int PrintFinishFLAG = 0x11;
  private final int StatusFLAG = 0x12;
  private final Handler timeoutHandler = new Handler();
  private Runnable timeoutRunnable;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    btn_cmd = findViewById(R.id.btn_cmd);
    btn_bitmap = findViewById(R.id.btn_bitmap);
    btn_battery = findViewById(R.id.btn_battery);
    btn_status = findViewById(R.id.btn_status);
    sampleEdit = findViewById(R.id.sampleEdit);
    sampleEdit.setText("1");
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        cpcl = CPCL.generic(connectedDevice);
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

    btn_battery.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_BATVOL;
        GenericCPCL _gcpcl = cpcl.batteryVolume();
        safeWrite(_gcpcl);
      }
    });


    btn_status.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        readMark = ReadMark.OPERATE_STATUS;
        GenericCPCL _gcpcl = cpcl.status();
        safeWrite(_gcpcl);
      }
    });


    btn_cmd.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (sampleEdit.getText().toString().trim().equals("")) {
          sampleNumber = 1;
        } else {
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
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
          sampleNumber = Integer.parseInt(sampleEdit.getText().toString().trim());
        }
        BitmapFactory.Options mOptions = new BitmapFactory.Options();
        mOptions.inScaled = false;
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.logo, mOptions);
        GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(400).height(320).copies(sampleNumber).build())
          .image(CImage.builder()
            .startX(10)
            .startY(0)
            .image(new AndroidSourceImage(bitmap))
            .compress(true)
            .build()
          )
          .form()
          .print(CPrint.builder().build());
        startTimer(3000L * sampleNumber);//打印前开个超时定时器,打印机超过该时间不返回数据就认为打印失败,多份的话可以依据份数来增加超时时间
        safeWrite(_gcpcl);
      }
    });
  }

  //打印机上报数据
  private final Handler myHandler = new Handler(msg -> {
    switch (msg.what) {
      case ReceiveFLAG:
        onReceive((byte[]) msg.obj);
        break;
      case PrintFinishFLAG:
        stopTimer();
        show("打印成功");
        readMark = ReadMark.OPERATE_STATUS;
        GenericCPCL _gcpcl = cpcl.status();
        safeWrite(_gcpcl);
        break;
      case StatusFLAG:
        stopTimer();
        byte[] bytes = (byte[]) msg.obj;
        if (ByteArrToHex(bytes).equals("AAFF010155")) {
          show("纸舱盖打开");
        }
        if (ByteArrToHex(bytes).equals("AAFF010255")) {
          show("缺纸");
        }
        if (ByteArrToHex(bytes).equals("AAFF010355")) {
          show("卡纸");
        }
        if (ByteArrToHex(bytes).equals("AAFF010455")) {
          show("低电压");
        }
        if (ByteArrToHex(bytes).equals("AAFF010555")) {
          show("打印头异常");
        }
        break;
    }
    return true;
  });


  private void dataListen(ConnectedDevice connectedDevice) {
    dataListenerRunner = DataListener.with(connectedDevice)
      .listen(new ListenAction() {
        @Override
        public void action(byte[] received) {
          Log.e("onReceive", ByteArrToHex(received));
          if (ByteArrToHex(received).equals("4F4B")) {
            Message message = new Message();
            message.what = PrintFinishFLAG;
            message.obj = received;
            myHandler.sendMessage(message);
            return;
          }
          if (received.length == 5) {
            if (received[0] == (byte) 0xAA && received[1] == (byte) 0xFF) {
              Message message = new Message();
              message.what = StatusFLAG;
              message.obj = received;
              myHandler.sendMessage(message);
              return;
            }
          }
          Message message = new Message();
          message.what = ReceiveFLAG;
          message.obj = received;
          myHandler.sendMessage(message);
        }
      })
      .start();
  }

  /**
   * 说明：1.以下单位都是dot 1mm=8dot(分辨率203) 1mm=12dot(分辨率300) 开发者根据自己使用的打印机来适配
   * 2.字体问题，当使用到例如Font.TSS24_MAX1 带MAX这类的字体时需要.font(Font.TSS24_MAX1).mag(true)才会生效 .mag(true)是允许倍数放大
   * 3.一个完整的指令.page()是指令头 .print()是指令尾必不可少的
   * 4.需要整个页面旋转的时候.print(CPrint.builder().mode(CPrint.Mode.MIRROR).build());
   */
  private void printNow() {
    GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1040).copies(sampleNumber).build())
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
      .text(CText.builder().textX(598 - 56 - 16 - 120 + 17).textY(696 + 80 + 136 + 11 + 6).font(Font.TSS24).content("已验视").build())
      .form()//标签定位指令
      .print(CPrint.builder().mode(CPrint.Mode.NORMAL).build());
    startTimer(3000L * sampleNumber);//打印前开个超时定时器,打印机超过该时间不返回数据就认为打印失败,多份的话可以依据份数来增加超时时间
    safeWrite(_gcpcl);
  }

  public void onReceive(byte[] bytes) {
    switch (readMark) {
      case OPERATE_STATUS://主动查询状态的时候走这里
        readMark = ReadMark.NONE;
        String status = printerStatus(bytes);
        show(status);
        readMark = ReadMark.OPERATE_BATVOL;
        GenericCPCL _gcpcl = cpcl.batteryVolume();
        safeWrite(_gcpcl);
        break;
      case OPERATE_BATVOL:
        readMark = ReadMark.NONE;
        if (bytes.length == 1) {
          String s = "电量：" + (int) bytes[0];
          show(s);
        }
        break;
      case OPERATE_PRINT:
        readMark = ReadMark.NONE;

      default:
        readMark = ReadMark.NONE;
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

  /**
   * 查询打印机状态
   *
   * @return 1.准备就绪  2.纸舱盖打开 3.缺纸 4.正在打印中 5.低电压
   */
  public String printerStatus(byte[] Rep) {
    if (Rep == null) {
      return "失败";
    }
    if (Rep[0] == 0x00) {
      return "准备就绪";
    }
    if ((Rep[0] == 0x4f) && (Rep[1] == 0x4b)) {
      return "准备就绪";
    }
    if ((Rep[0] & 16) != 0) {
      return "纸舱盖打开";
    }
    if ((Rep[0] & 1) != 0) {
      return "缺纸";
    }
    if ((Rep[0] & 8) != 0) {
      return "正在打印中";
    }
    if ((Rep[0] & 4) != 0) {
      return "低电压";
    }
    return "准备就绪";
  }

  private void show(String message) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }

  public void startTimer(long timeout) {
    timeoutRunnable = new Runnable() {
      @Override
      public void run() {
        onTimeout();
      }
    };
    timeoutHandler.postDelayed(timeoutRunnable, timeout);
  }

  public void stopTimer() {
    timeoutHandler.removeCallbacks(timeoutRunnable);
  }

  private void onTimeout() {
    show("打印失败");
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
    stopTimer();
  }

}
