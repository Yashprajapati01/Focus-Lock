import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/usecases/load_session_config.dart';
import '../../domain/usecases/save_session_config.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/cancel_session.dart';
import 'session_event.dart';
import 'session_state.dart' as states;

@injectable
class SessionBloc extends Bloc<SessionEvent, states.SessionBlocState> {
  final LoadSessionConfig loadSessionConfig;
  final SaveSessionConfig saveSessionConfig;
  final StartSession startSession;
  final CancelSession cancelSession;

  Timer? _countdownTimer;
  Timer? _sessionTimer;

  SessionBloc({
    required this.loadSessionConfig,
    required this.saveSessionConfig,
    required this.startSession,
    required this.cancelSession,
  }) : super(
         const states.SessionInitial(
           config: SessionConfig(duration: Duration(minutes: 1)),
         ),
       ) {
    on<SessionInitialized>(_onSessionInitialized);
    on<TimeChanged>(_onTimeChanged);
    on<PresetSelected>(_onPresetSelected);
    on<SessionStartRequested>(_onSessionStartRequested);
    on<CountdownTick>(_onCountdownTick);
    on<CountdownCancelled>(_onCountdownCancelled);
    on<SessionTimerTick>(_onSessionTimerTick);
    on<SessionCompleted>(_onSessionCompleted);
    on<SessionCancelled>(_onSessionCancelled);
    on<SessionPaused>(_onSessionPaused);
    on<SessionResumed>(_onSessionResumed);
    on<SessionReset>(_onSessionReset);
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    return super.close();
  }

  Future<void> _onSessionInitialized(
    SessionInitialized event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    final result = await loadSessionConfig();
    result.fold(
      (failure) {
        // Use default config if loading fails
        emit(
          const states.SessionConfiguring(
            config: SessionConfig(duration: Duration(minutes: 1)),
          ),
        );
      },
      (config) {
        emit(states.SessionConfiguring(config: config));
      },
    );
  }

  Future<void> _onTimeChanged(
    TimeChanged event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    final newConfig = state.config.copyWith(duration: event.duration);
    emit(states.SessionConfiguring(config: newConfig));

    // Save the configuration
    await saveSessionConfig(newConfig);
  }

  Future<void> _onPresetSelected(
    PresetSelected event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    final newConfig = state.config.copyWith(duration: event.duration);
    emit(states.SessionConfiguring(config: newConfig));

    // Save the configuration
    await saveSessionConfig(newConfig);
  }

  Future<void> _onSessionStartRequested(
    SessionStartRequested event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    if (state is! states.SessionConfiguring) return;

    // Start countdown
    emit(states.SessionCountdown(config: state.config, secondsRemaining: 10));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = 10 - timer.tick;
      if (remaining > 0) {
        add(CountdownTick(remaining));
      } else {
        timer.cancel();
        _startActiveSession();
      }
    });
  }

  void _onCountdownTick(
    CountdownTick event,
    Emitter<states.SessionBlocState> emit,
  ) {
    if (state is states.SessionCountdown) {
      emit(
        states.SessionCountdown(
          config: state.config,
          secondsRemaining: event.secondsRemaining,
        ),
      );
    }
  }

  void _onCountdownCancelled(
    CountdownCancelled event,
    Emitter<states.SessionBlocState> emit,
  ) {
    _countdownTimer?.cancel();
    emit(states.SessionConfiguring(config: state.config));
  }

  Future<void> _startActiveSession() async {
    final result = await startSession(state.config);
    result.fold(
      (failure) {
        emit(
          states.SessionError(config: state.config, message: failure.message),
        );
      },
      (_) {
        final startTime = DateTime.now();
        emit(
          states.SessionActive(
            config: state.config,
            remainingTime: state.config.duration,
            startTime: startTime,
          ),
        );

        _startSessionTimer();
      },
    );
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is states.SessionActive) {
        final currentState = state as states.SessionActive;
        final newRemainingTime =
            currentState.remainingTime - const Duration(seconds: 1);

        if (newRemainingTime.inSeconds <= 0) {
          timer.cancel();
          add(const SessionCompleted());
        } else {
          add(SessionTimerTick(newRemainingTime));
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _onSessionTimerTick(
    SessionTimerTick event,
    Emitter<states.SessionBlocState> emit,
  ) {
    if (state is states.SessionActive) {
      final currentState = state as states.SessionActive;
      emit(currentState.copyWith(remainingTime: event.remainingTime));
    }
  }

  Future<void> _onSessionCompleted(
    SessionCompleted event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    _sessionTimer?.cancel();

    // End device lock
    await cancelSession();

    emit(
      states.SessionCompleted(
        config: state.config,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onSessionCancelled(
    SessionCancelled event,
    Emitter<states.SessionBlocState> emit,
  ) async {
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();

    // Calculate elapsed time if session was active
    Duration? timeElapsed;
    if (state is states.SessionActive) {
      final activeState = state as states.SessionActive;
      timeElapsed = state.config.duration - activeState.remainingTime;
    }

    // End device lock
    await cancelSession();

    emit(
      states.SessionCancelled(
        config: state.config,
        cancelledAt: DateTime.now(),
        timeElapsed: timeElapsed,
      ),
    );
  }

  void _onSessionPaused(
    SessionPaused event,
    Emitter<states.SessionBlocState> emit,
  ) {
    if (state is states.SessionActive) {
      _sessionTimer?.cancel();
      final activeState = state as states.SessionActive;
      final pausedDuration = DateTime.now().difference(activeState.startTime);

      emit(
        states.SessionPaused(
          config: state.config,
          remainingTime: activeState.remainingTime,
          startTime: activeState.startTime,
          pausedDuration: pausedDuration,
        ),
      );
    }
  }

  void _onSessionResumed(
    SessionResumed event,
    Emitter<states.SessionBlocState> emit,
  ) {
    if (state is states.SessionPaused) {
      final pausedState = state as states.SessionPaused;

      emit(
        states.SessionActive(
          config: state.config,
          remainingTime: pausedState.remainingTime,
          startTime: pausedState.startTime,
        ),
      );

      _startSessionTimer();
    }
  }

  void _onSessionReset(
    SessionReset event,
    Emitter<states.SessionBlocState> emit,
  ) {
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();

    emit(states.SessionConfiguring(config: state.config));
  }
}
