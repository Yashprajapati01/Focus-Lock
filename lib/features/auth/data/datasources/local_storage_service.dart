import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class LocalStorageService {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearUser();
}

@LazySingleton(as: LocalStorageService)
class LocalStorageServiceImpl implements LocalStorageService {
  static const String _userKey = 'cached_user';

  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e) {
      throw SystemFailure('Failed to save user data: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw SystemFailure('Failed to retrieve user data: ${e.toString()}');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await _prefs.remove(_userKey);
    } catch (e) {
      throw SystemFailure('Failed to clear user data: ${e.toString()}');
    }
  }
}

@module
abstract class LocalStorageModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
