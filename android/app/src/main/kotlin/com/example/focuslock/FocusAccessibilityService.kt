package com.example.focuslock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class FocusAccessibilityService : AccessibilityService() {
    
    private lateinit var sharedPrefs: SharedPreferences
    
    companion object {
        private const val TAG = "FocusAccessibilityService"
        private const val PREFS_NAME = "focus_lock_prefs"
        private const val KEY_SESSION_ACTIVE = "session_active"
        private const val KEY_LOCK_PACKAGE = "lock_package"
    }
    
    override fun onCreate() {
        super.onCreate()
        sharedPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        Log.d(TAG, "FocusAccessibilityService created")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val isSessionActive = sharedPrefs.getBoolean(KEY_SESSION_ACTIVE, false)
        val lockPackage = sharedPrefs.getString(KEY_LOCK_PACKAGE, packageName)
        
        if (!isSessionActive) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(event, lockPackage)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleWindowContentChanged(event, lockPackage)
            }
        }
    }
    
    private fun handleWindowStateChanged(event: AccessibilityEvent, lockPackage: String?) {
        val currentPackage = event.packageName?.toString()
        
        Log.d(TAG, "Window state changed: $currentPackage")
        
        // If user switched to a different app, bring back the lock screen
        if (currentPackage != null && currentPackage != lockPackage) {
            // Ignore system UI packages
            if (isSystemPackage(currentPackage)) {
                return
            }
            
            Log.d(TAG, "User tried to switch to $currentPackage, bringing back lock screen")
            bringBackLockScreen()
        }
    }
    
    private fun handleWindowContentChanged(event: AccessibilityEvent, lockPackage: String?) {
        val currentPackage = event.packageName?.toString()
        
        // Additional check for content changes that might indicate app switching
        if (currentPackage != null && currentPackage != lockPackage) {
            if (!isSystemPackage(currentPackage)) {
                Log.d(TAG, "Content changed in non-lock app: $currentPackage")
                bringBackLockScreen()
            }
        }
    }
    
    private fun isSystemPackage(packageName: String): Boolean {
        return packageName.startsWith("com.android.systemui") ||
               packageName.startsWith("android") ||
               packageName.startsWith("com.android.launcher") ||
               packageName.startsWith("com.google.android.inputmethod") ||
               packageName == "com.android.settings" ||
               packageName == "com.android.vending" // Play Store
    }
    
    private fun bringBackLockScreen() {
        try {
            val intent = Intent(this, LockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                         Intent.FLAG_ACTIVITY_CLEAR_TOP or
                         Intent.FLAG_ACTIVITY_SINGLE_TOP or
                         Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(intent)
            Log.d(TAG, "Lock screen brought back to foreground")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bring back lock screen", e)
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "FocusAccessibilityService destroyed")
    }
}