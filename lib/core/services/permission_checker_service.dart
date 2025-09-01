import 'dart:io';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PermissionCheckerService {
  static const MethodChannel _channel = MethodChannel('focuslock/permissions');

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    if (!Platform.isAndroid) return true;

    try {
      print('=== CHECKING ALL PERMISSIONS ===');

      // Check all required permissions
      final results = await Future.wait([
        _hasNotificationPermission(),
        _hasAdminPermission(),
        _hasOverlayPermission(),
        _hasUsageStatsPermission(),
        _hasAccessibilityPermission(),
      ]);

      final permissions = [
        'Notification',
        'Admin',
        'Overlay',
        'Usage Stats',
        'Accessibility',
      ];

      for (int i = 0; i < results.length; i++) {
        print('${permissions[i]}: ${results[i]}');
      }

      final allGranted = results.every((granted) => granted == true);
      print('All permissions granted: $allGranted');
      print('================================');

      return allGranted;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  Future<bool> _hasNotificationPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasNotificationPermission') ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasAdminPermission() async {
    try {
      return await _channel.invokeMethod<bool>('isAdminActive') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasAccessibilityPermission') ??
          false;
    } catch (e) {
      return false;
    }
  }
}
