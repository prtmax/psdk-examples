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
import com.printer.psdk.compatible.external.inkjet.*;
import com.printer.psdk.compatible.external.inkjet.mark.ImageMode;
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

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
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
  private final int PrintProcessFLAG = 0x12;
  private ReadMark readMark = ReadMark.NONE;
  private boolean isSending = false;
  private ProgressDialog progressDialog;
  private DataListenerRunner dataListenerRunner;
  private CompatibleInkJet compatibleInkJet;

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
              InputStream is = getResources().openRawResource(R.raw.caomei);
              BitmapDrawable bmpDraw = new BitmapDrawable(is);
              Bitmap rawBitmap = bmpDraw.getBitmap();
              // 目标宽度
              int targetWidth = 1052;

              // 获取原始 Bitmap 的宽度和高度
              int originalWidth = rawBitmap.getWidth();
              int originalHeight = rawBitmap.getHeight();

              // 计算新的高度，保持纵横比
              int targetHeight = (int) ((float) originalHeight * targetWidth / originalWidth);

              // 按宽度和计算出的高度进行缩放
              rawBitmap = Bitmap.createScaledBitmap(rawBitmap, targetWidth, targetHeight, true);
              readMark = ReadMark.OPERATE_PRINT;
              CompatibleInkJet _compatibleInkJet = compatibleInkJet.page(IPage.builder().width(44).height(60).build())
                .cls()
                .image(IImage.builder().image(new AndroidSourceImage(rawBitmap)).mode(ImageMode.JPG).build())
                .print(1);
//              Log.e(TAG, "下发的hex: " + _compatibleInkJet.command().hex());
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
          Log.e(TAG, ByteArrToHex(received));
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
              messageBatteryStatus.what = PrintProcessFLAG;
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
          parseStatus((byte[]) msg.obj);
          break;
        case PrintProcessFLAG:
          onPrintProcess((byte[]) msg.obj);
          break;
      }
    }
  };

  // 状态掩码映射表
  private static final Map<Integer, String> STATUS_MASKS = new LinkedHashMap<Integer, String>() {{
    put(0x00000001, "开盖");
    put(0x00000002, "卡纸");
    put(0x00000004, "缺纸");
    put(0x00000008, "缺墨");
    put(0x00000020, "繁忙");
    put(0x00000040, "低压");
    put(0x00000100, "正在取消");
    put(0x00000200, "数据异常");
    put(0x00000400, "机电错误");
    put(0x00000800, "纸道有纸");
    put(0x00001000, "无墨盒");
  }};

  /**
   * 解析打印机状态 (直接接收字节数组)
   * @param bytes 四字节数组
   * @return 状态列表，如果正常则返回包含"正常"的列表
   */
  public static List<String> parsePrinterStatus(byte[] bytes) {
    List<String> statuses = new ArrayList<>();

    // 检查输入长度
    if (bytes == null || bytes.length != 4) {
      statuses.add("错误: 输入必须是四个字节");
      return statuses;
    }

    // 将字节数组转换为小端序的整数值
    int value = (bytes[0] & 0xFF) |
      ((bytes[1] & 0xFF) << 8) |
      ((bytes[2] & 0xFF) << 16) |
      ((bytes[3] & 0xFF) << 24);

    // 检查正常状态
    if (value == 0) {
      statuses.add("正常");
      return statuses;
    }

    // 检查每个状态掩码
    for (Map.Entry<Integer, String> entry : STATUS_MASKS.entrySet()) {
      int mask = entry.getKey();
      if ((value & mask) != 0) {
        statuses.add(entry.getValue());
      }
    }

    // 如果没有匹配的状态
    if (statuses.isEmpty()) {
      statuses.add("未知状态 (0x" + Integer.toHexString(value) + ")");
    }

    return statuses;
  }

  // 解析打印机状态数据
  public static String parseStatus(byte[] data) {
    if (data == null || data.length != 5) {
      return "无效数据: 数据长度错误";
    }

    // 验证数据头
    if (data[0] != (byte) 0xFF) {
      return "无效数据: 数据头不匹配";
    }

    // 提取状态类型标识（4个字节）
    int statusType = ((data[1] & 0xFF) << 24) |
      ((data[2] & 0xFF) << 16) |
      ((data[3] & 0xFF) << 8) |
      (data[4] & 0xFF);

    // 根据状态类型标识映射到对应的状态描述
    String status = mapStatusToString(statusType);
    Log.e(TAG, "主动上报状态: " + status);
    return status;
  }

  // 将状态码映射为字符串描述
  private static String mapStatusToString(int statusType) {
    switch (statusType) {
      case 0x00000000: return "正常";
      case 0x00000001: return "开盖";
      case 0x00000003: return "卡纸";
      case 0x00000004: return "缺纸";
      case 0x00000008: return "缺墨";
      case 0x00000040: return "低压";
      case 0x00000100: return "正在取消";
      case 0x00000200: return "数据异常";
      case 0x00000400: return "机电错误";
      case 0x00000800: return "纸道有纸";
      case 0x00001000: return "无墨盒";
      default: return "未知状态: " + String.format("0x%08X", statusType);
    }
  }

  public int onPrintProcess(byte[] data) {
    // 验证数据长度
    if (data == null || data.length != 5) {
      return -1;
    }

    // 验证数据头 (0xFD)
    if (data[0] != (byte) 0xFD) {
      return -1;
    }

    // 解析进度值
    int progress = data[4] & 0xFF;

    // 验证进度范围 (0-100)
    if (progress > 100) {
      return -1;
    }
    Log.e(TAG, "打印进度: " + progress);
    return progress;
  }
  /**
   * 解析墨盒状态
   * @param data 墨盒状态字节数组
   * @return 墨水量
   */
  public int parseInkStatus(byte[] data) {
    // 验证数据长度
    if (data == null || data.length < 11) {
      return 0;
    }

    // 验证数据头 "INK " (4字节)
    byte[] header = new byte[]{'I', 'N', 'K', ' '};
    for (int i = 0; i < header.length; i++) {
      if (data[i] != header[i]) {
        return 0;
      }
    }

    try {

      // 解析墨水量 (第5个字节)
      int inkLevel = data[4] & 0xFF; // 转换为无符号整数
      Log.e(TAG, "墨水量: " + inkLevel);
      show("墨水量: " + inkLevel);
      // 解析四位唯一标识 (第6-9字节)
      String uniqueId = String.format("%02X%02X%02X%02X",
        data[5] & 0xFF,
        data[6] & 0xFF,
        data[7] & 0xFF,
        data[8] & 0xFF);
      Log.e(TAG, "墨盒四位唯一标识: " + uniqueId);
      return inkLevel;
    } catch (Exception e) {
      return 0;
    }
  }
  /**
   * 解析打印机配置响应
   * @param data 配置响应的字节数组
   * @return 包含所有配置信息的 Config 对象，解析失败返回 null
   */
  public Config parseConfigResponse(byte[] data) {
    // 验证数据长度
    if (data == null || data.length < 18) { // 最小长度: 7(CONFIG) + 2(res) + 3(hw) + 3(fw) + 2(shutdown+beep) + 2(\r\n) = 19?
      return null;
    }

    // 验证数据头 "CONFIG " (7字节)
    byte[] header = new byte[]{'C', 'O', 'N', 'F', 'I', 'G', ' '};
    for (int i = 0; i < header.length; i++) {
      if (data[i] != header[i]) {
        return null;
      }
    }

    Config config = new Config();

    try {
      int offset = 7; // 跳过 "CONFIG " 头

      // 1. 解析分辨率 (2字节，大端序)
      config.resolution = ((data[offset] & 0xFF) << 8) | (data[offset + 1] & 0xFF);
      offset += 2;

      // 2. 解析硬件版本 (3字节)
      config.hardwareVersion = String.format("%d.%d.%d",
        data[offset] & 0xFF,
        data[offset + 1] & 0xFF,
        data[offset + 2] & 0xFF);
      offset += 3;

      // 3. 解析固件版本 (3字节)
      byte fwByte1 = data[offset];
      int major = (fwByte1 >> 4) & 0x0F; // 高4位
      int minor = fwByte1 & 0x0F;         // 低4位
      int build = ((data[offset + 1] & 0xFF) << 8) | (data[offset + 2] & 0xFF); // 后2字节

      config.firmwareVersion = String.format("%d.%d.%d", major, minor, build);
      offset += 3;

      // 4. 解析定时关机 (1字节)
      config.autoShutdown = data[offset] & 0xFF;
      offset++;

      // 5. 解析提示音 (1字节)
      config.beepEnabled = data[offset] & 0xFF;
      offset++;

      // 验证结束符 (可选)
      // 理论上最后两个字节应为 0x0D 0x0A (\r\n)
      Log.e(TAG, "打印机所有信息: " + config);
      show("打印机所有信息: " + config);
      return config;

    } catch (Exception e) {
      return null;
    }
  }

  /**
   * 解析电池状态
   * @param data 电池状态字节数组
   * @return 电量和充电状态
   */
  public int parseBatteryStatus(byte[] data) {
    // 验证数据长度
    if (data == null || data.length < 12) {
      return 0;
    }

    // 验证数据头 "BATTERY " (8字节)
    byte[] header = new byte[]{'B', 'A', 'T', 'T', 'E', 'R', 'Y', ' '};
    for (int i = 0; i < header.length; i++) {
      if (data[i] != header[i]) {
        return 0;
      }
    }

    try {

      // 解析电量百分比 (第9个字节)
      int batteryLevel = data[8] & 0xFF; // 转换为无符号整数
      Log.e(TAG, "电量: " + batteryLevel);
      show("电量: " + batteryLevel);
      // 解析充电状态 (第10个字节)
      boolean isCharging = (data[9] & 0xFF) == 0x01;
      Log.e(TAG, "充电状态: " + (isCharging?"充电中":"未充电"));
      show("充电状态: " + (isCharging?"充电中":"未充电"));
      return batteryLevel;
    } catch (Exception e) {
      return 0;
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
        List<String> status = parsePrinterStatus(bytes);
        Log.e(TAG, "主动查询状态: " + status);
        show("主动查询状态: " + status);
        break;
      case OPERATE_BATVOL:
        readMark = ReadMark.NONE;
        parseBatteryStatus(bytes);
        break;
      case OPERATE_INFO:
        readMark = ReadMark.NONE;
        parseConfigResponse(bytes);
        break;
      case OPERATE_INK_BOX_INFO:
        readMark = ReadMark.NONE;
        parseInkStatus(bytes);
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

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
