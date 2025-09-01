package com.example.focuslock

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.*

class LockScreenService : Service() {
    
    private lateinit var sharedPrefs: SharedPreferences
    private var timer: Timer? = null
    private var remainingSeconds = 0
    private var isSessionActive = false
    
    companion object {
        private const val TAG = "LockScreenService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "focus_lock_channel"
        private const val PREFS_NAME = "focus_lock_prefs"
        private const val KEY_SESSION_ACTIVE = "session_active"
        private const val KEY_REMAINING_SECONDS = "remaining_seconds"
        
        const val ACTION_START_LOCK = "START_LOCK"
        const val ACTION_STOP_LOCK = "STOP_LOCK"
        const val ACTION_UPDATE_TIMER = "UPDATE_TIMER"
        const val EXTRA_DURATION_SECONDS = "duration_seconds"
        const val EXTRA_REMAINING_SECONDS = "remaining_seconds"
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        sharedPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        createNotificationChannel()
        Log.d(TAG, "LockScreenService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_LOCK -> {
                val durationSeconds = intent.getIntExtra(EXTRA_DURATION_SECONDS, 60)
                startLockSession(durationSeconds)
            }
            ACTION_STOP_LOCK -> {
                stopLockSession()
            }
            ACTION_UPDATE_TIMER -> {
                val remaining = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
                updateTimer(remaining)
            }
        }
        return START_STICKY // Restart service if killed
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Lock Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when a focus session is active"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun startLockSession(durationSeconds: Int) {
        if (isSessionActive) return
        
        try {
            remainingSeconds = durationSeconds
            isSessionActive = true
            
            // Save session state
            sharedPrefs.edit()
                .putBoolean(KEY_SESSION_ACTIVE, true)
                .putInt(KEY_REMAINING_SECONDS, remainingSeconds)
                .putString("lock_package", packageName)
                .apply()
            
            // Start foreground service with notification
            startForeground(NOTIFICATION_ID, createNotification())
            
            // Launch lock activity
            launchLockActivity()
            
            // Start countdown timer
            startTimer()
            
            Log.d(TAG, "Lock session started for $durationSeconds seconds")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start lock session", e)
        }
    }
    
    private fun launchLockActivity() {
        val intent = Intent(this, LockActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                     Intent.FLAG_ACTIVITY_CLEAR_TOP or
                     Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(this, LockScreenService::class.java).apply {
            action = ACTION_STOP_LOCK
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Session Active")
            .setContentText("Time remaining: ${formatTime(remainingSeconds)}")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Emergency Stop",
                stopPendingIntent
            )
            .build()
    }
    
    private fun startTimer() {
        timer?.cancel()
        timer = Timer()
        
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                remainingSeconds--
                
                // Update shared preferences
                sharedPrefs.edit()
                    .putInt(KEY_REMAINING_SECONDS, remainingSeconds)
                    .apply()
                
                // Update notification
                updateNotification()
                
                // Broadcast timer update to LockActivity
                broadcastTimerUpdate()
                
                if (remainingSeconds <= 0) {
                    stopLockSession()
                } else {
                    // Ensure lock activity is still in foreground
                    ensureLockActivityForeground()
                }
            }
        }, 1000, 1000)
    }
    
    private fun ensureLockActivityForeground() {
        // This will be handled by the AccessibilityService
        // But we can also launch it here as a backup
        try {
            val intent = Intent(this, LockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                         Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not ensure lock activity foreground", e)
        }
    }
    
    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun broadcastTimerUpdate() {
        val intent = Intent(LockActivity.ACTION_UPDATE_TIMER).apply {
            putExtra(LockActivity.EXTRA_REMAINING_SECONDS, remainingSeconds)
        }
        sendBroadcast(intent)
    }
    
    private fun updateTimer(remaining: Int) {
        remainingSeconds = remaining
        
        // Update shared preferences
        sharedPrefs.edit()
            .putInt(KEY_REMAINING_SECONDS, remainingSeconds)
            .apply()
        
        // Update notification
        updateNotification()
        
        // Broadcast to lock activity
        broadcastTimerUpdate()
        
        Log.d(TAG, "Timer updated: $remaining seconds remaining")
    }
    
    private fun formatTime(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        
        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, secs)
            else -> String.format("%d:%02d", minutes, secs)
        }
    }
    
    private fun stopLockSession() {
        try {
            timer?.cancel()
            timer = null
            isSessionActive = false
            
            // Update session state
            sharedPrefs.edit()
                .putBoolean(KEY_SESSION_ACTIVE, false)
                .putInt(KEY_REMAINING_SECONDS, 0)
                .apply()
            
            // Broadcast session end to lock activity
            val intent = Intent(LockActivity.ACTION_END_SESSION)
            sendBroadcast(intent)
            
            Log.d(TAG, "Lock session stopped")
            
            // Stop foreground service
            stopForeground(true)
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop lock session", e)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopLockSession()
        Log.d(TAG, "LockScreenService destroyed")
    }
}