package com.psdk.examples.cloud_print_demo

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pendingImagePickResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var destroyed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.psdk.examples.cloud_print_demo/local_image",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> launchLocalImagePicker(result)
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun launchLocalImagePicker(result: MethodChannel.Result) {
        if (pendingImagePickResult != null) {
            result.error("pick_in_progress", "已有图片选择窗口正在打开", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        pendingImagePickResult = result
        try {
            startActivityForResult(intent, REQUEST_PICK_LOCAL_IMAGE)
        } catch (error: ActivityNotFoundException) {
            pendingImagePickResult = null
            result.error(
                "picker_unavailable",
                error.message ?: "系统未提供本地图片选择器",
                null,
            )
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_PICK_LOCAL_IMAGE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val pending = pendingImagePickResult
        pendingImagePickResult = null
        if (pending == null) return

        val uri: Uri? = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            pending.success(null)
            return
        }

        Thread {
            try {
                val fileName = resolveDisplayName(uri)
                val mimeType = contentResolver.getType(uri)
                val bytes = readUriBytesLimited(uri, MAX_LOCAL_IMAGE_BYTES)
                mainHandler.post {
                    if (destroyed || isFinishing || isDestroyed) return@post
                    pending.success(
                        mapOf(
                            "name" to fileName,
                            "bytes" to bytes,
                            "mimeType" to mimeType,
                        ),
                    )
                }
            } catch (error: Exception) {
                mainHandler.post {
                    if (destroyed || isFinishing || isDestroyed) return@post
                    pending.error(
                        "read_failed",
                        error.message ?: "读取本地图片失败",
                        null,
                    )
                }
            }
        }.start()
    }

    private fun resolveDisplayName(uri: Uri): String {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            val col = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (col >= 0 && cursor.moveToFirst()) {
                val name = cursor.getString(col)
                if (!name.isNullOrBlank()) return name
            }
        }
        val tail = uri.lastPathSegment?.substringAfterLast('/')
        return if (!tail.isNullOrBlank()) tail else "local_image"
    }

    private fun readUriBytesLimited(uri: Uri, maxBytes: Int): ByteArray {
        val stream = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("无法打开选中的图片文件")
        stream.use { input ->
            val out = ByteArrayOutputStream()
            val buf = ByteArray(16 * 1024)
            var total = 0
            while (true) {
                val n = input.read(buf)
                if (n < 0) break
                total += n
                if (total > maxBytes) {
                    throw IllegalStateException("所选图片超过 25 MB 大小限制")
                }
                out.write(buf, 0, n)
            }
            val data = out.toByteArray()
            if (data.isEmpty()) {
                throw IllegalStateException("选中的图片文件为空")
            }
            return data
        }
    }

    override fun onDestroy() {
        destroyed = true
        mainHandler.removeCallbacksAndMessages(null)
        try {
            pendingImagePickResult?.success(null)
        } catch (_: Exception) {}
        pendingImagePickResult = null
        super.onDestroy()
    }

    private companion object {
        const val REQUEST_PICK_LOCAL_IMAGE = 4102
        const val MAX_LOCAL_IMAGE_BYTES = 25 * 1024 * 1024
    }
}
