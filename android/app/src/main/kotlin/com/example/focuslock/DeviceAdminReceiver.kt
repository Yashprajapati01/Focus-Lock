package com.example.focuslock

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class FocusLockDeviceAdminReceiver : DeviceAdminReceiver() {
    
    companion object {
        private const val TAG = "FocusLockDeviceAdmin"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "Device admin disabled")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "This will disable the Focus Lock app's ability to manage device settings and enforce focus restrictions."
    }
}