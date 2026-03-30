package com.example.classic_bluetooth_demo.util;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;
import android.preference.PreferenceManager;

import com.example.classic_bluetooth_demo.R;

import java.util.Locale;

public class LanguageUtil {
  private static final String LANGUAGE_KEY = "language";
  private static final String LANGUAGE_ENGLISH = "en";
  private static final String LANGUAGE_CHINESE = "zh";

  public static String getCurrentLanguage(Context context) {
    SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
    String storedLanguage = preferences.getString(LANGUAGE_KEY, null);
    if (storedLanguage != null) {
      return storedLanguage;
    }
    return isChineseLocale(Locale.getDefault()) ? LANGUAGE_CHINESE : LANGUAGE_ENGLISH;
  }

  public static void setLanguage(Context context, String language) {
    SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(context);
    preferences.edit().putString(LANGUAGE_KEY, language).apply();
    updateResources(context, language);
  }

  public static void applyLanguage(Context context) {
    updateResources(context, getCurrentLanguage(context));
  }

  public static void applyLanguage(Activity activity) {
    updateResources(activity, getCurrentLanguage(activity));
    activity.setTitle(activity.getString(R.string.app_name));
  }

  private static void updateResources(Context context, String language) {
    Locale locale = getLocale(language);
    Locale.setDefault(locale);

    Resources resources = context.getResources();
    Configuration configuration = new Configuration(resources.getConfiguration());
    configuration.setLocale(locale);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      context.createConfigurationContext(configuration);
    }
    resources.updateConfiguration(configuration, resources.getDisplayMetrics());
  }

  private static Locale getLocale(String language) {
    if (LANGUAGE_CHINESE.equals(language)) {
      return Locale.SIMPLIFIED_CHINESE;
    }
    return Locale.ENGLISH;
  }

  private static boolean isChineseLocale(Locale locale) {
    return locale != null && locale.getLanguage().startsWith(LANGUAGE_CHINESE);
  }
}
