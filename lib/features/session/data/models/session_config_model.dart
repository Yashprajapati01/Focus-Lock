import '../../domain/entities/session_config.dart';

class SessionConfigModel extends SessionConfig {
  const SessionConfigModel({required super.duration, super.lastUsed});

  factory SessionConfigModel.fromEntity(SessionConfig entity) {
    return SessionConfigModel(
      duration: entity.duration,
      lastUsed: entity.lastUsed,
    );
  }

  factory SessionConfigModel.fromJson(Map<String, dynamic> json) {
    return SessionConfigModel(
      duration: Duration(milliseconds: json['durationMs'] as int),
      lastUsed: json['lastUsed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUsed'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'durationMs': duration.inMilliseconds,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
    };
  }

  SessionConfigModel copyWith({Duration? duration, DateTime? lastUsed}) {
    return SessionConfigModel(
      duration: duration ?? this.duration,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
