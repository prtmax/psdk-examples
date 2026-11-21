package com.printer.demo;

import android.content.Context;
import android.content.SharedPreferences;

public class ConfigPreference {

    private ConfigPreference(SharedPreferences sharedPreferences) {
        mSharedPreferences = sharedPreferences;
    }

    private final SharedPreferences mSharedPreferences;
    private static volatile ConfigPreference gConfigPreference;

    public static SharedPreferences with(Context context) {
        if (gConfigPreference == null) {
            synchronized (ConfigPreference.class) {
                if (gConfigPreference == null) {
                    gConfigPreference = new ConfigPreference(context.getApplicationContext().getSharedPreferences("APP_CONFIG", 0));
                }
            }
        }
        return gConfigPreference.mSharedPreferences;
    }
}
