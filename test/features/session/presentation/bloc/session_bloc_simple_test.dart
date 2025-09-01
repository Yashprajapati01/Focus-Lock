import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/presentation/bloc/session_state.dart';

void main() {
  group('SessionBloc State Tests', () {
    test('SessionInitial should have correct properties', () {
      const state = SessionInitial(
        config: SessionConfig(duration: Duration(minutes: 30)),
      );

      expect(state.config.duration, equals(const Duration(minutes: 30)));
      expect(state.props, contains(state.config));
    });

    test('SessionConfiguring should have correct properties', () {
      const state = SessionConfiguring(
        config: SessionConfig(duration: Duration(hours: 1)),
      );

      expect(state.config.duration, equals(const Duration(hours: 1)));
      expect(state.props, contains(state.config));
    });

    test('SessionCountdown should have correct properties', () {
      const state = SessionCountdown(
        config: SessionConfig(duration: Duration(minutes: 45)),
        secondsRemaining: 10,
      );

      expect(state.config.duration, equals(const Duration(minutes: 45)));
      expect(state.secondsRemaining, equals(10));
      expect(state.props, contains(state.config));
      expect(state.props, contains(10));
    });

    test('SessionActive should have correct properties', () {
      final startTime = DateTime.now();
      final state = SessionActive(
        config: const SessionConfig(duration: Duration(minutes: 30)),
        remainingTime: const Duration(minutes: 25),
        startTime: startTime,
      );

      expect(state.config.duration, equals(const Duration(minutes: 30)));
      expect(state.remainingTime, equals(const Duration(minutes: 25)));
      expect(state.startTime, equals(startTime));
      expect(state.props, contains(state.config));
      expect(state.props, contains(state.remainingTime));
      expect(state.props, contains(startTime));
    });

    test('SessionCompleted should have correct properties', () {
      final completedAt = DateTime.now();
      final state = SessionCompleted(
        config: const SessionConfig(duration: Duration(minutes: 30)),
        completedAt: completedAt,
      );

      expect(state.config.duration, equals(const Duration(minutes: 30)));
      expect(state.completedAt, equals(completedAt));
      expect(state.props, contains(state.config));
      expect(state.props, contains(completedAt));
    });

    test('SessionCancelled should have correct properties', () {
      final cancelledAt = DateTime.now();
      final state = SessionCancelled(
        config: const SessionConfig(duration: Duration(minutes: 30)),
        cancelledAt: cancelledAt,
        timeElapsed: const Duration(minutes: 15),
      );

      expect(state.config.duration, equals(const Duration(minutes: 30)));
      expect(state.cancelledAt, equals(cancelledAt));
      expect(state.timeElapsed, equals(const Duration(minutes: 15)));
      expect(state.props, contains(state.config));
      expect(state.props, contains(cancelledAt));
      expect(state.props, contains(const Duration(minutes: 15)));
    });

    test('SessionError should have correct properties', () {
      const state = SessionError(
        config: SessionConfig(duration: Duration(minutes: 30)),
        message: 'Test error message',
      );

      expect(state.config.duration, equals(const Duration(minutes: 30)));
      expect(state.message, equals('Test error message'));
      expect(state.props, contains(state.config));
      expect(state.props, contains('Test error message'));
    });
  });
}
