package com.example.appstinence
import android.util.Log
import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class AppBlockerService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        Log.d("ACCESS_SERVICE", "Got event: ${event?.packageName}")
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (MainActivity.blockedApps.contains(packageName)) {
                Log.d("ACCESS_SERVICE", "Blocking $packageName")
                showOverlay()
            }
        }
    }

    private fun showOverlay() {
        val intent = Intent(this, OverlayService::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startService(intent)
    }

    override fun onInterrupt() {}
}
