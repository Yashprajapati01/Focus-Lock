package com.example.focuslock

import android.Manifest
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
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "focuslock/permissions"
    private val DEVICE_ADMIN_REQUEST_CODE = 1001
    private val OVERLAY_PERMISSION_REQUEST_CODE = 1002
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003
    private val USAGE_STATS_REQUEST_CODE = 1004
    
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPermissionType: String? = null

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
}
