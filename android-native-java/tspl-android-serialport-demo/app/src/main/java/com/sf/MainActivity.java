package com.sf;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;

import com.hardware.printer.qirui.GetSerialPort;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.serialport.android.SAConnectedDevice;
import com.printer.psdk.device.serialport.android.SADevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.types.lifecycle.Lifecycle;
import com.printer.psdk.frame.logger.PLog;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CodeType;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;
import com.printer.psdk.tspl.mark.ShowType;


public class MainActivity extends Activity {

  private Button open, close, model, barCode, QRCode, getinfor, printbmp;
  private TextView tv_port;
  private GenericTSPL tspl;
  private SADevice device;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    GetSerialPort getSerialPort = new GetSerialPort();
    String port = getSerialPort.QiRui_GetCOM();
    open = (Button) findViewById(R.id.power_on);
    tv_port = findViewById(R.id.tv_port);
    tv_port.setText("当前可用串口：" + port);
    open.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        boolean open = openPort(port, 115200);
        showMessage(open ? "成功" : "失败");
      }
    });
    close = (Button) findViewById(R.id.power_off);
    close.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        boolean close = closePort();
        showMessage(close ? "成功" : "失败");
      }
    });

    printbmp = (Button) findViewById(R.id.printbmp);
    printbmp.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.raw.logo);
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
        showMessage(result);
      }
    });
    barCode = (Button) findViewById(R.id.barCode);
    barCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
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
        showMessage(result);
      }
    });
    QRCode = (Button) findViewById(R.id.QRCode);
    QRCode.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
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
        showMessage(result);
      }
    });
    model = (Button) findViewById(R.id.model);
    model.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(180).build())
          .direction(TDirection.builder().direction(TDirection.Direction.UP_OUT).mirror(TDirection.Mirror.NO_MIRROR).build())
          .gap(true)
          .cut(true)
          .speed(6)
          .density(6)
          .cls()
          .bar(TBar.builder().x(300).y(10).width(4).height(90).build())
          .bar(TBar.builder().x(30).y(100).width(740).height(4).build())
          .bar(TBar.builder().x(30).y(880).width(740).height(4).build())
          .bar(TBar.builder().x(30).y(1300).width(740).height(4).build())
          .text(TText.builder().x(400).y(25).font(Font.TSS24).xmulti(3).ymulti(3).content("上海浦东").build())
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
        showMessage(result);
      }
    });
    getinfor = (Button) findViewById(R.id.getInfor);
    getinfor.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        GenericTSPL _gtspl = tspl.version();
        String result = safeWriteAndRead(_gtspl);
        showMessage(result);

      }
    });
  }

  public boolean openPort(String portPath, int baudrate) {
    try {
      //获得串口端点名称
      device = new SADevice(portPath, baudrate);
      SAConnectedDevice connectedDevice = device.open();
      Lifecycle lifecycle = Lifecycle.builder()
        .connectedDevice(connectedDevice)
        .build();
      GenericTSPL tspl = TSPL.generic(lifecycle);
      String str = this.safeWriteAndRead(tspl.state());
      if (str != null && str.contains("READSTA")) {
        this.tspl = tspl;
        return true;
      }
    } catch (Exception e) {
      return false;
    }
    return false;
  }

  public boolean closePort() {
    try {
      device.close();
      return true;
    } catch (IOException e) {
      e.printStackTrace();
      return false;
    }
  }

  private void showMessage(String message) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
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
      PLog.error("Write data error: " + e.getMessage());
      return null;
    }
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
  }


}
