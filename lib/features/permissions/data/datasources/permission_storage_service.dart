import 'dart:convert';
import 'package:focuslock/features/permissions/data/models/permission_model.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';

abstract class PermissionStorageService {
  Future<void> savePermissions(List<PermissionModel> permissions);
  Future<List<PermissionModel>> getPermissions();
  Future<void> savePermission(PermissionModel permission);
  Future<PermissionModel?> getPermission(PermissionType type);
  Future<void> clearPermissions();
}

@LazySingleton(as: PermissionStorageService)
class PermissionStorageServiceImpl implements PermissionStorageService {
  static const String _permissionsKey = 'cached_permissions';

  final SharedPreferences _prefs;

  PermissionStorageServiceImpl(this._prefs);

  @override
  Future<void> savePermissions(List<PermissionModel> permissions) async {
    try {
      final permissionsJson = permissions.map((p) => p.toJson()).toList();
      final jsonString = json.encode(permissionsJson);
      await _prefs.setString(_permissionsKey, jsonString);
    } catch (e) {
      throw SystemFailure('Failed to save permissions: ${e.toString()}');
    }
  }

  @override
  Future<List<PermissionModel>> getPermissions() async {
    try {
      final jsonString = _prefs.getString(_permissionsKey);
      if (jsonString == null) {
        // Return initial permissions if none cached
        return PermissionType.values
            .map((type) => PermissionModel.initial(type))
            .toList();
      }

      final permissionsJson = json.decode(jsonString) as List<dynamic>;
      return permissionsJson
          .map((json) => PermissionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SystemFailure('Failed to retrieve permissions: ${e.toString()}');
    }
  }

  @override
  Future<void> savePermission(PermissionModel permission) async {
    try {
      final permissions = await getPermissions();
      final index = permissions.indexWhere((p) => p.type == permission.type);

      if (index != -1) {
        permissions[index] = permission;
      } else {
        permissions.add(permission);
      }

      await savePermissions(permissions);
    } catch (e) {
      throw SystemFailure('Failed to save permission: ${e.toString()}');
    }
  }

  @override
  Future<PermissionModel?> getPermission(PermissionType type) async {
    try {
      final permissions = await getPermissions();
      return permissions.cast<PermissionModel?>().firstWhere(
        (p) => p?.type == type,
        orElse: () => null,
      );
    } catch (e) {
      throw SystemFailure('Failed to retrieve permission: ${e.toString()}');
    }
  }

  @override
  Future<void> clearPermissions() async {
    try {
      await _prefs.remove(_permissionsKey);
    } catch (e) {
      throw SystemFailure('Failed to clear permissions: ${e.toString()}');
    }
  }
}
