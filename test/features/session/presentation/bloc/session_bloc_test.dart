import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/core/error/failures.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/domain/usecases/cancel_session.dart';
import 'package:focuslock/features/session/domain/usecases/load_session_config.dart';
import 'package:focuslock/features/session/domain/usecases/save_session_config.dart';
import 'package:focuslock/features/session/domain/usecases/start_session.dart';
import 'package:focuslock/features/session/presentation/bloc/session_bloc.dart';
import 'package:focuslock/features/session/presentation/bloc/session_event.dart';
import 'package:focuslock/features/session/presentation/bloc/session_state.dart'
    as state;

import 'session_bloc_test.mocks.dart';

@GenerateMocks([
  LoadSessionConfig,
  SaveSessionConfig,
  StartSession,
  CancelSession,
])
void main() {
  group('SessionBloc', () {
    late SessionBloc sessionBloc;
    late MockLoadSessionConfig mockLoadSessionConfig;
    late MockSaveSessionConfig mockSaveSessionConfig;
    late MockStartSession mockStartSession;
    late MockCancelSession mockCancelSession;

    setUp(() {
      mockLoadSessionConfig = MockLoadSessionConfig();
      mockSaveSessionConfig = MockSaveSessionConfig();
      mockStartSession = MockStartSession();
      mockCancelSession = MockCancelSession();

      sessionBloc = SessionBloc(
        loadSessionConfig: mockLoadSessionConfig,
        saveSessionConfig: mockSaveSessionConfig,
        startSession: mockStartSession,
        cancelSession: mockCancelSession,
      );
    });

    tearDown(() {
      sessionBloc.close();
    });

    test('initial state should be SessionInitial with default config', () {
      expect(
        sessionBloc.state,
        const state.SessionInitial(
          config: SessionConfig(duration: Duration(minutes: 30)),
        ),
      );
    });

    group('SessionInitialized', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionConfiguring with loaded config when successful',
        build: () {
          when(mockLoadSessionConfig()).thenAnswer(
            (_) async =>
                const Right(SessionConfig(duration: Duration(hours: 1))),
          );
          return sessionBloc;
        },
        act: (bloc) => bloc.add(const SessionInitialized()),
        expect: () => [
          const state.SessionConfiguring(
            config: SessionConfig(duration: Duration(hours: 1)),
          ),
        ],
        verify: (_) {
          verify(mockLoadSessionConfig()).called(1);
        },
      );

      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionConfiguring with default config when loading fails',
        build: () {
          when(
            mockLoadSessionConfig(),
          ).thenAnswer((_) async => const Left(CacheFailure('Load failed')));
          return sessionBloc;
        },
        act: (bloc) => bloc.add(const SessionInitialized()),
        expect: () => [
          const state.SessionConfiguring(
            config: SessionConfig(duration: Duration(minutes: 30)),
          ),
        ],
        verify: (_) {
          verify(mockLoadSessionConfig()).called(1);
        },
      );
    });

    group('TimeChanged', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionConfiguring with updated duration and save config',
        build: () {
          when(
            mockSaveSessionConfig(any),
          ).thenAnswer((_) async => const Right(null));
          return sessionBloc;
        },
        seed: () => const state.SessionConfiguring(
          config: SessionConfig(duration: Duration(minutes: 30)),
        ),
        act: (bloc) => bloc.add(const TimeChanged(Duration(hours: 1))),
        expect: () => [
          const state.SessionConfiguring(
            config: SessionConfig(duration: Duration(hours: 1)),
          ),
        ],
        verify: (_) {
          verify(mockSaveSessionConfig(any)).called(1);
        },
      );
    });

    group('PresetSelected', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionConfiguring with preset duration and save config',
        build: () {
          when(
            mockSaveSessionConfig(any),
          ).thenAnswer((_) async => const Right(null));
          return sessionBloc;
        },
        seed: () => const state.SessionConfiguring(
          config: SessionConfig(duration: Duration(minutes: 30)),
        ),
        act: (bloc) => bloc.add(const PresetSelected(Duration(hours: 2))),
        expect: () => [
          const state.SessionConfiguring(
            config: SessionConfig(duration: Duration(hours: 2)),
          ),
        ],
        verify: (_) {
          verify(mockSaveSessionConfig(any)).called(1);
        },
      );
    });

    group('SessionStartRequested', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionCountdown when starting from configuring state',
        build: () => sessionBloc,
        seed: () => const state.SessionConfiguring(
          config: SessionConfig(duration: Duration(minutes: 30)),
        ),
        act: (bloc) => bloc.add(const SessionStartRequested()),
        expect: () => [
          const state.SessionCountdown(
            config: SessionConfig(duration: Duration(minutes: 30)),
            secondsRemaining: 10,
          ),
        ],
      );

      blocTest<SessionBloc, state.SessionBlocState>(
        'should not emit anything when not in configuring state',
        build: () => sessionBloc,
        seed: () => state.SessionActive(
          config: const SessionConfig(duration: Duration(minutes: 30)),
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const SessionStartRequested()),
        expect: () => [],
      );
    });

    group('CountdownTick', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit updated countdown state',
        build: () => sessionBloc,
        seed: () => const state.SessionCountdown(
          config: SessionConfig(duration: Duration(minutes: 30)),
          secondsRemaining: 10,
        ),
        act: (bloc) => bloc.add(const CountdownTick(5)),
        expect: () => [
          const state.SessionCountdown(
            config: SessionConfig(duration: Duration(minutes: 30)),
            secondsRemaining: 5,
          ),
        ],
      );
    });

    group('CountdownCancelled', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionConfiguring when countdown is cancelled',
        build: () => sessionBloc,
        seed: () => const state.SessionCountdown(
          config: SessionConfig(duration: Duration(minutes: 30)),
          secondsRemaining: 5,
        ),
        act: (bloc) => bloc.add(const CountdownCancelled()),
        expect: () => [
          const state.SessionConfiguring(
            config: SessionConfig(duration: Duration(minutes: 30)),
          ),
        ],
      );
    });

    group('SessionTimerTick', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit updated active session state with new remaining time',
        build: () => sessionBloc,
        seed: () => state.SessionActive(
          config: const SessionConfig(duration: Duration(minutes: 30)),
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const SessionTimerTick(Duration(minutes: 29))),
        expect: () => [
          isA<state.SessionActive>().having(
            (s) => s.remainingTime,
            'remainingTime',
            const Duration(minutes: 29),
          ),
        ],
      );
    });

    group('SessionCompleted', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionCompleted and call cancel session',
        build: () {
          when(mockCancelSession()).thenAnswer((_) async => const Right(null));
          return sessionBloc;
        },
        seed: () => state.SessionActive(
          config: const SessionConfig(duration: Duration(minutes: 30)),
          remainingTime: const Duration(seconds: 1),
          startTime: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const SessionCompleted()),
        expect: () => [isA<state.SessionCompleted>()],
        verify: (_) {
          verify(mockCancelSession()).called(1);
        },
      );
    });

    group('SessionCancelled', () {
      blocTest<SessionBloc, state.SessionBlocState>(
        'should emit SessionCancelled and call cancel session',
        build: () {
          when(mockCancelSession()).thenAnswer((_) async => const Right(null));
          return sessionBloc;
        },
        seed: () => state.SessionActive(
          config: const SessionConfig(duration: Duration(minutes: 30)),
          remainingTime: const Duration(minutes: 15),
          startTime: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const SessionCancelled()),
        expect: () => [
          isA<state.SessionCancelled>().having(
            (s) => s.timeElapsed,
            'timeElapsed',
            isNotNull,
          ),
        ],
        verify: (_) {
          verify(mockCancelSession()).called(1);
        },
      );
    });
  });
}
