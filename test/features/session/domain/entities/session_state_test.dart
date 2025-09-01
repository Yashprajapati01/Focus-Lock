import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/domain/entities/session_state.dart';

void main() {
  group('SessionState', () {
    const testConfig = SessionConfig(duration: Duration(minutes: 30));

    group('canTransitionTo', () {
      test('should allow transition from configuring to countdown', () {
        const state = SessionState(
          config: testConfig,
          status: SessionStatus.configuring,
        );

        expect(state.canTransitionTo(SessionStatus.countdown), isTrue);
      });

      test('should allow transition from countdown to active', () {
        const state = SessionState(
          config: testConfig,
          status: SessionStatus.countdown,
          countdownSeconds: 10,
        );

        expect(state.canTransitionTo(SessionStatus.active), isTrue);
      });

      test(
        'should allow transition from countdown to configuring (cancel)',
        () {
          const state = SessionState(
            config: testConfig,
            status: SessionStatus.countdown,
            countdownSeconds: 5,
          );

          expect(state.canTransitionTo(SessionStatus.configuring), isTrue);
        },
      );

      test('should allow transition from active to paused', () {
        final state = SessionState(
          config: testConfig,
          status: SessionStatus.active,
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        );

        expect(state.canTransitionTo(SessionStatus.paused), isTrue);
      });

      test('should allow transition from active to completed', () {
        final state = SessionState(
          config: testConfig,
          status: SessionStatus.active,
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        );

        expect(state.canTransitionTo(SessionStatus.completed), isTrue);
      });

      test('should allow transition from paused to active', () {
        final state = SessionState(
          config: testConfig,
          status: SessionStatus.paused,
          remainingTime: const Duration(minutes: 15),
          startTime: DateTime.now(),
        );

        expect(state.canTransitionTo(SessionStatus.active), isTrue);
      });

      test('should not allow invalid transitions', () {
        const state = SessionState(
          config: testConfig,
          status: SessionStatus.completed,
        );

        expect(state.canTransitionTo(SessionStatus.active), isFalse);
        expect(state.canTransitionTo(SessionStatus.countdown), isFalse);
        expect(state.canTransitionTo(SessionStatus.paused), isFalse);
      });
    });

    group('isActive', () {
      test('should return true when status is active', () {
        final state = SessionState(
          config: testConfig,
          status: SessionStatus.active,
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        );

        expect(state.isActive, isTrue);
      });

      test('should return false when status is not active', () {
        const state = SessionState(
          config: testConfig,
          status: SessionStatus.configuring,
        );

        expect(state.isActive, isFalse);
      });
    });

    group('isCompleted', () {
      test('should return true when status is completed', () {
        const state = SessionState(
          config: testConfig,
          status: SessionStatus.completed,
        );

        expect(state.isCompleted, isTrue);
      });

      test('should return false when status is not completed', () {
        final state = SessionState(
          config: testConfig,
          status: SessionStatus.active,
          remainingTime: const Duration(minutes: 30),
          startTime: DateTime.now(),
        );

        expect(state.isCompleted, isFalse);
      });
    });
  });
}
