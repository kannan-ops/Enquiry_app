package com.srivagroups.enquiry

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.srivagroups.enquiry/share"
    private var pendingSharedData: Map<String, Any>? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        sendPendingData()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialShare") {
                result.success(pendingSharedData)
                pendingSharedData = null // Clear after reading
            } else if (call.method == "shareText") {
                val textToShare = call.argument<String>("text")
                if (textToShare != null) {
                    try {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, textToShare)
                        }
                        val chooser = Intent.createChooser(shareIntent, "Share details via")
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                } else {
                    result.error("BAD_ARGS", "Text parameter is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type || type.startsWith("text/")) {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (sharedText != null) {
                    pendingSharedData = mapOf("type" to "text", "text" to sharedText)
                }
            } else {
                val fileUri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (fileUri != null) {
                    val path = getPathFromUri(this, fileUri)
                    if (path != null) {
                        pendingSharedData = mapOf("type" to "media", "paths" to listOf(path))
                    }
                }
            }
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            val fileUris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            if (fileUris != null) {
                val paths = mutableListOf<String>()
                for (uri in fileUris) {
                    val path = getPathFromUri(this, uri)
                    if (path != null) {
                        paths.add(path)
                    }
                }
                if (paths.isNotEmpty()) {
                    pendingSharedData = mapOf("type" to "media", "paths" to paths)
                }
            }
        }
    }

    private fun sendPendingData() {
        val data = pendingSharedData
        if (data != null && methodChannel != null) {
            methodChannel?.invokeMethod("onShareReceived", data)
            pendingSharedData = null
        }
    }

    private fun getPathFromUri(context: Context, uri: Uri): String? {
        try {
            if (uri.scheme == "file") {
                return uri.path
            }
            val contentResolver = context.contentResolver
            val cursor = contentResolver.query(uri, null, null, null, null)
            var displayName: String? = null
            if (cursor != null && cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    displayName = cursor.getString(nameIndex)
                }
                cursor.close()
            }
            if (displayName == null) {
                displayName = "shared_file_${System.currentTimeMillis()}"
            }
            val cacheFile = File(context.cacheDir, displayName)
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val outputStream = FileOutputStream(cacheFile)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            return cacheFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
}
