package com.example.usb;


import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import com.print.psdk.CmdConvert;
import com.printer.psdk.cpcl.CPCL;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.CodeRotation;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;

import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.frame.father.args.common.Raw;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CodeType;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;
import com.printer.psdk.tspl.mark.ShowType;

import java.io.IOException;
import java.io.InputStream;


public class MainActivity extends AppCompatActivity {
  private GenericTSPL tspl;
  private GenericCPCL cpcl;
  private USB usb;
  private Button switch_Usb;
  private Button print1;
  private Button print2;
  private Button print3;
  private Button print4;
  private Button print5;
  private Button status_btn;
  private CheckBox cb_compress;
  private CheckBox cb_cut;
  private CheckBox cb_position;
  private Handler myHandler = new MyHandler();
  private boolean isOpen = false;
  private String curCmd = "tspl";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    switch_Usb = (Button) findViewById(R.id.switch_usb);
    print1 = (Button) findViewById(R.id.print1);
    print2 = (Button) findViewById(R.id.print2);
    print3 = (Button) findViewById(R.id.print3);
    print4 = (Button) findViewById(R.id.print4);
    print5 = (Button) findViewById(R.id.print5);
    status_btn = (Button) findViewById(R.id.status);
    cb_compress = (CheckBox) findViewById(R.id.cb_compress);
    cb_cut = (CheckBox) findViewById(R.id.cb_cut);
    cb_position = (CheckBox) findViewById(R.id.cb_position);
    usb = new USB(this, myHandler);
    usb.register_USB();

    RadioGroup radioGroup = findViewById(R.id.radioGroup);
    radioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(RadioGroup group, int checkedId) {
        RadioButton radioButton = findViewById(checkedId);
        curCmd = radioButton.getText().toString();
      }
    });
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
            tspl = TSPL.generic(usbConnectedDevice);
            cpcl = CPCL.generic(usbConnectedDevice);
            switch_Usb.setText("关闭USB");
            isOpen = true;
          } else {
            showMessage("打开失败，检查是否有可用的USB端口");
          }

        }
      }

    });
    print1.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        String text = "! 0 200 200 988 1\r\nPAGE-WIDTH 577\r\nLEFT\r\nRIGHT\r\nSETBOLD 1\r\nSETMAG 3 3\r\nTEXT 24 0 0 7 T801\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 0\r\nTEXT 55 0 15 57 客服热线 95338\r\nLEFT\r\nSETBOLD 0\r\nTEXT 55 0 15 79 已验视\r\nLEFT\r\nSETBOLD 0\r\nTEXT 55 0 152 79 SCP-CMD-sbox 1 2024-11-15 \"17\":05:02\r\nLEFT\r\nSETBOLD 0\r\nTEXT 55 0 410 79 顺丰特快\r\nLEFT\r\nB 128 2 2 98 46 108 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 2 2\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 1\r\nSETMAG 1 1\r\nTEXT 24 0 22 208 运单号 SF 744 449 183 0026\r\nSETMAG 1 1\r\nLEFT\r\nLINE 15 266 569 266 1\r\nLEFT\r\nLINE 15 332 569 332 1\r\nLEFT\r\nLINE 15 403 569 403 1\r\nLEFT\r\nLINE 15 619 569 619 1\r\nLEFT\r\nLINE 15 266 15 759 1\r\nLEFT\r\nLINE 569 266 569 759 1\r\nLEFT\r\nLINE 335 403 335 619 1\r\nLEFT\r\nLINE 15 756 569 756 1\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 4 4\r\nTEXT 55 0 19 262 020RD-B0-NKAL-012B\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 3 3\r\nTEXT 55 0 22 331 012\r\nSETMAG 1 1\r\nLEFT\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 4 4\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 1\r\nSETMAG 3 3\r\nTEXT 55 0 22 410 收\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 2 2\r\nTEXT 55 0 83 406 小邱 \r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 0\r\nSETMAG 2 2\r\nTEXT 55 0 83 442 1*6057\r\nSETMAG 1 1\r\nLEFT\r\nSETBOLD 0\r\nTEXT 24 0 22 471 顺丰速运\r\nLEFT\r\nSETBOLD 0\r\nTEXT 24 0 22 504 广东省广州市白云区湖北大厦\r\nLEFT\r\nSETBOLD 0\r\nLEFT\r\nB QR 345 410 M 2 U 5\nMA,MMM={'k1':'020RD','k2':'020NKAL','k3':'012','k4':'T801','k5':'SF7444491830026','k6':'','k7':'a80e3df2'}\nENDQR\r\nLEFT\r\nSETBOLD 0\r\nTEXT 55 0 22 622 寄 小* 4*9888 广东省深圳市南山区软件产业基地11栋\r\nLEFT\r\nSETBOLD 1\r\nSETMAG 6 5\r\nTEXT 55 0 19 662 R2\r\nSETMAG 1 1\r\nLEFT\r\nLEFT\r\nLEFT\r\nLEFT\r\nSETBOLD 0\r\nTEXT270 55 0 19 93 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nTEXT270 55 0 19 345 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nTEXT270 55 0 19 604 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nTEXT90 55 0 554 222 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nTEXT90 55 0 554 733 SF7444491830026\r\nLEFT\r\nSETBOLD 0\r\nGAP-SENSE\r\nFORM\r\nPRINT\r\n";
        try {
          CmdConvert convertc = new CmdConvert();
         byte[] value = convertc.cpcltotspl(text);
         tspl.clear().raw(Raw.builder().command(value).build()).write();
        } catch (Exception e) {
          showMessage(e.getMessage());
          throw new RuntimeException(e);
        }
      }
    });
//    print2.setOnClickListener(new View.OnClickListener() {
//      @Override
//      public void onClick(View v) {
//        if (!isOpen) {
//          showMessage("未打开USB端口");
//          return;
//        }
//        imageTest(2);
//      }
//    });
    print3.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        imageTest(3);
      }
    });
    print4.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        imageTest(4);
      }
    });
    print5.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        imageTest(5);
      }
    });

    status_btn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        GenericTSPL _gtspl = tspl.state();
        String result = safeWriteAndRead(_gtspl);
        showMessage(result);
      }
    });

    print2.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        if (curCmd.equals("tspl")) {
          GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(150).build())
            .direction(TDirection.builder().direction(TDirection.Direction.UP_OUT).mirror(TDirection.Mirror.NO_MIRROR).build())
            .gap(cb_position.isChecked())
            .cut(cb_cut.isChecked())
            .speed(6)
            .density(6)
            .cls()
            .bar(TBar.builder().x(300).y(10).width(4).height(90).build())
            .bar(TBar.builder().x(30).y(100).width(740).height(4).build())
            .bar(TBar.builder().x(30).y(880).width(740).height(4).build())
            .bar(TBar.builder().x(30).y(1300).width(740).height(4).build())
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
          safeWrite(_gtspl);
        } else {
          GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1040).copies(1).build())
            .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(664).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(88).endX(598).endY(88).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(88 + 128).endX(598).endY(88 + 128).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(88 + 128 + 80).endX(598).endY(88 + 128 + 80).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(88 + 128 + 80 + 144 + 128).endX(598 - 56 - 16).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
            .line(CLine.builder().startX(52).startY(88 + 128 + 80).endX(52).endY(88 + 128 + 80 + 144 + 128).lineWidth(2).build())
            .line(CLine.builder().startX(598 - 56 - 16).startY(88 + 128 + 80).endX(598 - 56 - 16).endY(664).lineWidth(2).build())
            .bar(CBar.builder().x(120).y(88 + 12).lineWidth(1).height(80).content("1234567890").codeType(com.printer.psdk.cpcl.mark.CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
            .text(CText.builder().textX(120 + 12).textY(88 + 20 + 76).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("1234567890").build())
            .text(CText.builder().textX(12).textY(88 + 128 + 80 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("收").build())
            .text(CText.builder().textX(12).textY(88 + 128 + 80 + 96).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
            .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("发").build())
            .text(CText.builder().textX(12).textY(88 + 128 + 80 + 144 + 80).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
            .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 128 + 16).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("签收人/签收时间").build())
            .text(CText.builder().textX(430).textY(88 + 128 + 80 + 144 + 128 + 36).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("月").build())
            .text(CText.builder().textX(490).textY(88 + 128 + 80 + 144 + 128 + 36).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("日").build())
            .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("收姓名" + " " + "13777777777").build())
            .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 24 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
            .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("名字" + " " + "13777777777").build())
            .text(CText.builder().textX(52 + 20).textY(88 + 128 + 80 + 144 + 24 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 104).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("派").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 160).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(88 + 128 + 80 + 208).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("联").build())
            .box(CBox.builder().topLeftX(0).topLeftY(1).bottomRightX(598).bottomRightY(968).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(696 + 80).endX(598).endY(696 + 80).lineWidth(2).build())
            .line(CLine.builder().startX(0).startY(696 + 80 + 136).endX(598 - 56 - 16).endY(696 + 80 + 136).lineWidth(2).build())
            .line(CLine.builder().startX(52).startY(80).endX(52).endY(696 + 80 + 136).lineWidth(2).build())
            .line(CLine.builder().startX(598 - 56 - 16).startY(80).endX(598 - 56 - 16).endY(968).lineWidth(2).build())
            .bar(CBar.builder().x(320).y(696 - 4).lineWidth(1).height(56).content("1234567890").codeType(com.printer.psdk.cpcl.mark.CodeType.CODE128).codeRotation(CodeRotation.ROTATION_0).build())
            .text(CText.builder().textX(320 + 8).textY(696 + 54).font(com.printer.psdk.cpcl.mark.Font.TSS16).content("1234567890").build())
            .text(CText.builder().textX(12).textY(696 + 80 + 35).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("发").build())
            .text(CText.builder().textX(12).textY(696 + 80 + 84).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("件").build())
            .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("名字" + " " + "13777777777").build())
            .text(CText.builder().textX(52 + 20).textY(696 + 80 + 28 + 32).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("南京市浦口区威尼斯水城七街区七街区").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 50).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("客").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 82).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("户").build())
            .text(CText.builder().textX(598 - 56 - 5).textY(696 + 80 + 106).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("联").build())
            .text(CText.builder().textX(12 + 8).textY(696 + 80 + 136 + 22 - 5).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("物品：" + "几个快递" + " " + "12kg").build())
            .box(CBox.builder().topLeftX(598 - 56 - 16 - 120).topLeftY(696 + 80 + 136 + 11).bottomRightX(598 - 56 - 16 - 16).bottomRightY(968 - 11).lineWidth(2).build())
            .text(CText.builder().textX(598 - 56 - 16 - 120 + 17).textY(696 + 80 + 136 + 11 + 6).font(com.printer.psdk.cpcl.mark.Font.TSS24).content("已验视").build());
          if (cb_position.isChecked()) {
            _gcpcl.form();
          }
          _gcpcl.print(CPrint.builder().build());
          safeWrite(_gcpcl);
        }

      }
    });
  }
  @Override
  protected void onResume() {
    super.onResume();
    if(!isOpen){
      USBConnectedDevice usbConnectedDevice = usb.openUsb();
      if (usbConnectedDevice != null) {
        tspl = TSPL.generic(usbConnectedDevice);
        cpcl = CPCL.generic(usbConnectedDevice);
        switch_Usb.setText("关闭USB");
        isOpen = true;
      }
    }
  }
  public void imageTest(int i) {
    InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + i));
    BitmapDrawable bmpDraw = new BitmapDrawable(is);
    Bitmap rawBitmap = bmpDraw.getBitmap();
    rawBitmap = Bitmap.createScaledBitmap(rawBitmap, 540, 360, true);
    if (curCmd.equals("tspl")) {
      GenericTSPL _gtspl = tspl.clear().page(TPage.builder().width(68).height(45).build())//单位是mm 1mm=8dot
        //注释的为热转印机器指令
//                        .label()//标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
//                        .bline()//黑标纸打印
//                        .continuous()//连续纸打印
//                        .offset(0)//进纸
//                        .ribbon(false)//热敏模式
//                        .shift(0)//垂直偏移
//                        .reference(0,0)//相对偏移
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
            .image(new AndroidSourceImage(rawBitmap))
            .compress(cb_compress.isChecked())
            .build()
        )
        .print(1);
      safeWrite(_gtspl);
    } else {
      GenericCPCL _gcpcl = cpcl.page(CPage.builder().width(608).height(1040).build())//单位是dot 1mm=8dot
        .image(CImage.builder()
          .image(new AndroidSourceImage(rawBitmap))
          .compress(cb_compress.isChecked())
          .build()
        );
      if (cb_position.isChecked()) {
        _gcpcl.form();
      }
      _gcpcl.print(CPrint.builder().build());
      safeWrite(_gcpcl);
    }
  }

//  public void cmdToBitmapWithPrint() {
//    try {
//      InputStream is = getResources().openRawResource(R.raw.logo);
//      BitmapDrawable bmpDraw = new BitmapDrawable(is);
//      Bitmap logoBitmap = bmpDraw.getBitmap();
//      CommandToBitmap command = new CommandToBitmap();
//      command.setPage(76 * 8, 130 * 8);
//      command.drawImage(10, 10, logoBitmap, 50, 50);
//      command.drawText(10, 80, "testtesttest", 2, true);
//      command.drawQRCode(10, 200, "testtesttest", 100, CorrectLevel.L);
//      command.drawBarCode(10, 350, 80, 150, "123456456", 0, 0);
//      AndroidSourceImage printBitmap = command.render().getBitmap();
//      GenericTSPL _gtspl = tspl.page(TPage.builder().width(76).height(130).build())
//        .direction(
//          TDirection.builder()
//            .direction(TDirection.Direction.UP_OUT)
//            .mirror(TDirection.Mirror.NO_MIRROR)
//            .build()
//        )
//        .gap(true)
//        .cut(true)
//        .cls()
//        .image(
//          TImage.builder()
//            .image(printBitmap)
//            .compress(true)
//            .build()
//        )
//        .print(1);
//      safeWrite(_gtspl);
//    } catch (Exception e) {
//      e.printStackTrace();
//    }
//  }


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
          switch_Usb.setText("关闭USB");
          isOpen = true;
          break;
        case USB.ATTACHED:
          showMessage("监测到设备！");
          USBConnectedDevice usbConnectedDevice = usb.openUsb();
          if (usbConnectedDevice != null) {
            tspl = TSPL.generic(usbConnectedDevice);
            cpcl = CPCL.generic(usbConnectedDevice);
            switch_Usb.setText("关闭USB");
            isOpen = true;
          }
          break;
        case USB.DETACHED:
          showMessage("设备已移除！");
          switch_Usb.setText("打开USB");
          isOpen = false;
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
