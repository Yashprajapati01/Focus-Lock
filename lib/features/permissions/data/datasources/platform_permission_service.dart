import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart'
    as domain;
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/errors/failures.dart';

abstract class PlatformPermissionService {
  Future<domain.PermissionStatus> requestPermission(domain.PermissionType type);
  Future<domain.PermissionStatus> getPermissionStatus(
    domain.PermissionType type,
  );
  Future<void> openPermissionSettings(domain.PermissionType type);
  Future<List<domain.Permission>> getAllPermissions();
}

@LazySingleton(as: PlatformPermissionService)
class PlatformPermissionServiceImpl implements PlatformPermissionService {
  static const MethodChannel _channel = MethodChannel('focuslock/permissions');

  // Stream controller for app resume events
  static final _appResumeController = StreamController<void>.broadcast();
  static Stream<void> get onAppResumed => _appResumeController.stream;

  PlatformPermissionServiceImpl() {
    // Set up method call handler for native callbacks
    _channel.setMethodCallHandler(_handleMethodCall);

    // Listen to app resume events to refresh permission status
    onAppResumed.listen((_) {
      // Small delay to ensure system state is updated
      Future.delayed(const Duration(milliseconds: 300), () {
        _appResumeController.add(null);
      });
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppResumed':
        _appResumeController.add(null);
        break;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  @override
  Future<domain.PermissionStatus> requestPermission(
    domain.PermissionType type,
  ) async {
    try {
      switch (type) {
        case domain.PermissionType.notification:
          return await _requestNotificationPermission();
        case domain.PermissionType.admin:
          return await _requestAdminPermission();
        case domain.PermissionType.overlay:
          return await _requestOverlayPermission();
        case domain.PermissionType.calling:
          return await _requestCallingPermission();
        case domain.PermissionType.accessibility:
          return await _requestAccessibilityPermission();
      }
    } catch (e) {
      throw PermissionFailure(
        'Failed to request ${type.displayName}: ${e.toString()}',
      );
    }
  }

  @override
  Future<domain.PermissionStatus> getPermissionStatus(
    domain.PermissionType type,
  ) async {
    try {
      switch (type) {
        case domain.PermissionType.notification:
          return await _getNotificationPermissionStatus();
        case domain.PermissionType.admin:
          return await _getAdminPermissionStatus();
        case domain.PermissionType.overlay:
          return await _getOverlayPermissionStatus();
        case domain.PermissionType.calling:
          return await _getCallingPermissionStatus();
        case domain.PermissionType.accessibility:
          return await _getAccessibilityPermissionStatus();
      }
    } catch (e) {
      // Return pending if we can't check the status
      return domain.PermissionStatus.pending;
    }
  }

  @override
  Future<void> openPermissionSettings(domain.PermissionType type) async {
    try {
      switch (type) {
        case domain.PermissionType.notification:
          await _openNotificationSettings();
          break;
        case domain.PermissionType.admin:
          await _openAdminSettings();
          break;
        case domain.PermissionType.overlay:
          await _openOverlaySettings();
          break;
        case domain.PermissionType.calling:
          await _openUsageStatsSettings();
          break;
        case domain.PermissionType.accessibility:
          await _openAccessibilitySettings();
          break;
      }
    } catch (e) {
      throw PermissionFailure(
        'Failed to open settings for ${type.displayName}: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<domain.Permission>> getAllPermissions() async {
    final permissions = <domain.Permission>[];

    for (final type in domain.PermissionType.values) {
      final status = await getPermissionStatus(type);
      permissions.add(
        domain.Permission(
          type: type,
          status: status,
          title: type.displayName,
          description: type.description,
          icon: type.icon,
        ),
      );
    }

    return permissions;
  }

  // Notification Permission Methods
  Future<domain.PermissionStatus> _requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'requestNotificationPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.denied;
      } else {
        // iOS fallback to permission_handler
        final permission = Permission.notification;
        final status = await permission.request();
        return _convertPermissionStatus(status);
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to request notification permission: ${e.message}',
      );
    }
  }

  Future<domain.PermissionStatus> _getNotificationPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'hasNotificationPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        // iOS fallback to permission_handler
        final permission = Permission.notification;
        final status = await permission.status;
        return _convertPermissionStatus(status);
      }
    } catch (e) {
      return domain.PermissionStatus.pending;
    }
  }

  // Admin Permission Methods
  Future<domain.PermissionStatus> _requestAdminPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'requestAdminPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.denied;
      } else {
        // iOS doesn't have device admin permissions
        return domain.PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      if (e.code == 'UNIMPLEMENTED') {
        // If not implemented, open settings manually
        await openAppSettings();
        return domain.PermissionStatus.pending;
      }
      throw PermissionFailure(
        'Failed to request admin permission: ${e.message}',
      );
    }
  }

  Future<domain.PermissionStatus> _getAdminPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('isAdminActive');
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        return domain.PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      if (e.code == 'UNIMPLEMENTED') {
        return domain.PermissionStatus.pending;
      }
      return domain.PermissionStatus.pending;
    }
  }

  Future<void> _openAdminSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openAdminSettings');
      } else {
        await openAppSettings();
      }
    } on PlatformException catch (e) {
      if (e.code == 'UNIMPLEMENTED') {
        await openAppSettings();
      } else {
        throw PermissionFailure('Failed to open admin settings: ${e.message}');
      }
    }
  }

  // Overlay Permission Methods
  Future<domain.PermissionStatus> _requestOverlayPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'requestOverlayPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.denied;
      } else {
        // iOS doesn't have overlay permissions in the same way
        return domain.PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to request overlay permission: ${e.message}',
      );
    }
  }

  Future<domain.PermissionStatus> _getOverlayPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('canDrawOverlays');
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        return domain.PermissionStatus.denied;
      }
    } catch (e) {
      return domain.PermissionStatus.pending;
    }
  }

  Future<void> _openOverlaySettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openOverlaySettings');
      } else {
        await openAppSettings();
      }
    } on PlatformException catch (e) {
      throw PermissionFailure('Failed to open overlay settings: ${e.message}');
    }
  }

  // Usage Stats Permission Methods (replaces calling permission)
  Future<domain.PermissionStatus> _requestCallingPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'requestUsageStatsPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.denied;
      } else {
        // iOS fallback - no equivalent permission
        return domain.PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to request usage stats permission: ${e.message}',
      );
    }
  }

  Future<domain.PermissionStatus> _getCallingPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'hasUsageStatsPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        return domain.PermissionStatus.denied;
      }
    } catch (e) {
      return domain.PermissionStatus.pending;
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openNotificationSettings');
      } else {
        await openAppSettings();
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to open notification settings: ${e.message}',
      );
    }
  }

  Future<void> _openUsageStatsSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openUsageStatsSettings');
      } else {
        await openAppSettings();
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to open usage stats settings: ${e.message}',
      );
    }
  }

  // Accessibility Permission Methods
  Future<domain.PermissionStatus> _requestAccessibilityPermission() async {
    try {
      if (Platform.isAndroid) {
        // Check if already granted
        final hasPermission = await _channel.invokeMethod<bool>(
          'hasAccessibilityPermission',
        );

        if (hasPermission == true) {
          return domain.PermissionStatus.granted;
        }

        // For accessibility permission, we can only open settings
        final result = await _channel.invokeMethod<bool>(
          'requestAccessibilityPermission',
        );

        // The result indicates if the settings were opened successfully
        // We need to check the actual permission status after user returns
        final finalStatus = await _channel.invokeMethod<bool>(
          'hasAccessibilityPermission',
        );

        return finalStatus == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        // iOS doesn't have accessibility service permissions in the same way
        return domain.PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to request accessibility permission: ${e.message}',
      );
    }
  }

  Future<domain.PermissionStatus> _getAccessibilityPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        // Add a small delay to ensure the service state is updated
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await _channel.invokeMethod<bool>(
          'hasAccessibilityPermission',
        );
        return result == true
            ? domain.PermissionStatus.granted
            : domain.PermissionStatus.pending;
      } else {
        return domain.PermissionStatus.denied;
      }
    } catch (e) {
      return domain.PermissionStatus.pending;
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openAccessibilitySettings');
      } else {
        await openAppSettings();
      }
    } on PlatformException catch (e) {
      throw PermissionFailure(
        'Failed to open accessibility settings: ${e.message}',
      );
    }
  }

  // Helper method to convert permission_handler status to domain status
  domain.PermissionStatus _convertPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return domain.PermissionStatus.granted;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return domain.PermissionStatus.denied;
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return domain.PermissionStatus.granted; // Treat limited as granted
    }
  }
}
