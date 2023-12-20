package com.example.usb;


import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.net.Uri;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;


import com.example.usb.ota.FileChooseUtil;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;

import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import comprinter.psdk.frame.ota.types.mark.UpgradeMarker;
import comprinter.psdk.frame.ota.types.tspl.UpdatePrinterTSPL;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;


public class MainActivity extends AppCompatActivity {
  private GenericTSPL tspl;
  private USB usb;
  private Button switch_Usb;
  private Button bt_boot;
  private Button bt_ota_usb;
  private Button print;
  private Button bt_ota;
  private Button status_btn;
  private CheckBox cb_compress;
  private CheckBox cb_cut;
  private CheckBox cb_position;
  private Handler myHandler = new MyHandler();
  private boolean isOpen = false;
  private boolean isOpenOTA = false;
  private ProgressDialog progressDialog;
  private Button file_choose;
  private TextView tv_file;
  private USBConnectedDevice usbConnectedDevice;
  private USBConnectedDevice usbConnectedDeviceOTA;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    switch_Usb = (Button) findViewById(R.id.switch_usb);
    bt_boot = (Button) findViewById(R.id.bt_boot);
    bt_ota_usb = (Button) findViewById(R.id.bt_ota_usb);
    print = (Button) findViewById(R.id.print);
    bt_ota = (Button) findViewById(R.id.bt_ota);
    status_btn = (Button) findViewById(R.id.status);
    cb_compress = (CheckBox) findViewById(R.id.cb_compress);
    cb_cut = (CheckBox) findViewById(R.id.cb_cut);
    cb_position = (CheckBox) findViewById(R.id.cb_position);
    file_choose = findViewById(R.id.file_choose);
    tv_file = findViewById(R.id.tv_file);
    usb = new USB(this, myHandler);
    usb.register_USB();

    switch_Usb.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (isOpen) {
          usb.closeUsb();
          switch_Usb.setText("打开USB");
          isOpen = false;
        } else {
          usbConnectedDevice = usb.openUsb();
          if (usbConnectedDevice != null) {
            tspl = TSPL.generic(usbConnectedDevice);
            switch_Usb.setText("关闭USB");
            isOpen = true;
          } else {
            showMessage("打开失败，检查是否有可用的USB端口或者再次打开");
          }
        }
      }
    });
    bt_boot.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        UpdatePrinterTSPL updatePrinter = new UpdatePrinterTSPL(usbConnectedDevice);
        boolean success = updatePrinter.intoBoot();
        showMessage(success ? "进入升级模式成功" : "进入升级模式失败");

      }
    });
    print.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + 1));
        BitmapDrawable bmpDraw = new BitmapDrawable(is);
        Bitmap rawBitmap = bmpDraw.getBitmap();
        rawBitmap = Bitmap.createScaledBitmap(rawBitmap, 800, 1200, true);
        GenericTSPL _gtspl = tspl.clear().page(TPage.builder().width(100).height(150).build())
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)
              .mirror(TDirection.Mirror.NO_MIRROR)
              .build()
          )
          .gap(cb_position.isChecked())
          .cut(cb_cut.isChecked())
          .cls()
          .image(
            TImage.builder()
              .x(0)
              .y(0)
              .image(new AndroidSourceImage(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
    file_choose.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");//设置类型，我这里是任意类型，任意后缀的可以这样写。
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, 1);
      }
    });
    bt_ota_usb.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (isOpenOTA) {
          usb.closeUsb();
          bt_ota_usb.setText("打开升级模式的USB");
          isOpenOTA = false;
        } else {
          usbConnectedDeviceOTA = usb.openUsbOTA();
          if (usbConnectedDeviceOTA != null) {
            bt_ota_usb.setText("关闭升级模式的USB");
            isOpenOTA = true;
          } else {
            showMessage("打开失败，检查是否有可用的USB端口或者再次打开");
          }
        }
      }
    });
    bt_ota.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpenOTA || usbConnectedDeviceOTA == null) {
          showMessage("未打开升级模式的USB端口");
          return;
        }
        String path = tv_file.getText().toString();
        if (path.equals("未选择文件")) {
          showMessage("未选择文件");
          return;
        }
        progressDialog = new ProgressDialog(MainActivity.this);
        progressDialog.setMessage("打印机正在进入升级模式，此过程可能需要几分钟，请耐心等待......");
        showprogress();
        byte[] fileByte = FileChooseUtil.File2Bytes(new File(path));
        if (fileByte == null) {
          showMessage("文件找不到");
          return;
        }
//                byte[] filebyte=readResources(R.raw.by482ver436);
        Log.e("jcz", String.valueOf(fileByte.length));
        UpdatePrinterTSPL updatePrinter = new UpdatePrinterTSPL(usbConnectedDeviceOTA, fileByte, handler);
        updatePrinter.startUpdate();
      }
    });

    status_btn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        GenericTSPL _gtspl = tspl.version();
        String result = safeWriteAndRead(_gtspl);
        showMessage(result);
      }
    });

  }

  private byte[] readResources(int ID) {
    try {

      //得到资源中的Raw数据流
      InputStream in = getResources().openRawResource(ID);
      //得到数据的大小
      int length = in.available();
      byte[] buffer = new byte[length];
      //读取数据
      in.read(buffer);

      //关闭
      in.close();
      return buffer;
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;

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

  //蓝牙固件升级部分
  private Handler handler = new Handler() {
    @Override
    public void handleMessage(Message msg) {
      UpgradeMarker transactionTypeEnum = UpgradeMarker.getByCode(msg.what);
      switch (transactionTypeEnum) {
        case MSG_UPDATE_PROGRESS_BAR_BT: {
          int progress = (int) msg.obj;
          if (progressDialog != null) {
            progressDialog.setProgress(progress);
          }
          break;
        }
        case MSG_OTA_START_COMMAND_DATA_INVALID_BT:
        case MSG_OTA_START_COMMAND_SEND_FAILED_BT:
        case MSG_OTA_DATA_COMMAND_SEND_FAILED_BT: {
          if (progressDialog != null) {
            progressDialog.dismiss();
          }
          Toast.makeText(MainActivity.this, "OTA错误", Toast.LENGTH_SHORT).show();
          break;
        }
        case MSG_OTA_DATA_START_BT: {
          if (progressDialog != null) {
            progressDialog.setMessage("开始OTA");
          }
          break;
        }
        case MSG_OTA_FINISHED_BT: {
          if (progressDialog != null) {
            progressDialog.setProgress(100);
            progressDialog.dismiss();
            progressDialog = null;
          }
          Toast.makeText(MainActivity.this, "OTA完成", Toast.LENGTH_SHORT).show();
          break;
        }
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
          Toast.makeText(MainActivity.this, "打印机升级失败", Toast.LENGTH_SHORT).show();
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
          Toast.makeText(MainActivity.this, "打印机升级完成", Toast.LENGTH_SHORT).show();
          break;
        }
      }
    }
  };

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (resultCode == Activity.RESULT_OK) {//是否选择，没选择就不会继续
      Uri uri = data.getData();//得到uri，后面就是将uri转化成file的过程。
      String file_path = FileChooseUtil.getFileAbsolutePath(this, uri);
      if (file_path.contains("PRTU")) {
        tv_file.setText(file_path);
      } else {
        Toast.makeText(this, "文件类型有误", Toast.LENGTH_SHORT).show();
      }
    } else {
      Toast.makeText(this, "未选择文件", Toast.LENGTH_SHORT).show();
    }
  }

  //第一个参数文件名称（不加后缀）， 第二个参数文件夹名称，第三个参数包名
  public int getImageID(String name) {
    return getResources().getIdentifier(name, "raw",
      getPackageName());
  }

  private class MyHandler extends Handler {
    @Override
    public void handleMessage(Message msg) {
      switch (msg.what) {
        case USB.OPEN:
          showMessage("USB已打开！");
          break;
        case USB.ATTACHED:
          showMessage("监测到设备！");
          break;
        case USB.DETACHED:
          showMessage("设备已移除！");
          switch_Usb.setText("打开USB");
          bt_ota_usb.setText("打开升级模式的USB");
          isOpen = false;
          isOpenOTA = false;
          usbConnectedDevice = null;
          usbConnectedDeviceOTA = null;
          break;

      }
    }

  }

  //    private void dataListen(ConnectedDevice connectedDevice) {
//        DataListener.with(connectedDevice).listen(new ListenAction() {
//            @Override
//            public void action(byte[] bytes) {
//            //固件回传的数据
//            }
//        }).start();
//    }

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

  private void showMessage(String s) {
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
