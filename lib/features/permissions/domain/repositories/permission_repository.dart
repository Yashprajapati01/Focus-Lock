import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';

import '../../../../core/utils/typedef.dart';

abstract class PermissionRepository {
  /// Request a specific permission from the system
  ResultFuture<Permission> requestPermission(PermissionType type);

  /// Get current status of a specific permission
  ResultFuture<Permission> getPermissionStatus(PermissionType type);

  /// Get status of all permissions
  ResultFuture<List<Permission>> getAllPermissionStatuses();

  /// Get permission progress (granted vs total)
  ResultFuture<PermissionProgress> getPermissionProgress();

  /// Check if all permissions are granted
  ResultFuture<bool> areAllPermissionsGranted();

  /// Open system settings for a specific permission
  ResultVoid openPermissionSettings(PermissionType type);
}
