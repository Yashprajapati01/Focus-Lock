package com.example.focuslock

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.*

class LockActivity : Activity() {
    
    private lateinit var sharedPrefs: SharedPreferences
    private lateinit var timerTextView: TextView
    private lateinit var messageTextView: TextView
    private var timer: Timer? = null
    private var remainingSeconds = 0
    
    private val lockUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_UPDATE_TIMER -> {
                    val remaining = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 0)
                    updateTimer(remaining)
                }
                ACTION_END_SESSION -> {
                    endSession()
                }
            }
        }
    }
    
    companion object {
        private const val TAG = "LockActivity"
        private const val PREFS_NAME = "focus_lock_prefs"
        private const val KEY_SESSION_ACTIVE = "session_active"
        private const val KEY_REMAINING_SECONDS = "remaining_seconds"
        
        const val ACTION_UPDATE_TIMER = "com.focuslock.UPDATE_TIMER"
        const val ACTION_END_SESSION = "com.focuslock.END_SESSION"
        const val EXTRA_REMAINING_SECONDS = "remaining_seconds"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        sharedPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        
        setupFullscreenFlags()
        createLockUI()
        registerReceiver()
        
        // Get initial remaining time
        remainingSeconds = sharedPrefs.getInt(KEY_REMAINING_SECONDS, 60)
        updateTimer(remainingSeconds)
        
        Log.d(TAG, "LockActivity created")
    }
    
    private fun setupFullscreenFlags() {
        // Make this activity fullscreen and prevent user interaction with system
        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        
        // Hide system UI
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )
    }
    
    private fun createLockUI() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF000000.toInt())
            setPadding(48, 48, 48, 48)
        }
        
        // Title
        val titleTextView = TextView(this).apply {
            text = "🔒 Focus Mode Active"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        }
        
        // Timer display
        timerTextView = TextView(this).apply {
            text = "00:00"
            textSize = 48f
            setTextColor(0xFF4CAF50.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 32)
        }
        
        // Message
        messageTextView = TextView(this).apply {
            text = "Stay focused! You cannot exit until the timer expires.\n\nTake deep breaths and concentrate on your goals."
            textSize = 16f
            setTextColor(0xFFCCCCCC.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
        }
        
        layout.addView(titleTextView)
        layout.addView(timerTextView)
        layout.addView(messageTextView)
        
        setContentView(layout)
    }
    
    private fun registerReceiver() {
        val filter = IntentFilter().apply {
            addAction(ACTION_UPDATE_TIMER)
            addAction(ACTION_END_SESSION)
        }
        registerReceiver(lockUpdateReceiver, filter)
    }
    
    private fun updateTimer(seconds: Int) {
        remainingSeconds = seconds
        
        runOnUiThread {
            timerTextView.text = formatTime(seconds)
            
            if (seconds <= 0) {
                endSession()
            }
        }
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
    
    private fun endSession() {
        // Mark session as inactive
        sharedPrefs.edit()
            .putBoolean(KEY_SESSION_ACTIVE, false)
            .putInt(KEY_REMAINING_SECONDS, 0)
            .apply()
        
        // Show completion message
        runOnUiThread {
            messageTextView.text = "🎉 Focus session completed!\n\nGreat job! You can now return to the main app."
            timerTextView.text = "DONE"
            timerTextView.setTextColor(0xFF4CAF50.toInt())
        }
        
        // Auto-close after 3 seconds
        timer?.cancel()
        timer = Timer()
        timer?.schedule(object : TimerTask() {
            override fun run() {
                runOnUiThread {
                    finish()
                }
            }
        }, 3000)
        
        Log.d(TAG, "Session ended")
    }
    
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Block all key events (back, home, recent apps)
        return when (keyCode) {
            KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_HOME,
            KeyEvent.KEYCODE_APP_SWITCH -> {
                Log.d(TAG, "Blocked key event: $keyCode")
                true // Consume the event
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) {
            // If we lose focus, try to regain it
            Log.d(TAG, "Lost focus, attempting to regain")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
        try {
            unregisterReceiver(lockUpdateReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister receiver", e)
        }
        Log.d(TAG, "LockActivity destroyed")
    }
}