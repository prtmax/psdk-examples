package com.example.usb;


import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;


import com.printer.psdk.device.adapter.ReadOptions;
import com.printer.psdk.device.adapter.types.WroteReporter;

import com.printer.psdk.device.usb.USB;
import com.printer.psdk.device.usb.USBConnectedDevice;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.TSPL;
import com.printer.psdk.tspl.args.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;


public class MainActivity extends AppCompatActivity {
  private GenericTSPL tspl;
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
              .image(bitmap2Bytes(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
    print2.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + 2));
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
              .image(bitmap2Bytes(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
    print3.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + 3));
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
              .image(bitmap2Bytes(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
    print4.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + 4));
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
              .image(bitmap2Bytes(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
    print5.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (!isOpen) {
          showMessage("未打开USB端口");
          return;
        }
        InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + 5));
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
              .image(bitmap2Bytes(rawBitmap))
              .compress(cb_compress.isChecked())
              .build()
          )
          .print(1);
        safeWrite(_gtspl);
      }
    });
//        print.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                for (int i = 1; i < 6; i++) {
//                    InputStream is = MainActivity.this.getResources().openRawResource(getImageID("p" + i));
//                    BitmapDrawable bmpDraw = new BitmapDrawable(is);
//                    Bitmap rawBitmap = bmpDraw.getBitmap();
//                    rawBitmap = Bitmap.createScaledBitmap(rawBitmap, 800, 1200, true);
//                    GenericTSPL _gtspl = tspl.clear().page(TPage.builder().width(100).height(150).build())
//                            .direction(
//                                    TDirection.builder()
//                                            .direction(TDirection.Direction.UP_OUT)
//                                            .mirror(TDirection.Mirror.NO_MIRROR)
//                                            .build()
//                            )
//                            .gap(true)
//                            .cut(true)
//                            .cls()
//                            .image(
//                                    TImage.builder()
//                                            .x(0)
//                                            .y(0)
//                                            .image(bitmap2Bytes(rawBitmap))
//                                            .compress(true)
//                                            .build()
//                            )
//                            .print(1);
//                    String result = safeWriteAndRead(_gtspl);
//                }
//            }
//        });

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

//        print.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                if(!isOpen){
//                    showMessage("未打开USB端口");
//                    return;
//                }
//                GenericTSPL _gtspl = tspl.page(TPage.builder().width(100).height(180).build())
//                        .direction(TDirection.builder().direction(TDirection.Direction.UP_OUT).mirror(TDirection.Mirror.NO_MIRROR).build())
//                        .gap(true)
//                        .cut(true)
//                        .speed(6)
//                        .density(6)
//                        .cls()
//                        .bar(TBar.builder().x(300).y(10).width(4).height(90).build())
//                        .bar(TBar.builder().x(30).y(100).width(740).height(4).build())
//                        .bar(TBar.builder().x(30).y(880).width(740).height(4).build())
//                        .bar(TBar.builder().x(30).y(1300).width(740).height(4).build())
//                        .text(TText.builder().x(400).y(25).font(Font.TSS24).xmulti(3).ymulti(3).content("上海浦东").build())
//                        .text(TText.builder().x(30).y(120).font(Font.TSS24).xmulti(1).ymulti(1).content("发  件  人：张三 (电话 874236021)").build())
//                        .text(TText.builder().x(30).y(150).font(Font.TSS24).xmulti(1).ymulti(1).content("发件人地址：广州省 深圳市 福田区 思创路123号\"工业园\"1栋2楼").build())
//                        .text(TText.builder().x(30).y(200).font(Font.TSS24).xmulti(1).ymulti(1).content("收  件  人：李四 (电话 13899658435)").build())
//                        .text(TText.builder().x(30).y(230).font(Font.TSS24).xmulti(1).ymulti(1).content("收件人地址：上海市 浦东区 太仓路司务小区9栋1105室").build())
//                        .text(TText.builder().x(30).y(700).font(Font.TSS16).xmulti(1).ymulti(1).content("各類郵件禁寄、限寄的範圍，除上述規定外，還應參閱「中華人民共和國海關對").build())
//                        .text(TText.builder().x(30).y(720).font(Font.TSS16).xmulti(1).ymulti(1).content("进出口邮递物品监管办法”和国家法令有关禁止和限制邮寄物品的规定，以及邮").build())
//                        .text(TText.builder().x(30).y(740).font(Font.TSS16).xmulti(1).ymulti(1).content("寄物品的规定，以及邮电部转发的各国（地区）邮 政禁止和限制。").build())
//                        .text(TText.builder().x(30).y(760).font(Font.TSS16).xmulti(1).ymulti(1).content("寄件人承诺不含有法律规定的违禁物品。").build())
//                        .barcode(TBarCode.builder().x(80).y(300).codeType(CodeType.CODE_128).height(90).showType(ShowType.SHOW_CENTER).cellwidth(4).content("873456093465").build())
//                        .barcode(TBarCode.builder().x(550).y(910).codeType(CodeType.CODE_128).height(50).showType(ShowType.SHOW_CENTER).cellwidth(2).content("873456093465").build())
//                        .box(TBox.builder().startX(40).startY(500).endX(340).endY(650).width(4).radius(20).build())
//                        .text(TText.builder().x(60).y(520).font(Font.TSS24).xmulti(1).ymulti(1).content("寄件人签字：").build())
//                        .text(TText.builder().x(130).y(625).font(Font.TSS24).xmulti(1).ymulti(1).content("2015-10-30 09:09").build())
//                        .text(TText.builder().x(50).y(1000).font(Font.TSS32).xmulti(2).ymulti(3).content("广东 ---- 上海浦东").build())
//                        .circle(TCircle.builder().x(670).y(1170).width(6).radius(100).build())
//                        .text(TText.builder().x(670).y(1170).font(Font.TSS24).xmulti(3).ymulti(3).content("碎").build())
//                        .qrcode(TQRCode.builder().x(620).y(620).correctLevel(CorrectLevel.H).cellWidth(4).content("www.qrprt.com   www.qrprt.com   www.qrprt.com").build())
//                        .print(1);
//                safeWrite(_gtspl);
//            }
//        });
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
          switch_Usb.setText("关闭USB");
          isOpen = true;
          break;
        case USB.ATTACHED:
          showMessage("监测到设备！");
          usb.openUsb();
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
  private byte[] bitmap2Bytes(Bitmap bm) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
    return baos.toByteArray();
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
