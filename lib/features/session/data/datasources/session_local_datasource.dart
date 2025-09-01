import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_config_model.dart';

abstract class SessionLocalDataSource {
  /// Get the cached session configuration
  Future<SessionConfigModel> getSessionConfig();

  /// Cache the session configuration
  Future<void> cacheSessionConfig(SessionConfigModel config);
}

@LazySingleton(as: SessionLocalDataSource)
class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String sessionConfigKey = 'CACHED_SESSION_CONFIG';

  SessionLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<SessionConfigModel> getSessionConfig() async {
    final jsonString = sharedPreferences.getString(sessionConfigKey);

    if (jsonString != null) {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return SessionConfigModel.fromJson(jsonMap);
    } else {
      // Return default configuration if none exists
      return const SessionConfigModel(
        duration: Duration(minutes: 30),
        lastUsed: null,
      );
    }
  }

  @override
  Future<void> cacheSessionConfig(SessionConfigModel config) async {
    final configWithTimestamp = config.copyWith(lastUsed: DateTime.now());
    final jsonString = json.encode(configWithTimestamp.toJson());
    await sharedPreferences.setString(sessionConfigKey, jsonString);
  }
}
