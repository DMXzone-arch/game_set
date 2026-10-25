package com.example.game_set

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.example.game_set.BuildConfig

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gameset/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method != "getVersion") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                result.success(
                    mapOf(
                        "version" to BuildConfig.VERSION_NAME,
                        "buildNumber" to BuildConfig.VERSION_CODE,
                    ),
                )
            }
    }
}
