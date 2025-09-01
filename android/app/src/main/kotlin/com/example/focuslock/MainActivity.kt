package com.example.focuslock

import android.Manifest
import android.app.ActivityManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityManager
import android.view.KeyEvent
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "focuslock/permissions"
    private val DEVICE_ADMIN_CHANNEL = "com.focuslock/device_admin"
    private val UNINSTALL_CHANNEL = "com.focuslock.admin/uninstall"
    private val INFO_CHANNEL = "com.focuslock.admin/info"
    private val DEVICE_ADMIN_REQUEST_CODE = 1001
    private val OVERLAY_PERMISSION_REQUEST_CODE = 1002
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003
    private val USAGE_STATS_REQUEST_CODE = 1004
    
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPermissionType: String? = null
    private var isLockModeActive = false
    private var lockTimer: Timer? = null
    private var lockStartTime: Long = 0
    private var lockDurationMs: Long = 0

    companion object {
        private const val TAG = "FocusLockMainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, FocusLockDeviceAdminReceiver::class.java)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Admin Permission Methods
                "requestAdminPermission" -> {
                    requestAdminPermission(result)
                }
                "isAdminActive" -> {
                    result.success(devicePolicyManager.isAdminActive(adminComponent))
                }
                "openAdminSettings" -> {
                    openAdminSettings(result)
                }
                
                // Notification Permission Methods
                "requestNotificationPermission" -> {
                    requestNotificationPermission(result)
                }
                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings(result)
                }
                
                // Overlay Permission Methods
                "requestOverlayPermission" -> {
                    requestOverlayPermission(result)
                }
                "canDrawOverlays" -> {
                    result.success(canDrawOverlays())
                }
                "openOverlaySettings" -> {
                    openOverlaySettings(result)
                }
                
                // Usage Stats Permission Methods
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission(result)
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings(result)
                }
                
                // Accessibility Permission Methods
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission(result)
                }
                "hasAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings(result)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup device admin channel (for compatibility with existing Flutter code)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_ADMIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasDeviceAdminPermission" -> {
                    result.success(devicePolicyManager.isAdminActive(adminComponent))
                }
                "hasOverlayPermission" -> {
                    result.success(canDrawOverlays())
                }
                "requestDeviceAdminPermission" -> {
                    requestAdminPermission(result)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission(result)
                }
                "hasAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    // For accessibility, we can only open settings, not directly request
                    openAccessibilitySettings(result)
                }
                "startDeviceLock" -> {
                    val durationMs = when (val duration = call.argument<Any>("durationMs")) {
                        is Int -> duration.toLong()
                        is Long -> duration
                        else -> 60000L
                    }
                    startDeviceLock(durationMs, result)
                }
                "endDeviceLock" -> {
                    endDeviceLock(result)
                }
                "isLockActive" -> {
                    result.success(isLockModeActive)
                }
                "getRemainingTime" -> {
                    val remaining = if (isLockModeActive) {
                        val elapsed = System.currentTimeMillis() - lockStartTime
                        maxOf(0, lockDurationMs - elapsed)
                    } else 0
                    result.success(remaining)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup uninstall channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNINSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName") ?: this.packageName
                    val silent = call.argument<Boolean>("silent") ?: false
                    uninstallApp(packageName, silent, result)
                }
                "showUninstallDialog" -> {
                    showUninstallDialog(result)
                }
                "canSilentUninstall" -> {
                    result.success(canPerformSilentUninstall())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPackageName" -> {
                    Log.d(TAG, "getPackageName called, returning: $packageName")
                    result.success(packageName)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // ==================== ADMIN PERMISSION METHODS ====================
    
    private fun requestAdminPermission(result: MethodChannel.Result) {
        if (devicePolicyManager.isAdminActive(adminComponent)) {
            result.success(true)
            return
        }

        pendingResult = result
        pendingPermissionType = "admin"
        
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Focus Lock needs device administrator privileges to manage screen lock and enforce focus restrictions."
            )
        }
        
        try {
            startActivityForResult(intent, DEVICE_ADMIN_REQUEST_CODE)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request admin permission", e)
            pendingResult = null
            pendingPermissionType = null
            result.error("ADMIN_REQUEST_FAILED", "Failed to request admin permission: ${e.message}", null)
        }
    }

    private fun openAdminSettings(result: MethodChannel.Result) {
        try {
            // Open directly to Device Admin settings instead of general security settings
            val intent = Intent().apply {
                action = "android.settings.DEVICE_ADMIN_SETTINGS"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open admin settings", e)
            // Fallback to general security settings
            try {
                val fallbackIntent = Intent().apply {
                    action = Settings.ACTION_SECURITY_SETTINGS
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                result.success(null)
            } catch (fallbackException: Exception) {
                result.error("SETTINGS_OPEN_FAILED", "Failed to open admin settings: ${e.message}", null)
            }
        }
    }

    // ==================== NOTIFICATION PERMISSION METHODS ====================
    
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ requires runtime permission request
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
                return
            }
            
            pendingResult = result
            pendingPermissionType = "notification"
            
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST_CODE
            )
        } else {
            // For older versions, check if notifications are enabled
            result.success(hasNotificationPermission())
        }
    }
    
    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.areNotificationsEnabled()
        }
    }
    
    private fun openNotificationSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open notification settings", e)
            result.error("SETTINGS_OPEN_FAILED", "Failed to open notification settings: ${e.message}", null)
        }
    }

    // ==================== OVERLAY PERMISSION METHODS ====================
    
    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Settings.canDrawOverlays(this)) {
                result.success(true)
                return
            }
            
            pendingResult = result
            pendingPermissionType = "overlay"
            
            val intent = Intent().apply {
                action = Settings.ACTION_MANAGE_OVERLAY_PERMISSION
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            try {
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to request overlay permission", e)
                pendingResult = null
                pendingPermissionType = null
                result.error("OVERLAY_REQUEST_FAILED", "Failed to request overlay permission: ${e.message}", null)
            }
        } else {
            // Overlay permission is automatically granted on older versions
            result.success(true)
        }
    }
    
    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // Automatically granted on older versions
        }
    }
    
    private fun openOverlaySettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_MANAGE_OVERLAY_PERMISSION
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open overlay settings", e)
            result.error("SETTINGS_OPEN_FAILED", "Failed to open overlay settings: ${e.message}", null)
        }
    }

    // ==================== USAGE STATS PERMISSION METHODS ====================
    
    private fun requestUsageStatsPermission(result: MethodChannel.Result) {
        if (hasUsageStatsPermission()) {
            result.success(true)
            return
        }
        
        pendingResult = result
        pendingPermissionType = "usage_stats"
        
        val intent = Intent().apply {
            action = Settings.ACTION_USAGE_ACCESS_SETTINGS
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        
        try {
            startActivityForResult(intent, USAGE_STATS_REQUEST_CODE)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request usage stats permission", e)
            pendingResult = null
            pendingPermissionType = null
            result.error("USAGE_STATS_REQUEST_FAILED", "Failed to request usage stats permission: ${e.message}", null)
        }
    }
    
    private fun hasUsageStatsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } else {
            false
        }
    }
    
    private fun openUsageStatsSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_USAGE_ACCESS_SETTINGS
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open usage stats settings", e)
            result.error("SETTINGS_OPEN_FAILED", "Failed to open usage stats settings: ${e.message}", null)
        }
    }

    // ==================== ACCESSIBILITY PERMISSION METHODS ====================
    
    private fun requestAccessibilityPermission(result: MethodChannel.Result) {
        if (hasAccessibilityPermission()) {
            result.success(true)
            return
        }
        
        // For accessibility permission, we can only open settings - cannot directly request
        pendingResult = result
        pendingPermissionType = "accessibility"
        
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_ACCESSIBILITY_SETTINGS
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            // Don't call result.success() here - wait for onResume to check the actual permission status
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open accessibility settings", e)
            pendingResult = null
            pendingPermissionType = null
            result.error("SETTINGS_OPEN_FAILED", "Failed to open accessibility settings: ${e.message}", null)
        }
    }
    
    private fun hasAccessibilityPermission(): Boolean {
        try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            val serviceName = "${packageName}/${FocusAccessibilityService::class.java.name}"
            Log.d(TAG, "Checking accessibility permission for: $serviceName")
            Log.d(TAG, "Enabled services: $enabledServices")
            
            return enabledServices?.contains(serviceName) == true
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility permission", e)
            return false
        }
    }
    
    private fun openAccessibilitySettings(result: MethodChannel.Result) {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_ACCESSIBILITY_SETTINGS
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open accessibility settings", e)
            result.error("SETTINGS_OPEN_FAILED", "Failed to open accessibility settings: ${e.message}", null)
        }
    }

    // ==================== ACTIVITY RESULT HANDLERS ====================
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            DEVICE_ADMIN_REQUEST_CODE -> {
                val isAdminActive = devicePolicyManager.isAdminActive(adminComponent)
                pendingResult?.success(isAdminActive)
                pendingResult = null
                pendingPermissionType = null
            }
            
            OVERLAY_PERMISSION_REQUEST_CODE -> {
                val canDraw = canDrawOverlays()
                pendingResult?.success(canDraw)
                pendingResult = null
                pendingPermissionType = null
            }
            
            USAGE_STATS_REQUEST_CODE -> {
                val hasPermission = hasUsageStatsPermission()
                pendingResult?.success(hasPermission)
                pendingResult = null
                pendingPermissionType = null
            }
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            NOTIFICATION_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingResult?.success(granted)
                pendingResult = null
                pendingPermissionType = null
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        
        // Check if we're returning from a settings screen and have a pending result
        if (pendingResult != null && pendingPermissionType != null) {
            when (pendingPermissionType) {
                "overlay" -> {
                    val canDraw = canDrawOverlays()
                    pendingResult?.success(canDraw)
                    pendingResult = null
                    pendingPermissionType = null
                }
                "usage_stats" -> {
                    val hasPermission = hasUsageStatsPermission()
                    pendingResult?.success(hasPermission)
                    pendingResult = null
                    pendingPermissionType = null
                }
                "notification" -> {
                    val hasPermission = hasNotificationPermission()
                    pendingResult?.success(hasPermission)
                    pendingResult = null
                    pendingPermissionType = null
                }
                "admin" -> {
                    val isAdminActive = devicePolicyManager.isAdminActive(adminComponent)
                    pendingResult?.success(isAdminActive)
                    pendingResult = null
                    pendingPermissionType = null
                }
                "accessibility" -> {
                    val hasPermission = hasAccessibilityPermission()
                    pendingResult?.success(hasPermission)
                    pendingResult = null
                    pendingPermissionType = null
                }
            }
        }
        
        // Notify Flutter that the app has resumed so it can refresh permission states
        try {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onAppResumed", null)
            }
        } catch (e: Exception) {
            Log.d(TAG, "Could not notify Flutter of app resume: ${e.message}")
        }
    }
    
    // ==================== UNINSTALL METHODS ====================
    
    private fun uninstallApp(packageName: String, silent: Boolean, result: MethodChannel.Result) {
        Log.d(TAG, "uninstallApp called with packageName: $packageName, silent: $silent")
        Log.d(TAG, "Admin active: ${devicePolicyManager.isAdminActive(adminComponent)}")
        
        try {
            if (silent && devicePolicyManager.isAdminActive(adminComponent)) {
                Log.d(TAG, "Attempting silent uninstall with admin rights")
                
                // Remove device admin first to allow uninstall
                try {
                    devicePolicyManager.removeActiveAdmin(adminComponent)
                    Log.d(TAG, "Device admin removed successfully")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to remove device admin: ${e.message}")
                }
                
                // Try direct uninstall using system intent
                try {
                    val intent = Intent(Intent.ACTION_DELETE).apply {
                        data = Uri.parse("package:$packageName")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    Log.d(TAG, "Uninstall intent started successfully")
                    result.success(true)
                    return
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start uninstall intent", e)
                }
                
                // If direct method fails, try shell commands
                if (attemptSilentUninstallWithShell(packageName, result)) {
                    return
                }
                
                // If all methods fail, show error
                result.error("SILENT_UNINSTALL_FAILED", "All silent uninstall methods failed", null)
            } else {
                Log.d(TAG, "Using regular uninstall dialog (silent: $silent, admin: ${devicePolicyManager.isAdminActive(adminComponent)})")
                showUninstallDialog(result)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to uninstall app", e)
            result.error("UNINSTALL_FAILED", "Failed to uninstall app: ${e.message}", null)
        }
    }
    
    private fun attemptSilentUninstallWithPackageInstaller(packageName: String, result: MethodChannel.Result): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val packageInstaller = packageManager.packageInstaller
                val params = android.content.pm.PackageInstaller.SessionParams(
                    android.content.pm.PackageInstaller.SessionParams.MODE_FULL_INSTALL
                )
                
                // Create uninstall intent
                val intent = Intent(this, UninstallReceiver::class.java)
                val pendingIntent = android.app.PendingIntent.getBroadcast(
                    this, 0, intent, 
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        android.app.PendingIntent.FLAG_MUTABLE
                    } else {
                        0
                    }
                )
                
                // Attempt silent uninstall
                packageInstaller.uninstall(packageName, pendingIntent.intentSender)
                
                Log.d(TAG, "Silent uninstall initiated via PackageInstaller")
                result.success(true)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "PackageInstaller uninstall failed", e)
            false
        }
    }
    
    private fun attemptSilentUninstallWithShell(packageName: String, result: MethodChannel.Result): Boolean {
        return try {
            Log.d(TAG, "Attempting shell uninstall for package: $packageName")
            
            // Try simple pm uninstall command
            val process = Runtime.getRuntime().exec(arrayOf("pm", "uninstall", packageName))
            val exitCode = process.waitFor()
            
            if (exitCode == 0) {
                Log.d(TAG, "Shell uninstall successful")
                result.success(true)
                return true
            } else {
                Log.w(TAG, "Shell uninstall failed with exit code: $exitCode")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Shell uninstall exception", e)
            false
        }
    }
    
    private fun attemptSilentUninstallWithDeviceOwner(packageName: String, result: MethodChannel.Result): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (devicePolicyManager.isDeviceOwnerApp(this.packageName)) {
                    // If we're device owner, we can try to use system-level uninstall
                    devicePolicyManager.removeActiveAdmin(adminComponent)
                    
                    // Use device owner privileges with PackageInstaller
                    val packageInstaller = packageManager.packageInstaller
                    val intent = Intent(this, UninstallReceiver::class.java)
                    val pendingIntent = android.app.PendingIntent.getBroadcast(
                        this, 0, intent,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            android.app.PendingIntent.FLAG_MUTABLE
                        } else {
                            0
                        }
                    )
                    
                    packageInstaller.uninstall(packageName, pendingIntent.intentSender)
                    Log.d(TAG, "Silent uninstall initiated via device owner")
                    result.success(true)
                    return true
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Device owner uninstall failed", e)
            false
        }
    }
    
    private fun showUninstallDialog(result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show uninstall dialog", e)
            result.error("UNINSTALL_DIALOG_FAILED", "Failed to show uninstall dialog: ${e.message}", null)
        }
    }
    
    private fun canPerformSilentUninstall(): Boolean {
        return devicePolicyManager.isAdminActive(adminComponent) || 
               (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && 
                devicePolicyManager.isDeviceOwnerApp(packageName))
    }
    
    // ==================== DEVICE LOCK METHODS ====================
    
    private fun startDeviceLock(durationMs: Long, result: MethodChannel.Result) {
        try {
            // Check if we have device admin permission
            if (!devicePolicyManager.isAdminActive(adminComponent)) {
                result.error("NO_ADMIN_PERMISSION", "Device admin permission is required", null)
                return
            }
            
            // Check if we have overlay permission
            if (!canDrawOverlays()) {
                result.error("NO_OVERLAY_PERMISSION", "System overlay permission is required", null)
                return
            }
            
            // Enable kiosk mode
            enableKioskMode()
            
            // Start lock mode
            isLockModeActive = true
            lockStartTime = System.currentTimeMillis()
            lockDurationMs = durationMs
            
            // Start the lock screen service
            val serviceIntent = Intent(this, LockScreenService::class.java).apply {
                action = LockScreenService.ACTION_START_LOCK
                putExtra(LockScreenService.EXTRA_DURATION_SECONDS, (durationMs / 1000).toInt())
            }
            startService(serviceIntent)
            
            // Start timer to automatically end lock
            startLockTimer(durationMs)
            
            // Lock the device immediately
            devicePolicyManager.lockNow()
            
            Log.d(TAG, "Device lock started successfully for ${durationMs}ms")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start device lock", e)
            result.error("DEVICE_LOCK_FAILED", "Failed to start device lock: ${e.message}", null)
        }
    }
    
    private fun endDeviceLock(result: MethodChannel.Result) {
        try {
            // Disable kiosk mode
            disableKioskMode()
            
            // Stop lock mode
            isLockModeActive = false
            lockTimer?.cancel()
            lockTimer = null
            
            // Stop the lock screen service
            val serviceIntent = Intent(this, LockScreenService::class.java).apply {
                action = LockScreenService.ACTION_STOP_LOCK
            }
            startService(serviceIntent)
            
            Log.d(TAG, "Device lock ended")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to end device lock", e)
            result.error("DEVICE_UNLOCK_FAILED", "Failed to end device lock: ${e.message}", null)
        }
    }
    
    private fun enableKioskMode() {
        try {
            // Set flags to prevent user from leaving the app
            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
            
            // Hide system UI
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                window.decorView.systemUiVisibility = (
                    android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
                    android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                )
            }
            
            Log.d(TAG, "Kiosk mode enabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable kiosk mode", e)
        }
    }
    
    private fun disableKioskMode() {
        try {
            // Clear flags
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
            
            // Restore system UI
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                window.decorView.systemUiVisibility = android.view.View.SYSTEM_UI_FLAG_VISIBLE
            }
            
            Log.d(TAG, "Kiosk mode disabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable kiosk mode", e)
        }
    }
    
    private fun startLockTimer(durationMs: Long) {
        lockTimer?.cancel()
        lockTimer = Timer()
        
        lockTimer?.schedule(object : TimerTask() {
            override fun run() {
                runOnUiThread {
                    // Automatically end lock when timer expires
                    endDeviceLock(object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            Log.d(TAG, "Lock timer expired, lock ended automatically")
                        }
                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            Log.e(TAG, "Failed to end lock automatically: $errorMessage")
                        }
                        override fun notImplemented() {}
                    })
                }
            }
        }, durationMs)
    }
    
    // Override key events to prevent back button and home button
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isLockModeActive) {
            when (keyCode) {
                KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_HOME,
                KeyEvent.KEYCODE_MENU,
                KeyEvent.KEYCODE_APP_SWITCH -> {
                    Log.d(TAG, "Blocked key event: $keyCode during lock mode")
                    return true // Block the key event
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }
    
    // Prevent app from being moved to background during lock mode
    override fun onUserLeaveHint() {
        if (isLockModeActive) {
            Log.d(TAG, "Prevented app from going to background during lock mode")
            return // Don't call super to prevent backgrounding
        }
        super.onUserLeaveHint()
    }
    
    // Handle app lifecycle to maintain lock
    override fun onPause() {
        if (isLockModeActive) {
            Log.d(TAG, "App paused during lock mode, bringing back to foreground")
            // Bring app back to foreground immediately
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
        }
        super.onPause()
    }
}
