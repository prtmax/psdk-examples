package com.printer.demo.adapter;

import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.RecyclerView;

import com.printer.demo.R;
import com.printer.demo.entity.InfoItem;

import java.util.ArrayList;
import java.util.List;

public class GroupAdapter extends RecyclerView.Adapter<GroupAdapter.ViewHolder> {
    private ArrayList<InfoItem> infoItems;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private ItemClickListener itemClickListener;

    public void setItemClickListener(ItemClickListener itemClickListener) {
        this.itemClickListener = itemClickListener;
    }

    public void setInfoItems(ArrayList<InfoItem> infoItems) {
        this.infoItems = infoItems;
        mainHandler.post(() -> notifyDataSetChanged());
    }

    public List<InfoItem> getInfoItems() {
        return infoItems;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup group, int i) {
        if (i == 0) {
            return new TitleViewHolder(LayoutInflater.from(group.getContext()).inflate(R.layout.layout_item_title, group, false));
        }
        return new PropertyViewHolder(LayoutInflater.from(group.getContext()).inflate(R.layout.layout_item_property, group, false));
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int i) {
        if (holder instanceof TitleViewHolder) {
            InfoItem.Title title = (InfoItem.Title) infoItems.get(i);
            ((TitleViewHolder) holder).tvTitle.setText(title.title);
            holder.itemView.setEnabled(true);
            holder.itemView.setOnClickListener(null);
        } else {
            InfoItem.Property property = (InfoItem.Property) infoItems.get(i);
            PropertyViewHolder propertyViewHolder = ((PropertyViewHolder) holder);
            propertyViewHolder.tvPropertyName.setEnabled(property.writable);
            propertyViewHolder.tvPropertyValue.setEnabled(property.writable);
            propertyViewHolder.tvPropertyName.setText(property.name);
            String text = property.items != null ? property.items[property.index] : property.value;
            propertyViewHolder.tvPropertyValue.setText(property.suffix != null ? text + property.suffix : text);
            holder.itemView.setEnabled(property.writable);
            holder.itemView.setOnClickListener(v -> {
                if (itemClickListener != null) {
                    itemClickListener.onItemClick(property, i);
                }
            });
        }
    }

    @Override
    public int getItemViewType(int position) {
        return infoItems.get(position) instanceof InfoItem.Title ? 0 : 1;
    }

    @Override
    public int getItemCount() {
        return infoItems == null ? 0 : infoItems.size();
    }

    public interface ItemClickListener {
        void onItemClick(InfoItem item, int position);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
        }
    }

    public static class TitleViewHolder extends ViewHolder {
        TextView tvTitle;

        public TitleViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.tv_title);
        }
    }

    public static class PropertyViewHolder extends ViewHolder {
        TextView tvPropertyName;
        TextView tvPropertyValue;
        ConstraintLayout clProperty;

        public PropertyViewHolder(@NonNull View itemView) {
            super(itemView);
            clProperty = itemView.findViewById(R.id.cl_property);
            tvPropertyName = itemView.findViewById(R.id.tv_property_name);
            tvPropertyValue = itemView.findViewById(R.id.tv_property_value);
        }
    }
}
