package com.example.appstinence

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import android.app.usage.UsageStatsManager

class ForegroundService : Service() {
    private var lastApp: String? = null
    private var handler: Handler? = null

    companion object {
        var lastBlockedApp: String? = null
    }

    override fun onCreate() {
        super.onCreate()
        handler = Handler(Looper.getMainLooper())
        startForegroundService()
        monitorApps()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundService() {
        val channelId = "APP_BLOCKER_SERVICE_CHANNEL"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "App Blocker Service",
                NotificationManager.IMPORTANCE_LOW
            )
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("App Blocker Running")
            .setContentText("Monitoring app usage...")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .build()

        startForeground(1, notification)
    }

    private fun monitorApps() {
        handler?.post(object : Runnable {
            override fun run() {
                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val time = System.currentTimeMillis()
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    time - 1000 * 60, time
                )

                if (!stats.isNullOrEmpty()) {
                    val currentApp = stats.maxByOrNull { it.lastTimeUsed }?.packageName
                    //Log.d("ForegroundService", "Current app: $currentApp, Last app: $lastApp")

                    if (currentApp != null && currentApp != lastApp && currentApp != packageName) {
                        lastApp = currentApp
                        if (MainActivity.blockedApps.contains(currentApp)) {
                            Log.d("ForegroundService", "Blocked app detected: $currentApp")
                            lastBlockedApp = currentApp
                            showOverlay()
                        }
                    }
                }

                handler?.postDelayed(this, 500)
            }
        })
    }

    private fun showOverlay() {
        Log.d("ForegroundService", "Launching native lock screen activity")
        val intent = Intent(this, LockScreenActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("package_name", lastApp) // 👈 This is the fix!
        }
        startActivity(intent)
    }


    override fun onDestroy() {
        super.onDestroy()
        handler?.removeCallbacksAndMessages(null)
    }
}
