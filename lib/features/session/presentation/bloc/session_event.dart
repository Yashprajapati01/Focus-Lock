import 'package:equatable/equatable.dart';
import '../../domain/entities/session_config.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionInitialized extends SessionEvent {
  const SessionInitialized();
}

class TimeChanged extends SessionEvent {
  final Duration duration;

  const TimeChanged(this.duration);

  @override
  List<Object> get props => [duration];
}

class PresetSelected extends SessionEvent {
  final Duration duration;

  const PresetSelected(this.duration);

  @override
  List<Object> get props => [duration];
}

class SessionStartRequested extends SessionEvent {
  const SessionStartRequested();
}

class CountdownTick extends SessionEvent {
  final int secondsRemaining;

  const CountdownTick(this.secondsRemaining);

  @override
  List<Object> get props => [secondsRemaining];
}

class CountdownCancelled extends SessionEvent {
  const CountdownCancelled();
}

class SessionTimerTick extends SessionEvent {
  final Duration remainingTime;

  const SessionTimerTick(this.remainingTime);

  @override
  List<Object> get props => [remainingTime];
}

class SessionCompleted extends SessionEvent {
  const SessionCompleted();
}

class SessionCancelled extends SessionEvent {
  const SessionCancelled();
}

class SessionPaused extends SessionEvent {
  const SessionPaused();
}

class SessionResumed extends SessionEvent {
  const SessionResumed();
}

class SessionReset extends SessionEvent {
  const SessionReset();
}
