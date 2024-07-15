package com.follow.clash.services

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import androidx.lifecycle.Observer
import com.follow.clash.GlobalState
import com.follow.clash.RunState
import com.follow.clash.TempActivity


@RequiresApi(Build.VERSION_CODES.N)
class FlClashTileService : TileService() {

    private val observer = Observer<RunState> { runState ->
        updateTile(runState)
    }

    private fun updateTile(runState: RunState) {
        if (qsTile != null) {
            qsTile.state = when (runState) {
                RunState.START -> Tile.STATE_ACTIVE
                RunState.PENDING -> Tile.STATE_UNAVAILABLE
                RunState.STOP -> Tile.STATE_INACTIVE
            }
            qsTile.updateTile()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        GlobalState.runState.value?.let { updateTile(it) }
        GlobalState.runState.observeForever(observer)
    }

    private fun activityTransfer() {
        val intent = Intent(this, TempActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
        val pendingIntent = if (Build.VERSION.SDK_INT >= 31) {
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(pendingIntent)
        } else {
            startActivityAndCollapse(intent)
        }
    }

    override fun onClick() {
        super.onClick()
        activityTransfer()
        if (GlobalState.runState.value == RunState.STOP) {
            GlobalState.runState.value = RunState.PENDING
            val titlePlugin = GlobalState.getCurrentTitlePlugin()
            if (titlePlugin != null) {
                titlePlugin.handleStart()
            } else {
                GlobalState.initServiceEngine(applicationContext)
            }
        } else if (GlobalState.runState.value == RunState.START) {
            GlobalState.runState.value = RunState.PENDING
            GlobalState.getCurrentTitlePlugin()?.handleStop()
        }

    }

    override fun onDestroy() {
        GlobalState.runState.removeObserver(observer)
        super.onDestroy()
    }
}