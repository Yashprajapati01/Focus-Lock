import 'package:injectable/injectable.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';
import '../models/session_config_model.dart';
import '../services/device_admin_service.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  final SessionLocalDataSource localDataSource;
  final DeviceAdminService deviceAdminService;

  SessionRepositoryImpl({
    required this.localDataSource,
    required this.deviceAdminService,
  });

  @override
  Future<SessionConfig> loadSessionConfig() async {
    try {
      return await localDataSource.getSessionConfig();
    } catch (e) {
      // Return default config if loading fails
      return const SessionConfig(
        duration: Duration(minutes: 30),
        lastUsed: null,
      );
    }
  }

  @override
  Future<void> saveSessionConfig(SessionConfig config) async {
    final configModel = SessionConfigModel.fromEntity(config);
    await localDataSource.cacheSessionConfig(configModel);
  }

  @override
  Future<void> startDeviceLock() async {
    final hasPermissions = await hasRequiredPermissions();
    if (!hasPermissions) {
      throw Exception('Required permissions not granted for device lock');
    }

    await deviceAdminService.startDeviceLock();
  }

  @override
  Future<void> startDeviceLockWithDuration(Duration duration) async {
    final hasPermissions = await hasRequiredPermissions();
    if (!hasPermissions) {
      throw Exception('Required permissions not granted for device lock');
    }

    if (deviceAdminService is DeviceAdminServiceImpl) {
      await (deviceAdminService as DeviceAdminServiceImpl)
          .startDeviceLockWithDuration(duration);
    } else {
      await deviceAdminService.startDeviceLock();
    }
  }

  @override
  Future<void> endDeviceLock() async {
    await deviceAdminService.endDeviceLock();
  }

  @override
  Future<bool> hasRequiredPermissions() async {
    final hasAdmin = await hasDeviceAdminPermission();
    final hasOverlay = await hasOverlayPermission();
    return hasAdmin && hasOverlay;
  }

  @override
  Future<bool> hasDeviceAdminPermission() async {
    return await deviceAdminService.hasDeviceAdminPermission();
  }

  @override
  Future<bool> hasOverlayPermission() async {
    return await deviceAdminService.hasOverlayPermission();
  }
}
