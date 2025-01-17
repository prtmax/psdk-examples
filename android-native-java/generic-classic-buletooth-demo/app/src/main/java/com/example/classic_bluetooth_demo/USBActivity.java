package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.*;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.cpcl.mark.CodeRotation;
import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.args.*;
import com.printer.psdk.tspl.mark.CodeType;
import com.printer.psdk.tspl.mark.CorrectLevel;
import com.printer.psdk.tspl.mark.Font;
import com.printer.psdk.tspl.mark.ShowType;

import java.io.IOException;
import java.io.InputStream;


public class USBActivity extends Activity {
  private USB usb;
  private Button switch_Usb;
  private Button printImage;
  private Button printModel;
  private Button printPdf;
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
    setContentView(R.layout.activity_usb);
    switch_Usb = (Button) findViewById(R.id.switch_usb);
    printImage = (Button) findViewById(R.id.printImage);
    printModel = (Button) findViewById(R.id.printModel);
    printPdf = (Button) findViewById(R.id.printPdf);
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
            PrintUtil.getInstance().init(usbConnectedDevice);
            switch_Usb.setText("关闭USB");
            isOpen = true;
          } else {
            showMessage("打开失败，检查是否有可用的USB端口");
          }

        }
      }

    });
    printPdf.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        Intent intent = new Intent(USBActivity.this, PDFActivity.class);
        startActivity(intent);
      }
    });
    printImage.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        imageTest(1);
      }
    });
    printModel.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        if (curCmd.equals("tspl")) {
          GenericTSPL _gtspl = PrintUtil.getInstance().tspl().clear().page(TPage.builder().width(100).height(150).build())
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
          safeWrite(_gtspl);
        } else {
          GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().clear().page(CPage.builder().width(608).height(1040).copies(1).build())
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

    status_btn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        GenericTSPL _gtspl = PrintUtil.getInstance().tspl().clear().state();
        String result = safeWriteAndRead(_gtspl);
        showMessage(result);
      }
    });

  }
  @Override
  protected void onResume() {
    super.onResume();
    if(!isOpen){
      USBConnectedDevice usbConnectedDevice = usb.openUsb();
      if (usbConnectedDevice != null) {
        PrintUtil.getInstance().init(usbConnectedDevice);
        switch_Usb.setText("关闭USB");
        isOpen = true;
      }
    }
  }
  public void imageTest(int i) {
    InputStream is = USBActivity.this.getResources().openRawResource(getImageID("p" + i));
    BitmapDrawable bmpDraw = new BitmapDrawable(is);
    Bitmap rawBitmap = bmpDraw.getBitmap();
    rawBitmap = Bitmap.createScaledBitmap(rawBitmap, 800, 1200, true);
    if (curCmd.equals("tspl")) {
      GenericTSPL _gtspl = PrintUtil.getInstance().tspl().clear().page(TPage.builder().width(100).height(150).build())
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
            .x(0)
            .y(0)
            .image(new AndroidSourceImage(rawBitmap))
            .compress(cb_compress.isChecked())
            .build()
        )
        .print(1);
      safeWrite(_gtspl);
    } else {
      GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().clear().page(CPage.builder().width(608).height(1040).build())
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
            PrintUtil.getInstance().init(usbConnectedDevice);
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
