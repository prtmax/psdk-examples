package com.printer.demo;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.viewpager2.widget.ViewPager2;

import com.printer.demo.adapter.VP2Adapter;
import com.printer.sdk.CardPrinterAPI;
import com.printer.sdk.utils.ThreadUtils;

import me.relex.circleindicator.CircleIndicator3;

public class MainActivity extends AppCompatActivity {
    public final CardPrinterAPI api = new CardPrinterAPI(this);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        showVersionName();
        ViewPager2 vp2 = findViewById(R.id.vp2);
        vp2.setAdapter(new VP2Adapter(this));
        CircleIndicator3 ci3 = findViewById(R.id.ci3);
        ci3.setViewPager(vp2);

        ThreadUtils.create();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()){
                try {
                    Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                    intent.addCategory("android.intent.category.DEFAULT");
                    intent.setData(Uri.parse(String.format("package:%s", getPackageName())));
                    startActivityForResult(intent, 666);
                } catch (Exception e) {
                    Intent intent = new Intent();
                    intent.setData(Uri.parse(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
                    startActivityForResult(intent, 666);
                }
            }
        }
    }

    private void showVersionName() {
        PackageManager pm = getPackageManager();
        String versionName;
        try {
            PackageInfo pi = pm.getPackageInfo(getPackageName(), PackageManager.GET_META_DATA);
            versionName = pi.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            versionName = getString(R.string.unknown);
        }
        ((TextView) findViewById(R.id.version)).setText(getString(R.string.version, versionName));
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ThreadUtils.destroy();
    }
}