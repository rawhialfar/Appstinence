package com.example.appstinence

import android.annotation.SuppressLint
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.appstinence/native"
    private var saveAppData: SharedPreferences? = null

    companion object {
        var blockedApps: List<String> = listOf()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        saveAppData = applicationContext.getSharedPreferences("app_block_data", Context.MODE_PRIVATE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateBlockedApps" -> {
                    val apps = call.arguments as List<*>
                    blockedApps = apps.filterIsInstance<String>()
                    saveBlockedApps(blockedApps)
                    result.success("Success")
                }

                "startService" -> {
                    if (Settings.canDrawOverlays(this) && isUsageStatsPermissionGranted()) {
                        val intent = Intent(this, ForegroundService::class.java)
                        ContextCompat.startForegroundService(this, intent)
                        result.success("Service started")
                    } else {
                        result.error("PERMISSION_DENIED", "Overlay or usage stats permission not granted", null)
                    }
                }

                "stopService" -> {
                    stopService(Intent(this, ForegroundService::class.java))
                    result.success("Service stopped")
                }

                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }

                "requestOverlayPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                        startActivity(intent)
                    }
                    result.success(null)
                }

                "checkUsageStatsPermission" -> {
                    result.success(isUsageStatsPermissionGranted())
                }

                "requestUsageStatsPermission" -> {
                    if (!isUsageStatsPermissionGranted()) {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                    }
                    result.success(null)
                }

                "setPassword" -> {
                    val password = call.arguments as String
                    savePassword(password)
                    result.success("Password saved")
                }

                "getPassword" -> {
                    val password = saveAppData?.getString("password", null)
                    result.success(password)
                }

                "getLastBlockedApp" -> {
                    result.success(ForegroundService.lastBlockedApp)
                }

                "setPasswordForApp" -> {
                    val args = call.arguments as Map<*, *>
                    val packageName = args["package"] as? String
                    val password = args["password"] as? String
                    if (packageName != null && password != null) {
                        saveAppPassword(packageName, password)
                        result.success("Password saved for $packageName")
                    } else {
                        result.error("INVALID_ARGS", "Missing package or password", null)
                    }
                }

                "getPasswordForApp" -> {
                    val packageName = call.arguments as? String
                    if (packageName != null) {
                        val pwd = saveAppData?.getString("pwd_$packageName", null)
                        result.success(pwd)
                    } else {
                        result.error("INVALID_ARGS", "Missing package name", null)
                    }
                }

                "clearAllAppPasswords" -> {
                    val editor = saveAppData?.edit()
                    saveAppData?.all?.keys?.forEach {
                        if (it.startsWith("pwd_")) {
                            editor?.remove(it)
                        }
                    }
                    editor?.apply()
                    result.success("All app passwords cleared")
                }

                //  New method for Dart to access the launch intent extras
                "getInitialIntent" -> {
                    val extras = intent?.extras
                    val data = mapOf(
                        "show_overlay" to (extras?.getBoolean("show_overlay") ?: false),
                        "package_name" to extras?.getString("package_name")
                    )
                    result.success(data)
                }

                "getBlockedApps" -> {
                    val apps = saveAppData?.getString("blocked_apps", "")
                    result.success(apps)
                }

                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("CommitPrefEdits")
    private fun saveBlockedApps(apps: List<String>) {
        val editor: SharedPreferences.Editor = saveAppData!!.edit()
        editor.putString("blocked_apps", apps.joinToString(","))
        editor.apply()
    }

    @SuppressLint("CommitPrefEdits")
    private fun savePassword(password: String) {
        val editor: SharedPreferences.Editor = saveAppData!!.edit()
        editor.putString("password", password)
        editor.apply()
    }

    @SuppressLint("CommitPrefEdits")
    private fun saveAppPassword(packageName: String, password: String) {
        val editor: SharedPreferences.Editor = saveAppData!!.edit()
        editor.putString("pwd_$packageName", password)
        editor.apply()
    }


    private fun isUsageStatsPermissionGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
