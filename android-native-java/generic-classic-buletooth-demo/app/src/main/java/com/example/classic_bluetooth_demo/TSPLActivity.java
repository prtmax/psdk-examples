package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.bluetooth.Bluetooth;
import com.printer.psdk.device.bluetooth.ConnectListener;
import com.printer.psdk.device.bluetooth.Connection;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CodeType;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;
import com.printer.psdk.tspl.mark.ShowType;
import java.io.IOException;


public class TSPLActivity extends Activity {
  private Connection connection;
  private TextView tv_connect_status;
  private EditText etMsg, etDensity;
  private Button btnText, btnDensity, btnSN, btnBitmap, btnVer, btnStatus, btnBarCode, btnQRCode, btnModel;
  private GenericTSPL tspl;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
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
    BluetoothDevice device = getIntent().getParcelableExtra("device");

    connection = Bluetooth.getInstance().createConnectionClassic(device, new ConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        tspl = TSPL.generic(connectedDevice);
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
    EditText etMsg = findViewById(R.id.etMsg);
    btnText.setOnClickListener(new View.OnClickListener() {

      @Override
      public void onClick(View v) {

        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)
              .mirror(TDirection.Mirror.NO_MIRROR)
              .build()
          )
          .gap(true)
          .cut(true)
          .cls()
          .text(TText.builder().content(etMsg.getText().toString()).x(50).y(50).build())
          .print(1);
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }

    });
    btnBitmap.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)
              .mirror(TDirection.Mirror.NO_MIRROR)
              .build()
          )
          .gap(true)
          .cut(true)
          .cls()
          .image(
            TImage.builder()
              .image(new AndroidSourceImage(bitmap))
              .compress(true)
              .build()
          )
          .print(1);
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnSN.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.sn();
        String result = safeWriteAndRead(_gtspl);
      }
    });
    btnVer.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.version();
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnStatus.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.state();
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnDensity.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.density(Integer.parseInt(etDensity.getText().toString()));
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnBarCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)
              .mirror(TDirection.Mirror.NO_MIRROR)
              .build()
          )
          .gap(true)
          .cut(true)
          .cls()
          .barcode(TBarCode.builder().content("1234556890").height(50).x(10).y(10).cellWidth(2).build())
          .print(1);
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnQRCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(100).build())
          .direction(
            TDirection.builder()
              .direction(TDirection.Direction.UP_OUT)
              .mirror(TDirection.Mirror.NO_MIRROR)
              .build()
          )
          .gap(true)
          .cut(true)
          .cls()
          .qrcode(TQRCode.builder().x(10).y(10).content("1234556890").cellWidth(4).build())
          .print(1);
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
    btnModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        //page宽高的单位是mm 下面坐标的xy单位是dot 1mm=8dot(分辨率203) 1mm=12dot(分辨率300) 开发者根据自己使用的打印机来适配
        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(180).build())
          .label()//标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
//          .bline()//黑标纸打印
//          .continuous()//连续纸打印
//          .offset(0)//进纸
//          .ribbon(false)//热敏模式
//          .shift(0)//垂直偏移
//          .reference(0, 0)//相对偏移
          .direction(TDirection.builder().direction(TDirection.Direction.UP_OUT).mirror(TDirection.Mirror.NO_MIRROR).build())
          .cut(true)
          .speed(6)
          .density(6)
          .cls()
          .bar(TBar.builder().x(300).y(10).width(4).height(90).build())
          .bar(TBar.builder().x(30).y(100).width(740).height(4).build())
          .bar(TBar.builder().x(30).y(880).width(740).height(4).build())
          .bar(TBar.builder().x(30).y(1300).width(740).height(4).build())
//          .text(TText.builder().x(400).y(25).rawFont("SIMHEI.TTF").xmulti(14).ymulti(14).content("上海浦东").build())//使用自定义矢量字体放大倍数计算方式想打多大(mm)/0.35取整，例如想打5mm字体：5/0.35=14
          .text(TText.builder().x(400).y(25).font(Font.TSS24).xmulti(2).ymulti(3).content("上海浦东").build())
          .text(TText.builder().x(30).y(120).font(Font.TSS24).xmulti(1).ymulti(1).content("发  件  人：张三 (电话 874236021)").build())
          .text(TText.builder().x(30).y(150).font(Font.TSS24).xmulti(1).ymulti(1).content("发件人地址：广州省 深圳市 福田区 思创路123号\"工业园\"1栋2楼").build())
          .text(TText.builder().x(30).y(200).font(Font.TSS24).xmulti(1).ymulti(1).content("收  件  人：李四 (电话 13899658435)").build())
          .text(TText.builder().x(30).y(230).font(Font.TSS24).xmulti(1).ymulti(1).content("收件人地址：上海市 浦东区 太仓路司务小区9栋1105室").build())
          .text(TText.builder().x(30).y(700).font(Font.TSS16).xmulti(1).ymulti(1).content("各類郵件禁寄、限寄的範圍，除上述規定外，還應參閱「中華人民共和國海關對").build())
          .text(TText.builder().x(30).y(720).font(Font.TSS16).xmulti(1).ymulti(1).content("进出口邮递物品监管办法”和国家法令有关禁止和限制邮寄物品的规定，以及邮").build())
          .text(TText.builder().x(30).y(740).font(Font.TSS16).xmulti(1).ymulti(1).content("寄物品的规定，以及邮电部转发的各国（地区）邮 政禁止和限制。").build())
          .text(TText.builder().x(30).y(760).font(Font.TSS16).xmulti(1).ymulti(1).content("寄件人承诺不含有法律规定的违禁物品。").build())
          .barcode(TBarCode.builder().x(80).y(300).codeType(CodeType.CODE_128).height(90).showType(ShowType.SHOW_CENTER).cellWidth(4).content("873456093465").build())
          .barcode(TBarCode.builder().x(550).y(910).codeType(CodeType.CODE_128).height(50).showType(ShowType.SHOW_CENTER).cellWidth(2).content("873456093465").build())
          .box(TBox.builder().startX(40).startY(500).endX(340).endY(650).width(4).radius(20).build())
          .text(TText.builder().x(60).y(520).font(Font.TSS24).xmulti(1).ymulti(1).content("寄件人签字：").build())
          .text(TText.builder().x(130).y(625).font(Font.TSS24).xmulti(1).ymulti(1).content("2015-10-30 09:09").build())
          .text(TText.builder().x(50).y(1000).font(Font.TSS32).xmulti(2).ymulti(3).content("广东 ---- 上海浦东").build())
          .circle(TCircle.builder().x(670).y(1170).width(6).radius(100).build())
          .text(TText.builder().x(670).y(1170).font(Font.TSS24).xmulti(3).ymulti(3).content("碎").build())
          .qrcode(TQRCode.builder().x(620).y(620).correctLevel(CorrectLevel.H).cellWidth(4).content("www.qrprt.com   www.qrprt.com   www.qrprt.com").build())
          .print(1);
        String result = safeWriteAndRead(_gtspl);
        show(result);
      }
    });
  }


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

  private void show(String message) {
    if(message==null) return;
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    connection.disconnect();
  }

}
