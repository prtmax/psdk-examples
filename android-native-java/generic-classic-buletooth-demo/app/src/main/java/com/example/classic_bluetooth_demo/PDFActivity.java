package com.example.classic_bluetooth_demo;


import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.View;
import android.widget.*;
import androidx.viewpager.widget.ViewPager;
import com.example.classic_bluetooth_demo.util.FileChooseUtil;
import com.example.classic_bluetooth_demo.util.ImagePagerAdapter;
import com.example.classic_bluetooth_demo.util.PdfUtil;
import com.example.classic_bluetooth_demo.util.PrintUtil;
import com.printer.psdk.cpcl.GenericCPCL;
import com.printer.psdk.cpcl.args.*;
import com.printer.psdk.device.adapter.types.WroteReporter;
import com.printer.psdk.esc.GenericESC;
import com.printer.psdk.esc.args.EImage;
import com.printer.psdk.frame.father.PSDK;
import com.printer.psdk.imagep.android.AndroidSourceImage;
import com.printer.psdk.tspl.GenericTSPL;
import com.printer.psdk.tspl.args.*;

import java.io.IOException;


public class PDFActivity extends Activity {
  private Button bt_choose_pdf, bt_choose_image, bt_print_pdf;
  private RadioButton rb_label, rb_continue, rb_black_label;
  private CheckBox cb_compress;
  private CheckBox cb_cut;
  private EditText et_width, et_height;
  private TextView tv_pdf;
  private ViewPager viewPager;
  private String curCmd = "tspl";
  private Bitmap[] bitmaps;

  private static final int PICK_IMAGE = 1;
  private static final int PICK_PDF = 2;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_pdf);
    et_width = findViewById(R.id.et_width);
    et_height = findViewById(R.id.et_height);
    viewPager = findViewById(R.id.viewPager);
    tv_pdf = findViewById(R.id.tv_pdf);
    bt_choose_pdf = findViewById(R.id.bt_choose_pdf);
    bt_choose_image = findViewById(R.id.bt_choose_image);
    bt_print_pdf = findViewById(R.id.bt_print_pdf);
    cb_compress = findViewById(R.id.cb_compress);
    cb_cut = findViewById(R.id.cb_cut);
    rb_label = findViewById(R.id.rb_label);
    rb_continue = findViewById(R.id.rb_continue);
    rb_black_label = findViewById(R.id.rb_black_label);
    RadioGroup radioGroup = findViewById(R.id.radioGroup);
    radioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
      @Override
      public void onCheckedChanged(RadioGroup group, int checkedId) {
        RadioButton radioButton = findViewById(checkedId);
        curCmd = radioButton.getText().toString();
      }
    });
    bt_choose_pdf.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");//设置类型，这里是任意类型，任意后缀的可以这样写。
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, PICK_PDF);
      }
    });
    bt_choose_image.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");
        startActivityForResult(intent, PICK_IMAGE);
      }
    });
    bt_print_pdf.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (bitmaps == null) {
          showMessage("未选择PDF");
          return;
        }
        for (Bitmap bitmap : bitmaps) {
          imageTest(bitmap);
        }
      }
    });

  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (resultCode == Activity.RESULT_OK) {//是否选择，没选择就不会继续
      Uri uri = data.getData();//得到uri，后面就是将uri转化成file的过程。
      String file_path = FileChooseUtil.getFileAbsolutePath(this, uri);
      switch (requestCode) {
        case PICK_PDF:
          if (!file_path.toLowerCase().contains("pdf")) {
            showMessage("请选择后缀为pdf文件");
            return;
          }
          PdfUtil.showLoading(this, "加载中。。。");
          new Thread(() -> {
            bitmaps = PdfUtil.openFile(Uri.decode(file_path));
            if (bitmaps != null) {
              runOnUiThread(() -> {
                tv_pdf.setText(file_path);
                ImagePagerAdapter adapter = new ImagePagerAdapter(PDFActivity.this, bitmaps);
                viewPager.setAdapter(adapter);
                PdfUtil.dismissLoading();
              });
            }
          }).start();
          break;
        case PICK_IMAGE:
          try {
            Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), uri);
            if (bitmap != null) {
              runOnUiThread(() -> {
                bitmaps = new Bitmap[1];
                bitmaps[0] = bitmap;
                tv_pdf.setText(file_path);
                ImagePagerAdapter adapter = new ImagePagerAdapter(PDFActivity.this, bitmaps);
                viewPager.setAdapter(adapter);
                PdfUtil.dismissLoading();
              });
            }
          } catch (IOException e) {
            e.printStackTrace();
          }
          break;
      }
    } else {
      showMessage("未选择文件");
    }
  }

  @Override
  protected void onResume() {
    super.onResume();
  }

  public void imageTest(Bitmap rawBitmap) {
    if (et_width.getText().toString().isEmpty() || et_height.getText().toString().isEmpty()) {
      showMessage("纸张宽高不能为空");
      return;
    }
    int pageWidth = Integer.parseInt(et_width.getText().toString());
    int pageHeight = Integer.parseInt(et_height.getText().toString());

    // 目标宽度
    int targetWidth = pageWidth * 8;

    // 获取原始 Bitmap 的宽度和高度
    int originalWidth = rawBitmap.getWidth();
    int originalHeight = rawBitmap.getHeight();

    // 计算新的高度，保持纵横比
    int targetHeight = (int) ((float) originalHeight * targetWidth / originalWidth);

    // 按宽度和计算出的高度进行缩放
    rawBitmap = Bitmap.createScaledBitmap(rawBitmap, targetWidth, targetHeight, true);

    pageHeight = targetHeight / 8;

//    rawBitmap = Bitmap.createScaledBitmap(rawBitmap, pageWidth * 8, pageHeight * 8, true);
    if (curCmd.equals("tspl")) {
      GenericTSPL _gtspl = PrintUtil.getInstance().tspl().clear().page(TPage.builder().width(pageWidth).height(pageHeight).build());//单位是mm 200dpi:1mm=8dot 300dpi:1mm=12dot
      if (rb_label.isChecked()) {
        _gtspl.label();
      } else if (rb_continue.isChecked()) {
        _gtspl.continuous();
      } else if (rb_black_label.isChecked()) {
        _gtspl.bline();
      }
      //注释的为热转印机器指令
//                        .label()//标签纸打印 三种纸调用的时候根据打印机实际纸张选一种就可以了
//                        .bline()//黑标纸打印
//                        .continuous()//连续纸打印
//                        .offset(0)//进纸
//                        .ribbon(false)//热敏模式
//                        .shift(0)//垂直偏移
//                        .reference(0,0)//相对偏移
      _gtspl.direction(
          TDirection.builder()
            .direction(TDirection.Direction.UP_OUT)
            .mirror(TDirection.Mirror.NO_MIRROR)
            .build()
        )
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
    } else if (curCmd.equals("cpcl")) {
      GenericCPCL _gcpcl = PrintUtil.getInstance().cpcl().page(CPage.builder().width(pageWidth * 8).height(pageHeight * 8).build())//单位是dot 1mm=8dot
        .image(CImage.builder()
          .image(new AndroidSourceImage(rawBitmap))
          .compress(cb_compress.isChecked())
          .build()
        );
      if (!rb_continue.isChecked()) {//不是连续纸都要发定位指令
        _gcpcl.form();
      }
      _gcpcl.print(CPrint.builder().build());
      safeWrite(_gcpcl);
    } else {
      GenericESC _gesc = PrintUtil.getInstance().esc()
        .image(EImage.builder()
          .image(new AndroidSourceImage(rawBitmap))
          .compress(cb_compress.isChecked())
          .build())
        .lineDot(250);
      if (!rb_continue.isChecked()) {//不是连续纸都要发定位指令
        _gesc.position();
      }
      safeWrite(_gesc);
    }
  }

  private void safeWrite(PSDK psdk) {
    try {
      WroteReporter reporter = psdk.write();
      if (!reporter.isOk()) {
        throw new IOException("写入数据失败", reporter.getException());
      }
      showMessage("发送成功");
    } catch (Exception e) {
      e.printStackTrace();
      showMessage("发送失败,请尝试重新连接");
    }
  }

  private void showMessage(String s) {
    Toast.makeText(this, s, Toast.LENGTH_SHORT).show();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
  }

}
