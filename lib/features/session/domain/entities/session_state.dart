import 'package:equatable/equatable.dart';
import 'session_config.dart';

enum SessionStatus {
  configuring,
  countdown,
  active,
  paused,
  completed,
  cancelled,
}

class SessionState extends Equatable {
  final SessionConfig config;
  final SessionStatus status;
  final Duration? remainingTime;
  final DateTime? startTime;
  final int? countdownSeconds;

  const SessionState({
    required this.config,
    required this.status,
    this.remainingTime,
    this.startTime,
    this.countdownSeconds,
  });

  // Validation for state transitions
  bool canTransitionTo(SessionStatus newStatus) {
    switch (status) {
      case SessionStatus.configuring:
        return newStatus == SessionStatus.countdown;
      case SessionStatus.countdown:
        return newStatus == SessionStatus.active ||
            newStatus == SessionStatus.cancelled ||
            newStatus == SessionStatus.configuring;
      case SessionStatus.active:
        return newStatus == SessionStatus.paused ||
            newStatus == SessionStatus.completed ||
            newStatus == SessionStatus.cancelled;
      case SessionStatus.paused:
        return newStatus == SessionStatus.active ||
            newStatus == SessionStatus.cancelled;
      case SessionStatus.completed:
        return newStatus == SessionStatus.configuring;
      case SessionStatus.cancelled:
        return newStatus == SessionStatus.configuring;
    }
  }

  // Convenience getters
  bool get isActive => status == SessionStatus.active;
  bool get isCompleted => status == SessionStatus.completed;

  // Progress percentage (0.0 to 1.0)
  double get progress {
    if (remainingTime == null || status != SessionStatus.active) {
      return 0.0;
    }

    final totalDuration = config.duration;
    final elapsed = totalDuration - remainingTime!;
    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  SessionState copyWith({
    SessionConfig? config,
    SessionStatus? status,
    Duration? remainingTime,
    DateTime? startTime,
    int? countdownSeconds,
  }) {
    return SessionState(
      config: config ?? this.config,
      status: status ?? this.status,
      remainingTime: remainingTime ?? this.remainingTime,
      startTime: startTime ?? this.startTime,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }

  @override
  List<Object?> get props => [
    config,
    status,
    remainingTime,
    startTime,
    countdownSeconds,
  ];
}
