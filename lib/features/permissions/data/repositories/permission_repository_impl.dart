import 'package:dartz/dartz.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedef.dart';
import '../../domain/repositories/permission_repository.dart';
import '../datasources/permission_service.dart';
import '../datasources/permission_storage_service.dart';
import '../models/permission_progress_model.dart';

@LazySingleton(as: PermissionRepository)
class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionService _permissionService;
  final PermissionStorageService _storageService;

  PermissionRepositoryImpl(this._permissionService, this._storageService);

  @override
  ResultFuture<Permission> requestPermission(PermissionType type) async {
    try {
      final permission = await _permissionService.requestPermission(type);
      await _storageService.savePermission(permission);
      return Right(permission);
    } on PermissionFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        PermissionFailure(
          'Unexpected error requesting permission: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultFuture<Permission> getPermissionStatus(PermissionType type) async {
    try {
      // First try to get fresh status from system
      final permission = await _permissionService.getPermissionStatus(type);
      await _storageService.savePermission(permission);
      return Right(permission);
    } on PermissionFailure catch (e) {
      // If system check fails, try to get cached status
      try {
        final cachedPermission = await _storageService.getPermission(type);
        if (cachedPermission != null) {
          return Right(cachedPermission);
        }
        return Left(e);
      } catch (cacheError) {
        return Left(e);
      }
    } catch (e) {
      return Left(
        PermissionFailure(
          'Unexpected error getting permission status: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultFuture<List<Permission>> getAllPermissionStatuses() async {
    try {
      final permissions = await _permissionService.getAllPermissionStatuses();
      await _storageService.savePermissions(permissions);
      return Right(permissions.cast<Permission>());
    } on PermissionFailure catch (e) {
      // If system check fails, try to get cached permissions
      try {
        final cachedPermissions = await _storageService.getPermissions();
        return Right(cachedPermissions.cast<Permission>());
      } catch (cacheError) {
        return Left(e);
      }
    } catch (e) {
      return Left(
        PermissionFailure(
          'Unexpected error getting all permissions: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultFuture<PermissionProgress> getPermissionProgress() async {
    try {
      final permissionsResult = await getAllPermissionStatuses();
      return permissionsResult.fold((failure) => Left(failure), (permissions) {
        final grantedCount = permissions.where((p) => p.isGranted).length;
        final progress = PermissionProgressModel.fromGrantedCount(
          grantedCount,
          permissions.length,
        );
        return Right(progress);
      });
    } catch (e) {
      return Left(
        PermissionFailure(
          'Failed to calculate permission progress: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultFuture<bool> areAllPermissionsGranted() async {
    try {
      final progressResult = await getPermissionProgress();
      return progressResult.fold(
        (failure) => Left(failure),
        (progress) => Right(progress.isComplete),
      );
    } catch (e) {
      return Left(
        PermissionFailure(
          'Failed to check if all permissions are granted: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultVoid openPermissionSettings(PermissionType type) async {
    try {
      await _permissionService.openPermissionSettings(type);
      return const Right(null);
    } on PermissionFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        PermissionFailure(
          'Failed to open permission settings: ${e.toString()}',
        ),
      );
    }
  }
}
