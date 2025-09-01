import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';

void main() {
  group('SessionConfig', () {
    group('difficulty calculation', () {
      test('should return easy for 15 minutes', () {
        const config = SessionConfig(duration: Duration(minutes: 15));
        expect(config.difficulty, DifficultyLevel.easy);
      });

      test('should return easy for 30 minutes', () {
        const config = SessionConfig(duration: Duration(minutes: 30));
        expect(config.difficulty, DifficultyLevel.easy);
      });

      test('should return intermediate for 1 hour', () {
        const config = SessionConfig(duration: Duration(hours: 1));
        expect(config.difficulty, DifficultyLevel.intermediate);
      });

      test('should return intermediate for 2 hours', () {
        const config = SessionConfig(duration: Duration(hours: 2));
        expect(config.difficulty, DifficultyLevel.intermediate);
      });

      test('should return expert for 3 hours', () {
        const config = SessionConfig(duration: Duration(hours: 3));
        expect(config.difficulty, DifficultyLevel.expert);
      });

      test('should return expert for 4 hours', () {
        const config = SessionConfig(duration: Duration(hours: 4));
        expect(config.difficulty, DifficultyLevel.expert);
      });

      test('should return legendary for 5 hours', () {
        const config = SessionConfig(duration: Duration(hours: 5));
        expect(config.difficulty, DifficultyLevel.legendary);
      });

      test('should return legendary for 8 hours', () {
        const config = SessionConfig(duration: Duration(hours: 8));
        expect(config.difficulty, DifficultyLevel.legendary);
      });
    });

    group('formattedTime', () {
      test('should format minutes only', () {
        const config = SessionConfig(duration: Duration(minutes: 45));
        expect(config.formattedTime, '45m');
      });

      test('should format hours only', () {
        const config = SessionConfig(duration: Duration(hours: 2));
        expect(config.formattedTime, '2h');
      });

      test('should format hours and minutes', () {
        const config = SessionConfig(duration: Duration(hours: 1, minutes: 30));
        expect(config.formattedTime, '1h 30m');
      });

      test('should format single minute', () {
        const config = SessionConfig(duration: Duration(minutes: 1));
        expect(config.formattedTime, '1m');
      });
    });

    group('difficultyColor', () {
      test('should return green for easy', () {
        const config = SessionConfig(duration: Duration(minutes: 15));
        expect(config.difficultyColor, Colors.green);
      });

      test('should return orange for intermediate', () {
        const config = SessionConfig(duration: Duration(hours: 1));
        expect(config.difficultyColor, Colors.orange);
      });

      test('should return red for expert', () {
        const config = SessionConfig(duration: Duration(hours: 3));
        expect(config.difficultyColor, Colors.red);
      });

      test('should return purple for legendary', () {
        const config = SessionConfig(duration: Duration(hours: 5));
        expect(config.difficultyColor, Colors.purple);
      });
    });

    group('difficultyLabel', () {
      test('should return Easy for easy difficulty', () {
        const config = SessionConfig(duration: Duration(minutes: 15));
        expect(config.difficultyLabel, 'Easy');
      });

      test('should return Intermediate for intermediate difficulty', () {
        const config = SessionConfig(duration: Duration(hours: 1));
        expect(config.difficultyLabel, 'Intermediate');
      });

      test('should return Expert for expert difficulty', () {
        const config = SessionConfig(duration: Duration(hours: 3));
        expect(config.difficultyLabel, 'Expert');
      });

      test('should return Legendary for legendary difficulty', () {
        const config = SessionConfig(duration: Duration(hours: 5));
        expect(config.difficultyLabel, 'Legendary');
      });
    });

    group('copyWith', () {
      test('should create new instance with updated duration', () {
        const original = SessionConfig(duration: Duration(minutes: 30));
        final updated = original.copyWith(duration: const Duration(hours: 1));

        expect(updated.duration, const Duration(hours: 1));
        expect(updated.lastUsed, original.lastUsed);
        expect(updated, isNot(same(original)));
      });

      test('should create new instance with updated lastUsed', () {
        const original = SessionConfig(duration: Duration(minutes: 30));
        final now = DateTime.now();
        final updated = original.copyWith(lastUsed: now);

        expect(updated.duration, original.duration);
        expect(updated.lastUsed, now);
        expect(updated, isNot(same(original)));
      });
    });

    group('equality', () {
      test('should be equal with same properties', () {
        const config1 = SessionConfig(duration: Duration(minutes: 30));
        const config2 = SessionConfig(duration: Duration(minutes: 30));

        expect(config1, equals(config2));
      });

      test('should not be equal with different duration', () {
        const config1 = SessionConfig(duration: Duration(minutes: 30));
        const config2 = SessionConfig(duration: Duration(minutes: 45));

        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal with different lastUsed', () {
        final now = DateTime.now();
        final later = now.add(const Duration(hours: 1));

        final config1 = SessionConfig(
          duration: const Duration(minutes: 30),
          lastUsed: now,
        );
        final config2 = SessionConfig(
          duration: const Duration(minutes: 30),
          lastUsed: later,
        );

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
