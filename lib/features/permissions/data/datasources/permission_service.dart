import 'package:focuslock/features/permissions/data/datasources/platform_permission_service.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/permission.dart' as domain;
import '../models/permission_model.dart';

abstract class PermissionService {
  Future<PermissionModel> requestPermission(domain.PermissionType type);
  Future<PermissionModel> getPermissionStatus(domain.PermissionType type);
  Future<List<PermissionModel>> getAllPermissionStatuses();
  Future<void> openPermissionSettings(domain.PermissionType type);
}

@LazySingleton(as: PermissionService)
class PermissionServiceImpl implements PermissionService {
  final PlatformPermissionService _platformPermissionService;

  PermissionServiceImpl(this._platformPermissionService);
  @override
  Future<PermissionModel> requestPermission(domain.PermissionType type) async {
    try {
      final status = await _platformPermissionService.requestPermission(type);

      return PermissionModel(
        type: type,
        status: status,
        title: type.displayName,
        description: type.description,
        icon: type.icon,
      );
    } catch (e) {
      throw PermissionFailure(
        'Failed to request ${type.displayName} permission: ${e.toString()}',
      );
    }
  }

  @override
  Future<PermissionModel> getPermissionStatus(
    domain.PermissionType type,
  ) async {
    try {
      final status = await _platformPermissionService.getPermissionStatus(type);

      return PermissionModel(
        type: type,
        status: status,
        title: type.displayName,
        description: type.description,
        icon: type.icon,
      );
    } catch (e) {
      throw PermissionFailure(
        'Failed to get ${type.displayName} permission status: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PermissionModel>> getAllPermissionStatuses() async {
    try {
      final permissions = await _platformPermissionService.getAllPermissions();
      return permissions
          .map(
            (permission) => PermissionModel(
              type: permission.type,
              status: permission.status,
              title: permission.title,
              description: permission.description,
              icon: permission.icon,
            ),
          )
          .toList();
    } catch (e) {
      throw PermissionFailure(
        'Failed to get all permission statuses: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> openPermissionSettings(domain.PermissionType type) async {
    try {
      await _platformPermissionService.openPermissionSettings(type);
    } catch (e) {
      throw PermissionFailure(
        'Failed to open settings for ${type.displayName}: ${e.toString()}',
      );
    }
  }
}
