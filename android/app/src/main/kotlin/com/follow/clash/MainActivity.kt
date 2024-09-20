package com.follow.clash


import android.content.Intent
import android.os.Bundle
import com.follow.clash.plugins.AppPlugin
import com.follow.clash.plugins.ServicePlugin
import com.follow.clash.plugins.VpnPlugin
import com.follow.clash.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        when (intent.action) {
            "com.follow.clash.action.START" -> {
                GlobalState.getCurrentTilePlugin()?.handleStart()
            }

            "com.follow.clash.action.STOP" -> {
                GlobalState.getCurrentTilePlugin()?.handleStop()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(VpnPlugin())
        flutterEngine.plugins.add(ServicePlugin())
        flutterEngine.plugins.add(TilePlugin())
        GlobalState.flutterEngine = flutterEngine
    }

    override fun onDestroy() {
        GlobalState.flutterEngine = null
        super.onDestroy()
    }
}