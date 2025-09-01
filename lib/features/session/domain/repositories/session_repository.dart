import '../entities/session_config.dart';

abstract class SessionRepository {
  /// Load saved session configuration from local storage
  Future<SessionConfig> loadSessionConfig();

  /// Save session configuration to local storage
  Future<void> saveSessionConfig(SessionConfig config);

  /// Start device lock using admin permissions
  Future<void> startDeviceLock();

  /// Start device lock with specific duration
  Future<void> startDeviceLockWithDuration(Duration duration);

  /// End device lock and restore normal device access
  Future<void> endDeviceLock();

  /// Check if all required permissions are granted
  Future<bool> hasRequiredPermissions();

  /// Check if device admin permission is granted
  Future<bool> hasDeviceAdminPermission();

  /// Check if system overlay permission is granted
  Future<bool> hasOverlayPermission();
}
