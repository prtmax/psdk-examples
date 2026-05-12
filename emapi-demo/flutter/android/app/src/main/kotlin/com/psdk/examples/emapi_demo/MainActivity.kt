package com.psdk.examples.emapi_demo

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.psdk.examples.emapi_demo/android_sdk",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
    }
}
