package com.printer.demo.fragments;

import static com.printer.demo.utils.ImageScaleUtils.ScaleMode.CENTER;
import static com.printer.demo.utils.ImageScaleUtils.ScaleMode.CENTER_CROP;
import static com.printer.demo.utils.ImageScaleUtils.ScaleMode.CENTER_INSIDE;
import static com.printer.demo.utils.ImageScaleUtils.ScaleMode.FIT_XY;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import com.google.android.material.tabs.TabLayout;
import com.printer.demo.ConfigPreference;
import com.printer.demo.GlobalPara;
import com.printer.demo.MainActivity;
import com.printer.demo.R;
import com.printer.demo.adapter.ItemPageAdapter;
import com.printer.demo.fragments.data.ImageTmp;
import com.printer.demo.fragments.data.TextTmp;
import com.printer.demo.utils.DefaultThreadFactory;
import com.printer.demo.utils.ImageScaleUtils;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.Printer;
import com.printer.sdk.draw.BitmapData;
import com.printer.sdk.draw.CardCanvas;
import com.printer.sdk.draw.RibbonPanel;
import com.printer.sdk.exception.OperationException;
import com.printer.sdk.operate.EjectCard;
import com.printer.sdk.operate.PrintData;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class FragmentPrint extends Fragment {

    private boolean isFirstLoad = true;
    private final TextTmp textTmp = new TextTmp();
    private final ImageTmp imageTmp = new ImageTmp();
    private ItemPageAdapter itemPageAdapter;
    private TabLayout tabLayout;
    private final CardCanvas canvas = new CardCanvas();
    private TextView tvMsg;
    private CardPrinterAPI api;
    private ExecutorService executor;
    //    private Spinner spColor;
    private Spinner imageModeSp;

    public FragmentPrint() {
        super(R.layout.fragment_print);
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        api = ((MainActivity) requireActivity()).api;
        itemPageAdapter = new ItemPageAdapter(textTmp, imageTmp, this);
    }

    @Override
    public void onResume() {
        super.onResume();
        if (isFirstLoad) {
            isFirstLoad = false;
        }
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        executor = Executors.newSingleThreadExecutor(new DefaultThreadFactory((t, e) -> showMsg(e.getMessage())));
    }

    @Override
    public void onDestroy() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException ignore) {
        }
        super.onDestroy();
    }

    private CheckBox checkboxOpencv;
    private EditText etContrast;
    private EditText etBrightness;
    private EditText etSaturation;
    private EditText etSharpening;

    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // 当视图创建完成后调用
        ViewPager viewPager = view.findViewById(R.id.view_pager);
        viewPager.setAdapter(itemPageAdapter); //设置viewPager的适配器
        tabLayout = view.findViewById(R.id.tabs);
        requireView().post(() -> tabLayout.setupWithViewPager(viewPager));

        tvMsg = view.findViewById(R.id.tv_msg);
        view.findViewById(R.id.bt_add_item).setOnClickListener(v -> addItem());
        view.findViewById(R.id.bt_print).setOnClickListener(v -> print());
        view.findViewById(R.id.bt_clear).setOnClickListener(v -> clear());
        view.findViewById(R.id.bt_add_reprint).setOnClickListener(v -> reprint());
//        spColor = view.findViewById(R.id.sp_color);
        imageModeSp = view.findViewById(R.id.sp_image_mode);
        String[] items = requireContext().getResources().getStringArray(R.array.image_mode);
        imageModeSp.setAdapter(new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_dropdown_item, items));

        // 初始化OpenCV相关UI元素
        checkboxOpencv = view.findViewById(R.id.checkbox_opencv);
        etContrast = view.findViewById(R.id.et_contrast);
        etBrightness = view.findViewById(R.id.et_brightness);
        etSaturation = view.findViewById(R.id.et_saturation);
        etSharpening = view.findViewById(R.id.et_sharpening);

        String[] item = new String[RibbonPanel.values().length];
        for (int i = 0; i < item.length; ++i) {
            item[i] = RibbonPanel.values()[i].name();
        }
//        spColor.setAdapter(new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_dropdown_item, item));
    }

    private final float[] mAngle = {0, 90, 180, 270};

    private void addItem() {
        View view = requireView(); // 获取fragment的根视图
        EditText edPosX = view.findViewById(R.id.et_x_pos); //输入X坐标的文本框
        EditText edPosY = view.findViewById(R.id.et_y_pos);
        EditText edHeight = view.findViewById(R.id.et_height);
        EditText edWidth = view.findViewById(R.id.et_width);
        int angleIndex = ((Spinner) view.findViewById(R.id.sp_angle)).getSelectedItemPosition();
        int itemPos = tabLayout.getSelectedTabPosition();
        boolean isDrawVertical = ((CheckBox) view.findViewById(R.id.cb_draw_direct)).isChecked();
        if (edPosX.getText().length() == 0) {
            tvMsg.setText(getString(R.string.x_null));
            return;
        }
        if (edPosY.getText().length() == 0) {
            tvMsg.setText(getString(R.string.y_null));
            return;
        }
        if (edWidth.getText().length() == 0) {
            tvMsg.setText(getString(R.string.width_null));
            return;
        }
        if (edHeight.getText().length() == 0) {
            tvMsg.setText(getString(R.string.height_null));
            return;
        }
        try {
            itemPageAdapter.updateCurrentItemData(itemPos);
        } catch (Exception e) {
            tvMsg.setText(e.getMessage());
            return;
        }
        if (itemPos >= 0) {
            // 在后台线程中处理耗时操作
            executor.execute(() -> {
                // 设置画布方向（垂直或水平）
                canvas.setDrawDirection(isDrawVertical ? CardCanvas.Orientation.VERTICAL : CardCanvas.Orientation.HORIZONTAL);
                RibbonPanel ribbonPanel = RibbonPanel.values()[0];
                // 解码图片文件路径为bitmap对象
                Bitmap bitmap = BitmapFactory.decodeFile(imageTmp.mPath);
                if (bitmap == null) {
                    showRet("请先添加图片", null);
                    return;
                }



                float canvasWidth = Float.parseFloat(getEditText(edWidth, "0"));
                float canvasHeight = Float.parseFloat(getEditText(edHeight, "0"));
//                float canvasWidth = 152.40f;
//                float canvasHeight = 108.37f;
                //默认画布是横排
//                if (isDrawVertical){
//                    canvasWidth=Float.parseFloat(getEditText(edHeight, "0"));
//                    canvasHeight=Float.parseFloat(getEditText(edWidth, "0"));
//                }

                int index = imageModeSp.getSelectedItemPosition();
                ImageScaleUtils.ScaleMode selectedMode = CENTER;
                BitmapData bitmapData;
                if (index == 0) {
                    bitmapData = new BitmapData(Float.parseFloat(getEditText(edPosX, "0")),
                            Float.parseFloat(getEditText(edPosY, "0")), canvasWidth, canvasHeight, bitmap);
                } else {
                    if (index == 1) {
                        selectedMode = CENTER_INSIDE;
                    } else if (index == 2) {
                        selectedMode = FIT_XY;
                    } else if (index == 3) {
                        selectedMode = CENTER_CROP;
                    }
                    android.util.Log.d("原bitmap", "bitmap参数: " + bitmap.getWidth() + " " + bitmap.getHeight());
                    ImageScaleUtils.ScaleResult result = ImageScaleUtils.calculateScale(
                            bitmap.getWidth(),
                            bitmap.getHeight(),
                            canvasWidth,
                            canvasHeight,
                            selectedMode // 传入用户选择的模式
                    );
                    // 4. 创建最终的 BitmapData（假设您的 BitmapData 构造函数需要这些参数）
                    android.util.Log.d("TAG", "addItem: " + result.x + " " + result.y + " " + result.scaledWidth + " " + result.scaledHeight);
                    bitmapData = new BitmapData(result.x, result.y, result.scaledWidth, result.scaledHeight, bitmap);
                }


                bitmapData.setRotate(mAngle[angleIndex]);
                bitmapData.setDitherMode(BitmapData.DitherMode.values()[imageTmp.mHalftone]);
                bitmapData.setThreshold(imageTmp.mThreshold);
                canvas.setRibbonPanel(bitmapData.getDitherMode() != BitmapData.DitherMode.NONE ? RibbonPanel.K : ribbonPanel);
                // 将文本数据添加到画布并显示操作结果
                String ret = canvas.addData(bitmapData);
                showRet(getString(R.string.add_image), ret);

                // 生成预览图并保存到本地
//                try {
//                    Bitmap previewBitmap = canvas.generatePreviewBitmap(ribbonPanel, (int) 1800, (int) 1280);
//                    BitmapUtils.savePNG(previewBitmap, "/storage/emulated/0/DsLog/" + System.currentTimeMillis() + ".png");
//                    showRet("预览图已保存", null);
//                } catch (Exception e) {
//                    showRet("保存预览图失败", e.getMessage());
//                }

            });
        }
    }


    private void print() {
        executor.execute(() -> {
            try {
                long l1=System.currentTimeMillis();
                if (api.isConnected()) {
                    SharedPreferences sharedPreferences = ConfigPreference.with(requireContext());
                    showRet(getString(R.string.start_print), null);
                    PrintData printData = new PrintData();
                    printData.setFrontCardCanvas(canvas);
                    printData.setHalfOffset(sharedPreferences.getInt(GlobalPara.KEY_HALF_OFFSET, 0));
                    printData.setUseCMS(sharedPreferences.getInt(GlobalPara.KEY_CMS_ENABLED, 1) == 1);


                    android.util.Log.d("TAG", "print: "+(sharedPreferences.getInt(GlobalPara.KEY_CMS_ENABLED, 0)==1));
                    if (api.getPrinterSerial() == Printer.Serial.D300Kp) {
                        printData.setYMCPrintDpi(PrintData.PrintDpi.values()[sharedPreferences.getInt(GlobalPara.KEY_LAYER_COLOR_DPI, 0)]);
                        printData.setKPrintDpi(PrintData.PrintDpi.values()[sharedPreferences.getInt(GlobalPara.KEY_LAYER_BLACK_DPI, 1)]);
                    }

                    printData.setPrnPath(sharedPreferences.getString(GlobalPara.KEY_PRN_PATH, null));
                    printData.setPrnFileCount(sharedPreferences.getInt(GlobalPara.KEY_PRN_FILE_COUNT, 10));
                    String err = api.printerOp(printData);

                    canvas.clear();


                    if (err == null) {
                        api.cardOp(new EjectCard());
                    }


                    showRet(getString(R.string.print) + " " + (err == null ? getString(R.string.success) : getString(R.string.fail)), err);
                } else {
                    showMsg(getString(R.string.connect_first));
                }
            } catch (OperationException e) {
                showRet(getString(R.string.print), String.format("%s:%s", getString(R.string.fail), e.getMessage()));
            }
        });
    }


    private void reprint() {
        View view = requireView();
        EditText edReprintCount = view.findViewById(R.id.et_reprint_count);
        float reprintCount = Float.parseFloat(getEditText(edReprintCount, "0"));
        for (int i = 0; i < reprintCount; i++) {

            final int currentIndex = i;

            executor.execute(() -> {
                try {
                    if (api.isConnected()) {
                        SharedPreferences sharedPreferences = ConfigPreference.with(requireContext());

                        showRet("循环打印", String.format("开始第%s次", currentIndex + 1));

//                        showRet(getString(R.string.start_print), null);
                        PrintData printData = new PrintData();
                        printData.setFrontCardCanvas(canvas);
                        printData.setHalfOffset(sharedPreferences.getInt(GlobalPara.KEY_HALF_OFFSET, 0));
                        printData.setUseCMS(sharedPreferences.getInt(GlobalPara.KEY_CMS_ENABLED, 0) == 1);
                        if (api.getPrinterSerial() == Printer.Serial.D300Kp) {
                            printData.setYMCPrintDpi(PrintData.PrintDpi.values()[sharedPreferences.getInt(GlobalPara.KEY_LAYER_COLOR_DPI, 0)]);
                            printData.setKPrintDpi(PrintData.PrintDpi.values()[sharedPreferences.getInt(GlobalPara.KEY_LAYER_BLACK_DPI, 1)]);
                        }
                        printData.setPrnPath(sharedPreferences.getString(GlobalPara.KEY_PRN_PATH, null));
                        printData.setPrnFileCount(sharedPreferences.getInt(GlobalPara.KEY_PRN_FILE_COUNT, 10));
                        String err = api.printerOp(printData);
                        if (err == null) {
                            api.cardOp(new EjectCard());
                        }
                        showRet(getString(R.string.print) + " " + (err == null ? getString(R.string.success) : getString(R.string.fail)), err);
                    } else {
                        showMsg(getString(R.string.connect_first));
                    }
                } catch (Exception e) {
                    showRet(getString(R.string.print), String.format("%s:%s", getString(R.string.fail), e.getMessage()));
                }
            });
        }
    }

    private void clear() {
        canvas.clear();
        showRet(getString(R.string.clear_canvas), null);
    }

    private boolean isBlack(int color) {
        return (color & 0xFFFFFF) == 0;
    }

    private void runOnUiThread(Runnable runnable) {
        requireActivity().runOnUiThread(runnable);
    }

    private void showRet(String msg, String ret) {
        runOnUiThread(() -> tvMsg.setText(String.format("%s:%s", msg, ret == null ? getString(R.string.success) : ret)));
    }

    private void showMsg(String msg) {
        runOnUiThread(() -> tvMsg.setText(msg));
    }

    private String getEditText(EditText et, String defaultValue) {
        String txt = et.getText().toString();
        return txt.isEmpty() ? defaultValue : txt;
    }


}
