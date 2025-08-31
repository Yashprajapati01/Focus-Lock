package com.example.focuslock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.util.Log

class UninstallReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "UninstallReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        val status = intent?.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        
        when (status) {
            PackageInstaller.STATUS_SUCCESS -> {
                Log.d(TAG, "App uninstalled successfully")
                // App has been uninstalled successfully
            }
            PackageInstaller.STATUS_FAILURE -> {
                val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                Log.e(TAG, "Uninstall failed: $message")
            }
            PackageInstaller.STATUS_FAILURE_ABORTED -> {
                Log.w(TAG, "Uninstall aborted by user")
            }
            PackageInstaller.STATUS_FAILURE_BLOCKED -> {
                Log.w(TAG, "Uninstall blocked")
            }
            PackageInstaller.STATUS_FAILURE_CONFLICT -> {
                Log.w(TAG, "Uninstall conflict")
            }
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE -> {
                Log.w(TAG, "Uninstall incompatible")
            }
            PackageInstaller.STATUS_FAILURE_INVALID -> {
                Log.w(TAG, "Uninstall invalid")
            }
            PackageInstaller.STATUS_FAILURE_STORAGE -> {
                Log.w(TAG, "Uninstall storage failure")
            }
            else -> {
                Log.w(TAG, "Unknown uninstall status: $status")
            }
        }
    }
}