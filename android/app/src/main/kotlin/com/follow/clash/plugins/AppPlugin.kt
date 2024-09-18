package com.follow.clash.plugins

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.ComponentInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.getSystemService
import com.android.tools.smali.dexlib2.dexbacked.DexBackedDexFile
import androidx.core.content.FileProvider
import com.follow.clash.GlobalState
import com.follow.clash.extensions.getBase64
import com.follow.clash.models.Package
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.zip.ZipFile

class AppPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private var activity: Activity? = null

    private var toast: Toast? = null

    private lateinit var context: Context

    private lateinit var channel: MethodChannel

    private lateinit var scope: CoroutineScope

    private var vpnCallBack: (() -> Unit)? = null

    private val iconMap = mutableMapOf<String, String?>()

    private val packages = mutableListOf<Package>()

    private val skipPrefixList = listOf(
        "com.google",
        "com.android.chrome",
        "com.android.vending",
        "com.microsoft",
        "com.apple",
        "com.zhiliaoapp.musically", // Banned by China
    )

    private val chinaAppPrefixList = listOf(
        "com.tencent",
        "com.alibaba",
        "com.umeng",
        "com.qihoo",
        "com.ali",
        "com.alipay",
        "com.amap",
        "com.sina",
        "com.weibo",
        "com.vivo",
        "com.xiaomi",
        "com.huawei",
        "com.taobao",
        "com.secneo",
        "s.h.e.l.l",
        "com.stub",
        "com.kiwisec",
        "com.secshell",
        "com.wrapper",
        "cn.securitystack",
        "com.mogosec",
        "com.secoen",
        "com.netease",
        "com.mx",
        "com.qq.e",
        "com.baidu",
        "com.bytedance",
        "com.bugly",
        "com.miui",
        "com.oppo",
        "com.coloros",
        "com.iqoo",
        "com.meizu",
        "com.gionee",
        "cn.nubia",
        "com.oplus",
        "andes.oplus",
        "com.unionpay",
        "cn.wps"
    )

    private val chinaAppRegex by lazy {
        ("(" + chinaAppPrefixList.joinToString("|").replace(".", "\\.") + ").*").toRegex()
    }

    val VPN_PERMISSION_REQUEST_CODE = 1001

    val NOTIFICATION_PERMISSION_REQUEST_CODE = 1002

    private var isBlockNotification: Boolean = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        scope = CoroutineScope(Dispatchers.Default)
        context = flutterPluginBinding.applicationContext;
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    private fun tip(message: String?) {
        if (GlobalState.flutterEngine == null) {
            if (toast != null) {
                toast!!.cancel()
            }
            toast = Toast.makeText(context, message, Toast.LENGTH_SHORT)
            toast!!.show()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "moveTaskToBack" -> {
                activity?.moveTaskToBack(true)
                result.success(true);
            }

            "updateExcludeFromRecents" -> {
                val value = call.argument<Boolean>("value")
                updateExcludeFromRecents(value)
                result.success(true);
            }

            "getPackages" -> {
                scope.launch {
                    result.success(getPackagesToJson())
                }
            }

            "getChinaPackageNames" -> {
                scope.launch {
                    result.success(getChinaPackageNames())
                }
            }

            "getPackageIcon" -> {
                scope.launch {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.success(null)
                        return@launch
                    }
                    val packageIcon = getPackageIcon(packageName)
                    packageIcon.let {
                        if (it != null) {
                            result.success(it)
                            return@launch
                        }
                        if (iconMap["default"] == null) {
                            iconMap["default"] =
                                context.packageManager?.defaultActivityIcon?.getBase64()
                        }
                        result.success(iconMap["default"])
                        return@launch
                    }
                }
            }

            "tip" -> {
                val message = call.argument<String>("message")
                tip(message)
                result.success(true)
            }

            "openFile" -> {
                val path = call.argument<String>("path")!!
                openFile(path)
                result.success(true)
            }

            else -> {
                result.notImplemented();
            }
        }
    }

    private fun openFile(path: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileProvider",
            file
        )

        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(
            uri,
            "text/plain"
        )

        val flags =
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION

        val resInfoList = context.packageManager.queryIntentActivities(
            intent, PackageManager.MATCH_DEFAULT_ONLY
        )

        for (resolveInfo in resInfoList) {
            val packageName = resolveInfo.activityInfo.packageName
            context.grantUriPermission(
                packageName,
                uri,
                flags
            )
        }

        try {
            activity?.startActivity(intent)
        } catch (e: Exception) {
            println(e)
        }
    }

    private fun updateExcludeFromRecents(value: Boolean?) {
        val am = getSystemService(context, ActivityManager::class.java)
        val task = am?.appTasks?.firstOrNull {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                it.taskInfo.taskId == activity?.taskId
            } else {
                it.taskInfo.id == activity?.taskId
            }
        }

        when (value) {
            true -> task?.setExcludeFromRecents(value)
            false -> task?.setExcludeFromRecents(value)
            null -> task?.setExcludeFromRecents(false)
        }
    }

    private suspend fun getPackageIcon(packageName: String): String? {
        val packageManager = context.packageManager
        if (iconMap[packageName] == null) {
            iconMap[packageName] = try {
                packageManager?.getApplicationIcon(packageName)?.getBase64()
            } catch (_: Exception) {
                null
            }

        }
        return iconMap[packageName]
    }

    private fun getPackages(): List<Package> {
        val packageManager = context.packageManager
        if (packages.isNotEmpty()) return packages;
        packageManager?.getInstalledPackages(PackageManager.GET_META_DATA)?.filter {
            it.packageName != context.packageName
                    || it.requestedPermissions?.contains(Manifest.permission.INTERNET) == true
                    || it.packageName == "android"

        }?.map {
            Package(
                packageName = it.packageName,
                label = it.applicationInfo.loadLabel(packageManager).toString(),
                isSystem = (it.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 1,
                firstInstallTime = it.firstInstallTime
            )
        }?.let { packages.addAll(it) }
        return packages;
    }

    private suspend fun getPackagesToJson(): String {
        return withContext(Dispatchers.Default) {
            Gson().toJson(getPackages())
        }
    }

    private suspend fun getChinaPackageNames(): String {
        return withContext(Dispatchers.Default) {
            val packages: List<String> =
                getPackages().map { it.packageName }.filter { isChinaPackage(it) }
            Gson().toJson(packages)
        }
    }

    fun requestVpnPermission(context: Context, callBack: () -> Unit) {
        vpnCallBack = callBack
        val intent = VpnService.prepare(context)
        if (intent != null) {
            activity?.startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
            return;
        }
        vpnCallBack?.invoke()
    }

    fun requestNotificationsPermission(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            )
            if (permission != PackageManager.PERMISSION_GRANTED) {
                if (isBlockNotification) return
                if (activity == null) return
                ActivityCompat.requestPermissions(
                    activity!!,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
                return
            }
        }
    }

    private fun isChinaPackage(packageName: String): Boolean {
        val packageManager = context.packageManager ?: return false
        skipPrefixList.forEach {
            if (packageName == it || packageName.startsWith("$it.")) return false
        }
        val packageManagerFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_UNINSTALLED_PACKAGES or PackageManager.GET_ACTIVITIES or PackageManager.GET_SERVICES or PackageManager.GET_RECEIVERS or PackageManager.GET_PROVIDERS
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_UNINSTALLED_PACKAGES or PackageManager.GET_ACTIVITIES or PackageManager.GET_SERVICES or PackageManager.GET_RECEIVERS or PackageManager.GET_PROVIDERS
        }
        if (packageName.matches(chinaAppRegex)) {
            return true
        }
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(packageManagerFlags.toLong())
                )
            } else {
                @Suppress("DEPRECATION") packageManager.getPackageInfo(
                    packageName, packageManagerFlags
                )
            }
            mutableListOf<ComponentInfo>().apply {
                packageInfo.services?.let { addAll(it) }
                packageInfo.activities?.let { addAll(it) }
                packageInfo.receivers?.let { addAll(it) }
                packageInfo.providers?.let { addAll(it) }
            }.forEach {
                if (it.name.matches(chinaAppRegex)) return true
            }
            ZipFile(File(packageInfo.applicationInfo.publicSourceDir)).use {
                for (packageEntry in it.entries()) {
                    if (packageEntry.name.startsWith("firebase-")) return false
                }
                for (packageEntry in it.entries()) {
                    if (!(packageEntry.name.startsWith("classes") && packageEntry.name.endsWith(
                            ".dex"
                        ))
                    ) {
                        continue
                    }
                    if (packageEntry.size > 15000000) {
                        return true
                    }
                    val input = it.getInputStream(packageEntry).buffered()
                    val dexFile = try {
                        DexBackedDexFile.fromInputStream(null, input)
                    } catch (e: Exception) {
                        return false
                    }
                    for (clazz in dexFile.classes) {
                        val clazzName =
                            clazz.type.substring(1, clazz.type.length - 1).replace("/", ".")
                                .replace("$", ".")
                        if (clazzName.matches(chinaAppRegex)) return true
                    }
                }
            }
        } catch (_: Exception) {
            return false
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity;
        binding.addActivityResultListener(::onActivityResult)
        binding.addRequestPermissionsResultListener(::onRequestPermissionsResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity;
    }

    override fun onDetachedFromActivity() {
        channel.invokeMethod("exit", null)
        activity = null
    }

    private fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            if (resultCode == FlutterActivity.RESULT_OK) {
                GlobalState.initServiceEngine(context)
                vpnCallBack?.invoke()
            }
        }
        return true
    }

    private fun onRequestPermissionsResultListener(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            isBlockNotification = true
        }
        return true
    }
}
