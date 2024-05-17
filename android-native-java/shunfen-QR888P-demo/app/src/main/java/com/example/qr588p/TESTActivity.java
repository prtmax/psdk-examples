package com.example.qr588p;


import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.*;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.*;
import androidx.core.app.ActivityCompat;
import com.example.qr588p.zxing.activity.CaptureActivity;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.args.common.Raw;
import com.printer.psdk.frame.father.types.write.WriteOptions;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.Timer;
import java.util.TimerTask;


public class TESTActivity extends Activity {
  private Connection connection;
  private TextView tv_connect_status, tv_cur_ver, tv_new_ver,tv_file;
  private ImageView testImage;
  private Button btnScan, btnModel, btnUpdate,file_choose;
  private GenericTSPL tspl;
  private static final int REQUEST_CONNECT_DEVICE = 1;
  private static final int QRCODE_SCAN = 3;
  private static final int FILE_CHOOSE = 4;
  private Boolean isConnected = false;
  private Boolean isConnecting = false;
  private final BluetoothReceiver bluetoothReceiver = new BluetoothReceiver();
  private String address = "";
  private Timer timer;
  private ProgressDialog loading;
  private String newVersion = "";
  private String curVersion = "";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_test);
    tv_connect_status = findViewById(R.id.tv_connect_status);
    tv_cur_ver = findViewById(R.id.tv_cur_ver);
    tv_new_ver = findViewById(R.id.tv_new_ver);
    btnScan = findViewById(R.id.btnScan);
    btnModel = findViewById(R.id.btnModel);
    btnUpdate = findViewById(R.id.btnUpdate);
    file_choose = findViewById(R.id.file_choose);
    tv_file = findViewById(R.id.tv_file);
    testImage = findViewById(R.id.image);

    btnScan.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Intent openCameraIntent = new Intent(TESTActivity.this, CaptureActivity.class);
        startActivityForResult(openCameraIntent, QRCODE_SCAN);
      }
    });
    file_choose.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");//设置类型，我这里是任意类型，任意后缀的可以这样写。
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, FILE_CHOOSE);
      }
    });
    btnUpdate.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        String path = tv_file.getText().toString();
        if (path.equals("未选择文件")) {
          show("未选择文件");
          return;
        }
        updateFw();
      }
    });
    btnModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isConnected) {
          show("未连接");
          return;
        }
//        GenericTSPL _gtspl = tspl.raw(Raw.builder().command(
//          "^XA^LH0,0^PW480^CI28^LL600^FS^A@N,60,55,SIMSUN.TTF^FO42,40^FDT4-762混^FS\r\n" +
//          "^A@N,30,30,SIMSUN.TTF^FO42,110^FD件数:^FS\r\n" +
//          "^A@N,30,30,SIMSUN.TTF^FO182,110^FD格口:^FS\r\n" +
//          "^A@N,40,35,SIMSUN.TTF^FO117,105^FD1^FS\r\n" +
//          "^A@N,40,35,SIMSUN.TTF^FO257,105^FD22^FS\r\n" +
//          "^A@N,30,35,SIMSUN.TTF^FO312,110^FD(重)^FS\r\n" +
//          "^A@N,60,55,SIMSUN.TTF^FO150,30^FQ150^FY(重)^FS\r\n" +
//          "^FO42,150^BY4^BCN,100,N,N,N^FD>;822016933846^FS\r\n" +
//          "^FO372,40^BQN,2,3^FDMA,P822016933846,D762VA^FS\r\n" +
//          "^A@N,30,30,SIMSUN.TTF^FO42,260^FD822016933846^FS\r\n" +
//          "^A@N,30,30,SIMSUN.TTF^FO312,260^FD04/26 10:47^FS\r\n" +
//          "^XZ\r\n").build());
        GenericTSPL _gtspl = tspl.raw(Raw.builder().command(
          "^XA\r\n" +
            "^MMT\r\n" +
            "^CW0,E:MHEIGB18.TTF\r\n" +
            "^CI26\r\n" +
            "^CF0^FS\r\n" +
            "^LH0,0\r\n" +
            "^FX方框以X125 Y95坐标进行起始位进行打印^FS\r\n" +
            "^FO20,289,0^GB770,420,1^FS\r\n" +
            "^FO610,114,0^GB180,175,1^FS\r\n" +
            "^FO20,730,0^GB770,460,1^FS\r\n" +
            "^FO676,390,0^GB114,50,1^FS\r\n" +
            "^FX横线^FS\r\n" +
            "^FO20,500,0^GB770,0,1^FS\r\n" +
            "^FO20,535,0^GB240,0,1^FS\r\n" +
            "^FO20,625,0^GB240,0,1^FS\r\n" +
            "^FO610,625,0^GB180,0,1^FS\r\n" +
            "^FO20,835,0^GB770,0,1^FS\r\n" +
            "^FO20,1025,0^GB770,0,1^FS\r\n" +
            "^FX竖线^FS\r\n" +
            "^FO260,500,0^GB0,209,1^FS\r\n" +
            "^FO520,500,0^GB0,209,1^FS\r\n" +
            "^FO610,500,0^GB0,209,1^FS\r\n" +
            "^FO20,85^A@N,28,28^FD131146^FS\r\n" +
            "^FO120,85^A@N,18,18^FDUNITE    第33次打印  派件时间：2020-11-04 14:04:16^FS\r\n" +
            "^FX条形码^FS\r\n" +
            "^FO130,115^BY3^BCN,85,N,N,N,A^FDSF1608814805028^FS\r\n" +
            "^FT145,244^A@N,28,28^FD1/1^FS\r\n" +
            "^FT205,234^A@N,28,28^FD ^FS\r\n" +
            "^FT205,244^A@N,28,28^FD母单号 SF1 608 814 805 028^FS\r\n" +
            "^FO650,125^A@N,80,80^FD次^FS\r\n" +
            "^FO650,205^A@N,80,80^FD晨^FS\r\n" +
            "^FX目的地代码^FS\r\n" +
            "^FT30,375^A0,90,90^FD078^FS\r\n" +
            "^FO30,415^GFA,448,448,8,:Z64:eJxdkTFuhDAQRT+xBCk+0FKswhVcUiCxR+EIlCn3aBxkCw6QwiUFEvlj4yQb5O8Ho/GY+QO4c4U903lEHpgMbrUFtFKQbtJwyd4XqZEsxwHFA3Fz4JsFS1DRTSmsLJmRHh2NnbE0elJV+MOZ7M9Q/uVkvJNDqaoruTS6RQwXvxLr5/X9ZGJz+8chsXrl6IKxPSLv/VFsumfumfjOIhjVzy569THa/4LNh9iBY/vojJ/Vph11KHavvtsN+6IT9Qo/my/RrOxT9k2FoaRfX7PP2fc8B+zoX+aU5vYNk9dFHg==:5690^FS\r\n" +
            "^FO96,400^A@N,28,28^FD甄先生 134****1734 东莞托卡诺贸易有限公司^FS\r\n" +
            "^FO686,395^A0,56,56^FDCOD^FS\r\n" +
            "^FO96,438^A@N,28,28^FD广东省佛山市南海区桂城南新三路20号^FS\r\n" +
            "^FO40,510^A@N,24,24^FD寄付8.78元^FS\r\n" +
            "^FO50,543^A@N,100,100^FDA33^FS\r\n" +
            "^FO30,635^A@N,75,75^FD021WF^FS\r\n" +
            "^FO290,500^BQ,2,6^FDD03040C,LA,MMM={'k1':'','k2':'755AQ','k3':'','k4':'','k5':'608814805028','k6':'D','k7':'818e9280'}^FS\r\n" +
            "^FQ90^FO535,515^A@N,60,60,E:MHEIGB18.TTF^FY已 ^FS\r\n" +
            "^FQ90^FO535,575^A@N,60,60,E:MHEIGB18.TTF^FY验 ^FS\r\n" +
            "^FQ90^FO535,640^A@N,60,60,E:MHEIGB18.TTF^FY视 ^FS\r\n" +
            "^FO660,510^GFA,1128,1128,12,:Z64:eJzF1DESgyAQheF1KFLmCBzFo8HROIpHoLRgQlQg+5vooFWsvkJkcfchok9enghnD0c4wZkOcIRn+AVn2sMBnmpJBuXJCD/bBuWlhAOpXd24LFbbdoLyobLMb/bND9iU4n487D0dWc7sdo5dj7c9d23/5PPa7p3xyn9z/V589e7T07O+czZozpKF6+xtduqhzupqA7fZXu3qzC82LRfMyEF2vJq5SzCzycwGWNTMPu+EoG6hwxUibwlv5BE=:3eaf^FS\r\n" +
            "^FO630,630^A@N,80,80^FD ^FS\r\n" +
            "^FO400,45^A0,28,28^FD ^FS\r\n" +
            "^FX以下为附加联信息^FS\r\n" +
            "^FO30,745^GFA,448,448,8,:Z64:eJxNkT2OgzAUhAeMQmMlLcVquQLlFislR+EIKVOF7M3o9ho+AqULi7czL4Es8vhDsv1+5gHBZujrLTszeiHMWsCJStQH9fWS/kfqQOlOAKoHfAseY9ZR0qUjsIgRuAEDOuAb3DuP0mFozSzFnWPLDKkRB6TDzks7WUk15nqylVmYdoWzsifDb3K2P9nZ4+4s+HTe0Ig982TyRC4eh7W9ecG5RNSseFojuxhxPb7ZsBiR9fp5ZAei+tG7Tn2ysUF9VwVX+VBlvpZFSdW+fNp8233cfN18lu/Lvzlsc8HZivM5tz+9f1Ti:555f^FS\r\n" +
            "^FO96,740^A@N,28,28^FD韩女士 133****5892 香港葛天那中国有限公司^FS\r\n" +
            "^FO96,778^A@N,28,28^FD上海市浦东新区芬菊路194号^FS\r\n" +
            "^FO30,840^A@N,22,22^FD备注：^FS\r\n" +
            "^FO30,862^A@N,22,22^FD增值服务：优惠券7.52元；高峰期附加费20.00元^FS\r\n" +
            "^FO510,900,0^GB220,70,1^FS\r\n" +
            "^FO520,910^A@N,50,50^FD签单返还^FS\r\n" +
            "^FO30,975^A@N,22,22^FD签单返还回单号：608979636063^FS\r\n" +
            "^FO30,1000^A@N,22,22^FD计费重量：2.240KG  实际重量：7.160KG^FS\r\n" +
            "^XZ\r\n").build());
        safeWriteAndRead(_gtspl);
      }
    });
    registerBluetoothReceiver();
    checkPermissions();
    timer = new Timer();
    timer.schedule(new TimerTask() {
      @Override
      public void run() {
        //打印机断开状态自动连接
        if (!isConnected && !address.isEmpty() && !isConnecting) {
          printConnect(address);
        }
      }
    }, 1000, 1000);
  }

  private static final String[] PERMISSIONS = {
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION,
    Manifest.permission.ACCESS_LOCATION_EXTRA_COMMANDS,
    Manifest.permission.BLUETOOTH_SCAN,
    Manifest.permission.BLUETOOTH_CONNECT,
    Manifest.permission.BLUETOOTH_PRIVILEGED,
    Manifest.permission.CAMERA,
  };
  private void updateFw() {
    if (!isConnected) {
      show("未连接");
      return;
    }
    int cur_v = Integer.parseInt(curVersion.split("_")[1]);
    int new_v = Integer.parseInt(newVersion.split("_")[1]);
//    if (cur_v >= new_v) {
//      show("已经是最新版本");
//      return;
//    }
    byte[] state = safeWriteAndRead(tspl.status());
    if(state==null){
      show("打印机状态查询异常");
      return;
    }
    if(!onState(state)){
      return;
    }
    showLoading("打印机正在升级，此过程可能需要几分钟，请耐心等待......");
//    byte[] data = readResources(R.raw.fwver231227);
    byte[] data = FileChooseUtil.File2Bytes(new File(tv_file.getText().toString()));
    GenericTSPL _gtspl = tspl.raw(Raw.builder().command(data).build());
    new Thread(new Runnable() {
      @Override
      public void run() {
        safeWriteAndRead(_gtspl);
        dismissLoading();
      }
    }).start();
  }
  private void checkPermissions() {
    int permission1 = ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA);
    if (permission1 != PackageManager.PERMISSION_GRANTED) {
      // We don't have permission so prompt the user
      ActivityCompat.requestPermissions(
        this,
        PERMISSIONS,
        1
      );
    }
  }

  private void showLoading(String message) {
    if (message == null) return;
    loading = ProgressDialog.show(this, "", message, true);
  }

  private void dismissLoading() {
    if (loading == null) return;
    loading.dismiss();
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

  public static String formatMac(String mac, String split) {
    if (mac.length() != 12) return "";
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < 12; i++) {
      char c = mac.charAt(i);
      sb.append(c);
      if ((i & 1) == 1 && i <= 9) {
        sb.append(split);
      }
    }
    return sb.toString();
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == QRCODE_SCAN) {
      if (resultCode == Activity.RESULT_OK) {
        Bundle bundle = data.getExtras();
        String QRCodeScanResult = bundle.getString("result");
        show(QRCodeScanResult);
        address = formatMac(QRCodeScanResult.toUpperCase(), ":");
        if (address.length() != 17) {
          show("请扫描正确的条码");
          return;
        }
        printConnect(address);
      }
    }
    if (requestCode == FILE_CHOOSE) {
      if (resultCode == Activity.RESULT_OK) {
        Uri uri = data.getData();//得到uri，后面就是将uri转化成file的过程。
        String file_path = FileChooseUtil.getFileAbsolutePath(this, uri);
        if (file_path.contains("ALLAY")) {
          tv_file.setText(file_path);
          try {
            byte[] filebyte = FileChooseUtil.File2Bytes(new File(file_path));
            String dataString = new String(filebyte, "GB2312");
            newVersion = dataString.split(",")[0];
            String searchString = "VER_";
            // 查找指定字符串在原始字符串中的位置
            int index = newVersion.indexOf(searchString);

            // 如果找到了指定字符串
            if (index != -1) {
              // 截取从指定字符串位置开始到末尾的部分
              newVersion = newVersion.substring(index+searchString.length());
            }
            tv_new_ver.setText("最新固件版本："+newVersion);
            if(!curVersion.isEmpty()){
              int cur_v = Integer.parseInt(curVersion.split("_")[1]);
              int new_v = Integer.parseInt(newVersion.split("_")[1]);
              if (cur_v < new_v) {
                showDialog("检测到新固件版本，是否更新");
              }
            }
          } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
          }
        } else {
          show("文件类型有误");
        }
      }else {
        show("未选择文件");
      }
    }
  }

  /**
   * 打印机连接
   */
  private void printConnect(String printMac) {
    Bluetooth.getInstance().initialize(getApplication());
    BluetoothDevice device;
    device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(printMac);
    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        isConnected = true;
        tspl = TSPL.generic(connectedDevice);
        runOnUiThread(new Runnable() {
          @Override
          public void run() {
            isConnecting = false;
            tv_connect_status.setText(device.getName() + "连接成功");
          }
        });
        GenericTSPL _gtspl = tspl.version();
        byte[] curVersionData = safeWriteAndRead(_gtspl);
        if(curVersionData==null){
          runOnUiThread(new Runnable() {
            @Override
            public void run() {
              tv_cur_ver.setText("当前固件版本：查询失败");
            }
          });
        }
        try {
          curVersion = new String(curVersionData, "GB2312");
        } catch (UnsupportedEncodingException e) {
          throw new RuntimeException(e);
        }
        runOnUiThread(new Runnable() {
          @Override
          public void run() {
            tv_cur_ver.setText("当前固件版本：" + curVersion);
            if(!newVersion.isEmpty()){
              int cur_v = Integer.parseInt(curVersion.split("_")[1]);
              int new_v = Integer.parseInt(newVersion.split("_")[1]);
              if (cur_v < new_v) {
                showDialog("检测到新固件版本，是否更新");
              }
            }
          }
        });
      }

      @Override
      public void onConnectFail(String errMsg, Throwable e) {
        isConnected = false;
        runOnUiThread(new Runnable() {
          @Override
          public void run() {
            isConnecting = false;
//            tv_connect_status.setText(device.getName() + "连接失败");
          }
        });
      }

      @Override
      public void onConnectionStateChanged(BluetoothDevice device, int state) {
      }
    });
    new Thread(new Runnable() {
      @Override
      public void run() {
        isConnecting = true;
        connection.connect(null);
      }
    }).start();
  }

  // 注册广播接收器
  private void registerBluetoothReceiver() {
    IntentFilter intentFilter = new IntentFilter();
    intentFilter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
    intentFilter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
    registerReceiver(bluetoothReceiver, intentFilter);
  }

  // 蓝牙状态广播接收器
  public class BluetoothReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
        isConnected = true;
      } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
        isConnected = false;
        tv_connect_status.setText("未连接");
      }
    }
  }

  private byte[] safeWriteAndRead(PSDK psdk) {
    try {
      WroteReporter reporter = psdk.write(WriteOptions.builder().enableChunkWrite(false).build());
      if (!reporter.isOk()) {
        throw new IOException("写入数据失败", reporter.getException());
      }
      Thread.sleep(200);
      return psdk.read(ReadOptions.builder().timeout(2000).build());
    } catch (Exception e) {
      return null;
    }
  }

  private boolean onState(byte[] bytes) {
    if (bytes.length == 1) {
      if ((bytes[0] & 0x20) == 0x20) {
        Log.e("状态：", "打印机打印中");
        show("打印机打印中");
        return false;
      }
      return true;
    }
    return true;
  }
  private void show(String message) {
    if (message == null) return;
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }
  private void showDialog(String message) {
    AlertDialog.Builder builder = new AlertDialog.Builder(this);
    builder.setTitle("提示");
    builder.setMessage(message);
    builder.setNegativeButton("取消", new DialogInterface.OnClickListener() {
      @Override
      public void onClick(DialogInterface dialog, int which) {
        dialog.dismiss();
      }
    });
    builder.setPositiveButton("更新", new DialogInterface.OnClickListener() {
      @Override
      public void onClick(DialogInterface dialog, int which) {
        updateFw();
      }
    });
    AlertDialog dialog = builder.create();
    dialog.show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
