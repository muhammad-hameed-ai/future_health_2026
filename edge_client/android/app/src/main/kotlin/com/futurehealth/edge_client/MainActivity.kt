package com.futurehealth.edge_client

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.futurehealth.skinguard/updater"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        if (file.exists()) {
                            val intent = Intent(Intent.ACTION_VIEW)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

                            val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.fileprovider",
                                    file
                                )
                            } else {
                                Uri.fromFile(file)
                            }

                            intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
                            context.startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_FOUND", "APK file does not exist", null)
                        }
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
