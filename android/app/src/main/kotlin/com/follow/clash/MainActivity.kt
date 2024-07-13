package com.follow.clash

import android.os.Bundle
import android.webkit.WebSettings
import android.webkit.WebView
import io.flutter.plugin.common.MethodChannel
import com.follow.clash.plugins.AppPlugin
import com.follow.clash.plugins.ProxyPlugin
import com.follow.clash.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(ProxyPlugin())
        flutterEngine.plugins.add(TilePlugin())
        GlobalState.flutterEngine = flutterEngine
    }

    override fun onDestroy() {
        GlobalState.flutterEngine = null
        super.onDestroy()
    }
}