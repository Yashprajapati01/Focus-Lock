import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'dart:io';

abstract class DeviceAdminService {
  /// Check if device admin permission is granted
  Future<bool> hasDeviceAdminPermission();

  /// Check if system overlay permission is granted
  Future<bool> hasOverlayPermission();

  /// Start device lock mode
  Future<void> startDeviceLock();

  /// End device lock mode
  Future<void> endDeviceLock();

  /// Request device admin permission
  Future<bool> requestDeviceAdminPermission();

  /// Request system overlay permission
  Future<bool> requestOverlayPermission();

  /// Check if accessibility service permission is granted
  Future<bool> hasAccessibilityPermission();

  /// Request accessibility service permission
  Future<bool> requestAccessibilityPermission();
}

@LazySingleton(as: DeviceAdminService)
class DeviceAdminServiceImpl implements DeviceAdminService {
  static const MethodChannel _channel = MethodChannel(
    'com.focuslock/device_admin',
  );

  bool _isLocked = false;

  @override
  Future<bool> hasDeviceAdminPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool hasPermission = await _channel.invokeMethod(
        'hasDeviceAdminPermission',
      );
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking device admin permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> hasOverlayPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool hasPermission = await _channel.invokeMethod(
        'hasOverlayPermission',
      );
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> startDeviceLock() async {
    await startDeviceLockWithDuration(const Duration(minutes: 1));
  }

  /// Start device lock with specific duration
  Future<void> startDeviceLockWithDuration(Duration duration) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Device locking is only supported on Android');
    }

    try {
      // Check permissions first
      final hasAdmin = await hasDeviceAdminPermission();
      final hasOverlay = await hasOverlayPermission();

      if (!hasAdmin) {
        throw Exception('Device admin permission is required');
      }

      if (!hasOverlay) {
        throw Exception('System overlay permission is required');
      }

      final hasAccessibility = await hasAccessibilityPermission();
      if (!hasAccessibility) {
        throw Exception('Accessibility service permission is required');
      }

      await _channel.invokeMethod('startDeviceLock', {
        'durationMs': duration.inMilliseconds,
      });
      _isLocked = true;
    } on PlatformException catch (e) {
      throw Exception('Failed to start device lock: ${e.message}');
    }
  }

  @override
  Future<void> endDeviceLock() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('endDeviceLock');
      _isLocked = false;
    } on PlatformException catch (e) {
      print('Error ending device lock: ${e.message}');
      _isLocked = false; // Reset state even if call fails
    }
  }

  @override
  Future<bool> requestDeviceAdminPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool granted = await _channel.invokeMethod(
        'requestDeviceAdminPermission',
      );
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting device admin permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool granted = await _channel.invokeMethod(
        'requestOverlayPermission',
      );
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting overlay permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> hasAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool hasPermission = await _channel.invokeMethod(
        'hasAccessibilityPermission',
      );
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking accessibility permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool granted = await _channel.invokeMethod(
        'requestAccessibilityPermission',
      );
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting accessibility permission: ${e.message}');
      return false;
    }
  }

  /// Check if device is currently locked
  bool get isLocked => _isLocked;
}
