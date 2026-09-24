package com.bttr.bttr_client_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val performanceWriter = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bttr/performance")
            .setMethodCallHandler { call, result ->
                if (call.method != "appendFrames") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val rows = call.arguments as? String
                val directory = externalMediaDirs.firstOrNull()
                if (rows.isNullOrEmpty() || directory == null) {
                    result.error("PERFORMANCE_FILE", "Frame data or directory unavailable", null)
                    return@setMethodCallHandler
                }
                performanceWriter.execute {
                    try {
                        check(directory.isDirectory || directory.mkdirs()) {
                            "Cannot create performance directory"
                        }
                        File(directory, "performance-frames.csv").appendText("$rows\n")
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("PERFORMANCE_FILE", error.message, null)
                    }
                }
            }
    }

    override fun onDestroy() {
        performanceWriter.shutdown()
        super.onDestroy()
    }
}
