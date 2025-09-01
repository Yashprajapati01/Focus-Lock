import 'package:equatable/equatable.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/entities/session_state.dart' as domain;

abstract class SessionBlocState extends Equatable {
  final SessionConfig config;

  const SessionBlocState({required this.config});

  @override
  List<Object?> get props => [config];
}

class SessionInitial extends SessionBlocState {
  const SessionInitial({required super.config});
}

class SessionConfiguring extends SessionBlocState {
  const SessionConfiguring({required super.config});

  SessionConfiguring copyWith({SessionConfig? config}) {
    return SessionConfiguring(config: config ?? this.config);
  }
}

class SessionCountdown extends SessionBlocState {
  final int secondsRemaining;

  const SessionCountdown({
    required super.config,
    required this.secondsRemaining,
  });

  @override
  List<Object?> get props => [config, secondsRemaining];

  SessionCountdown copyWith({SessionConfig? config, int? secondsRemaining}) {
    return SessionCountdown(
      config: config ?? this.config,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

class SessionActive extends SessionBlocState {
  final Duration remainingTime;
  final DateTime startTime;

  const SessionActive({
    required super.config,
    required this.remainingTime,
    required this.startTime,
  });

  double get progress {
    final totalDuration = config.duration;
    final elapsed = totalDuration - remainingTime;
    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  @override
  List<Object?> get props => [config, remainingTime, startTime];

  SessionActive copyWith({
    SessionConfig? config,
    Duration? remainingTime,
    DateTime? startTime,
  }) {
    return SessionActive(
      config: config ?? this.config,
      remainingTime: remainingTime ?? this.remainingTime,
      startTime: startTime ?? this.startTime,
    );
  }
}

class SessionPaused extends SessionBlocState {
  final Duration remainingTime;
  final DateTime startTime;
  final Duration pausedDuration;

  const SessionPaused({
    required super.config,
    required this.remainingTime,
    required this.startTime,
    required this.pausedDuration,
  });

  double get progress {
    final totalDuration = config.duration;
    final elapsed = totalDuration - remainingTime;
    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  @override
  List<Object?> get props => [config, remainingTime, startTime, pausedDuration];

  SessionPaused copyWith({
    SessionConfig? config,
    Duration? remainingTime,
    DateTime? startTime,
    Duration? pausedDuration,
  }) {
    return SessionPaused(
      config: config ?? this.config,
      remainingTime: remainingTime ?? this.remainingTime,
      startTime: startTime ?? this.startTime,
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }
}

class SessionCompleted extends SessionBlocState {
  final DateTime completedAt;

  const SessionCompleted({required super.config, required this.completedAt});

  @override
  List<Object?> get props => [config, completedAt];
}

class SessionCancelled extends SessionBlocState {
  final DateTime cancelledAt;
  final Duration? timeElapsed;

  const SessionCancelled({
    required super.config,
    required this.cancelledAt,
    this.timeElapsed,
  });

  @override
  List<Object?> get props => [config, cancelledAt, timeElapsed];
}

class SessionError extends SessionBlocState {
  final String message;

  const SessionError({required super.config, required this.message});

  @override
  List<Object?> get props => [config, message];
}
