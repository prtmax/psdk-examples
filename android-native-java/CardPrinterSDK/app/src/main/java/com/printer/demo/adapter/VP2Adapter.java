package com.printer.demo.adapter;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.printer.demo.fragments.FragmentBase;
import com.printer.demo.fragments.FragmentInfo;
import com.printer.demo.fragments.FragmentPrint;

import java.util.ArrayList;

public class VP2Adapter extends FragmentStateAdapter {
    private final ArrayList<Fragment> fragments = new ArrayList<>();

    public VP2Adapter(@NonNull FragmentActivity fragmentActivity) {
        super(fragmentActivity);
        fragments.add(new FragmentBase());
        fragments.add(new FragmentInfo());
        fragments.add(new FragmentPrint());
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        return fragments.get(position);
    }

    @Override
    public int getItemCount() {
        return fragments.size();
    }
}
