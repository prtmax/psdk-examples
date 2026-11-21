package com.printer.demo.fragments;

import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.lxj.xpopup.XPopup;
import com.printer.demo.MainActivity;
import com.printer.demo.R;
import com.printer.demo.adapter.GroupAdapter;
import com.printer.demo.entity.InfoItem;
import com.printer.demo.task.ReadInfoTask;
import com.printer.demo.task.WriteInfoTask;
import com.printer.sdk.CardPrinterAPI;

import java.util.ArrayList;

/**
 * @noinspection unchecked
 */
public class FragmentInfo extends Fragment {

    private CardPrinterAPI api;
    private final HandlerThread handlerThread = new HandlerThread("PrinterInfoTask");
    private Handler handler;
    private TextView tvMsg;
    private final GroupAdapter groupAdapter = new GroupAdapter();

    public FragmentInfo() {
        super(R.layout.fragment_info);
    }

    @Override
    public void onDestroy() {
        handlerThread.quit();
        super.onDestroy();
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        api = ((MainActivity) context).api;
        handlerThread.start();
        ((MainActivity) context).runOnUiThread(() -> handler = new Handler(handlerThread.getLooper()) {
            @Override
            public void handleMessage(@NonNull Message msg) {
                if (msg.what == ReadInfoTask.READ_INFO) {
                    ArrayList<InfoItem> infoList = (ArrayList<InfoItem>) msg.obj;
                    groupAdapter.setInfoItems(infoList);
                } else {
                    String text = (String) msg.obj;
                    requireActivity().runOnUiThread(() -> tvMsg.setText(text));
                }
            }
        });
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        view.findViewById(R.id.btn_read_setting).setOnClickListener(v -> readSetting());
        view.findViewById(R.id.btn_write_setting).setOnClickListener(v -> writeSetting());
        tvMsg = view.findViewById(R.id.tv_msg);
        RecyclerView rvInfos = view.findViewById(R.id.rv_setting);
        rvInfos.setLayoutManager(new LinearLayoutManager(requireContext()));
        rvInfos.setAdapter(groupAdapter);
        groupAdapter.setItemClickListener((item, i) -> {
            InfoItem.Property property = (InfoItem.Property) item;
            if (property.items != null) {
                new XPopup.Builder(requireContext())
                        .isViewMode(true)
                        .asCenterList(property.name, property.items, (position, text) -> {
                            property.index = position;
                            groupAdapter.notifyItemChanged(i);
                        })
                        .show();
            } else {
                String range = property.minValue == null || property.maxValue == null ?
                        null : getString(R.string.range, property.minValue, property.maxValue);
                new XPopup.Builder(requireContext())
                        .isViewMode(true)
                        .isRequestFocus(true)
                        .autoOpenSoftInput(true)
                        .asInputConfirm(property.name, range, property.value, property.value,
                                        text -> {
                                            if (property.propertyType == Integer.class) {
                                                try {
                                                    int minValue = Integer.parseInt(property.minValue);
                                                    int maxValue = Integer.parseInt(property.maxValue);
                                                    int value = Integer.parseInt(text);
                                                    if (value < minValue || value > maxValue) {
                                                        tvMsg.setText(getString(R.string.out_of_range));
                                                        return;
                                                    }
                                                    // Avoid numbers like 050,convert to 50
                                                    property.value = String.valueOf(value);
                                                } catch (NumberFormatException e) {
                                                    handler.obtainMessage(0, getString(R.string.data_format_error)).sendToTarget();
                                                }
                                            } else if (property.propertyType == Long.class) {
                                                try {
                                                    long minValue = Long.parseLong(property.minValue);
                                                    long maxValue = Long.parseLong(property.maxValue);
                                                    long value = Long.parseLong(text);
                                                    if (value < minValue || value > maxValue) {
                                                        tvMsg.setText(getString(R.string.out_of_range));
                                                        return;
                                                    }
                                                    // Avoid numbers like 050,convert to 50
                                                    property.value = String.valueOf(value);
                                                } catch (NumberFormatException e) {
                                                    handler.obtainMessage(0, getString(R.string.data_format_error)).sendToTarget();
                                                }
                                            } else {
                                                property.value = text;
                                            }
                                            groupAdapter.notifyItemChanged(i);
                                        })
                        .show();
            }
        });
    }

    private void readSetting() {
        tvMsg.setText("");
        handler.post(new ReadInfoTask(requireContext(), handler, api));
    }

    private void writeSetting() {
        tvMsg.setText("");
        handler.post(new WriteInfoTask(requireContext(), handler, api, groupAdapter.getInfoItems()));
    }
}
