package com.printer.demo.adapter;

import android.content.res.ColorStateList;
import android.os.Handler;
import android.util.SparseArray;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.PagerAdapter;

import com.printer.demo.R;
import com.printer.demo.activities.SelectFileActivity;
import com.printer.demo.fragments.data.ImageTmp;
import com.printer.demo.fragments.data.TextTmp;
import com.printer.demo.view.CustomFlag;
import com.skydoves.colorpickerview.ColorPickerDialog;
import com.skydoves.colorpickerview.listeners.ColorEnvelopeListener;

import java.util.Objects;


public class ItemPageAdapter extends PagerAdapter {

    private static String[] TAB_TITLES;
    private final TextTmp textTmp;
    private final ImageTmp imageTmp;
    private final SparseArray<View> views = new SparseArray<>(4);
    private final Fragment fragment;
    private Spinner spDither;
    private EditText etThreshold;
    private CheckBox cbKColorPrinting;
    private Button btSelectFontColor;

    public void updateCurrentItemData(int index) throws Exception {
        if (index >= 0) {
            View view = views.get(index);
//            if (index == 0) {
//                updateTextItemData(view);
//            } else {
                updateImageData(view);
//            }
        }
    }

    private void updateTextItemData(View view) throws Exception {
        EditText content = view.findViewById(R.id.et_content);
        TextView fontPath = view.findViewById(R.id.tv_font_path);
        View color = view.findViewById(R.id.bt_select_font_color);
        EditText size = view.findViewById(R.id.et_text_size);
        textTmp.fontPath = fontPath.getText().toString();
        textTmp.content = content.getText().toString();
        textTmp.fontColor = getColor(color);
        textTmp.direction = ((Spinner) view.findViewById(R.id.sp_text_direction)).getSelectedItemPosition();
        textTmp.textBold = ((CheckBox) view.findViewById(R.id.cb_text_bold)).isChecked();
        textTmp.kColorPrint = cbKColorPrinting.isChecked();
        if (size.getText().length() == 0) {
            throw new Exception(fragment.getString(R.string.font_size_null));
        } else {
            textTmp.fontSize = size.getText().toString();
        }
    }

    private void updateImageData(View view) throws Exception {
        EditText imagePath = view.findViewById(R.id.et_path);
        imageTmp.mHalftone = spDither.getSelectedItemPosition();
        imageTmp.mPath = imagePath.getText().toString();
        if (imageTmp.mHalftone < 3) return;
        if (etThreshold.getText().length() == 0) {
            throw new Exception(fragment.getString(R.string.threshold_null));
        } else {
            imageTmp.mThreshold = Integer.parseInt(etThreshold.getText().toString());
        }
    }

    public ItemPageAdapter(TextTmp textTmp, ImageTmp imageTmp, Fragment fragment) {
        this.textTmp = textTmp;
        this.imageTmp = imageTmp;
        this.fragment = fragment;
//        new Handler().post(() -> TAB_TITLES = new String[]{this.fragment.getString(R.string.text),
//                                                           this.fragment.getString(R.string.image)});
        new Handler().post(() -> TAB_TITLES = new String[]{this.fragment.getString(R.string.image)});
    }

    @Nullable
    @Override
    public CharSequence getPageTitle(int position) {
        return TAB_TITLES[position];
    }

    @Override
    public int getCount() {
        return 1;
    }

    @Override
    public boolean isViewFromObject(@NonNull View view, @NonNull Object object) {
        return view == object;
    }

    @NonNull
    @Override
    public Object instantiateItem(@NonNull ViewGroup container, int position) {
        View view = views.get(position);
        if (view == null) {
            LayoutInflater layoutInflater = LayoutInflater.from(container.getContext());
//            if (position == 0) {
//                view = layoutInflater.inflate(R.layout.item_text, container, false);
//                btSelectFontColor = view.findViewById(R.id.bt_select_font_color);
//                btSelectFontColor.setOnClickListener(v -> selectColor(btSelectFontColor));
//                TextView textView = view.findViewById(R.id.tv_font_path);
//                view.findViewById(R.id.bt_pick_font).setOnClickListener(v -> selectFile(1, textView));
//                cbKColorPrinting = view.findViewById(R.id.cb_k_black);
//                cbKColorPrinting.setOnCheckedChangeListener((buttonView, isChecked) -> btSelectFontColor.setEnabled(!isChecked));
//            } else {
                view = layoutInflater.inflate(R.layout.item_image, container, false);
                EditText editText = view.findViewById(R.id.et_path);
                view.findViewById(R.id.bt_select_pic).setOnClickListener(v -> selectFile(0, editText));
                etThreshold = view.findViewById(R.id.et_threshold);
                spDither = view.findViewById(R.id.sp_dither);
                spDither.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                    @Override
                    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                        etThreshold.setEnabled(position == 3);
                    }

                    @Override
                    public void onNothingSelected(AdapterView<?> parent) {}
                });
//            }
            views.put(position, view);
        }
        container.addView(view);
        return view;
    }

    @Override
    public void destroyItem(@NonNull ViewGroup container, int position, @NonNull Object object) {
        container.removeView((View) object);
    }

    private void selectColor(View view) {
        ColorPickerDialog.Builder builder = new ColorPickerDialog.Builder(fragment.requireContext())
                .setPreferenceName("ColorPickerDialog")
                .setPositiveButton("Ok", (ColorEnvelopeListener) (envelope, fromUser) -> {
                    view.setBackgroundTintList(ColorStateList.valueOf(envelope.getColor()));
                })
                .setNegativeButton("Cancel", (dialogInterface, i) -> dialogInterface.dismiss())
                .attachAlphaSlideBar(true)
                .attachBrightnessSlideBar(true)
                .setBottomSpace(12);
        builder.getColorPickerView().setFlagView(new CustomFlag(fragment.requireContext(), R.layout.layout_color_pikcer));
        builder.show();
    }

    private int getColor(View view) {
        ColorStateList colorStateList = view.getBackgroundTintList();
        return Objects.requireNonNull(colorStateList).getColorForState(new int[]{android.R.attr.state_enabled}, 0);
    }

    private void selectFile(int type, TextView tvPath) {
        SelectFileActivity.Callback callback = tvPath::setText;
        if (type == 0) {
            SelectFileActivity.startSelectedImage(fragment, callback);
        } else {
            SelectFileActivity.startSelectedFont(fragment, callback);
        }
    }
}
