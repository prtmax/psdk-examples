package com.example.classic_bluetooth_demo.util;

import android.content.Context;
import android.content.SharedPreferences;
import android.widget.Toast;

import java.io.File;

public class MSharedPreferences {

    private static MSharedPreferences mSharedPreferences;
    private SharedPreferences sharedPreferences;
    private SharedPreferences.Editor editor;
    private Context context;

    //直接用静态方法获取即可。不需每次创建
    public static MSharedPreferences getmSharedPreferences() {
        if (mSharedPreferences == null) {
            mSharedPreferences = new MSharedPreferences();
        }
        return mSharedPreferences;
    }

    /**
     * 初始化Android自带的SharedPreferences类和编辑器
     */
    public void init(Context context) {
        //这里初始化Android提供的SharedPreferences类，也是不用创建，直接获取，如果有这个文件则不需要创建返回对象，如没有，直接创建
        sharedPreferences = context.getSharedPreferences(Config.SP, Context.MODE_PRIVATE);
        editor = sharedPreferences.edit();
    }

    /**
     * 删除此配置文件
     */
    public void delete(Context context) {
        String str = context.getPackageName();
        //这里实质上只是创建了个实例，并不是个文件
        //public boolean createNewFile() throws IOException // file.createNewFile();当且仅当文件不存在时创建，否则会抛出异常
        File file = new File("/data/data/" + context.getPackageName().toString() + "/shared_prefs", Config.SP);
        if (file.exists()) {
            file.delete();
            Toast.makeText(context, "删除配置文件成功！！！", Toast.LENGTH_SHORT).show();
        }

    }

    /**
     * 清除配置文件内的信息
     */

    public void clear(Context context) {
        if (editor != null) {
            editor.clear().commit();
            Toast.makeText(context, "你好", Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * 以下是写入各类数据
     */
    public void putString(String key, String value) {
        editor.putString(key, value);
    }

    public void putInt(String key, int value) {
        editor.putInt(key, value);
    }

    public void putLong(String key, long value) {
        editor.putLong(key, value);
    }

    public void putDouble(String key, double value) {
        editor.putFloat(key, (float) value);
    }

    public void putBoolean(String key, boolean value) {
        editor.putBoolean(key, value);
    }



    /**
     * 以下是读取各类数据
     */
    public String getString(String key) {
        return sharedPreferences.getString(key, "");
    }

    public int getInt(String key) {
        return sharedPreferences.getInt(key, -1);
    }

    public long getLong(String key) {
        return sharedPreferences.getLong(key, 0);
    }

    public float getFloat(String key) {
        return sharedPreferences.getFloat(key, 0);
    }

    public boolean getBoolean(String key) {
        return sharedPreferences.getBoolean(key, false);
    }

    /**
     * 提交使编辑器写入
     */
    public void commit() {
        editor.commit();
    }


}
