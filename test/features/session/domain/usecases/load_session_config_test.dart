import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/core/error/failures.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/domain/repositories/session_repository.dart';
import 'package:focuslock/features/session/domain/usecases/load_session_config.dart';

import 'load_session_config_test.mocks.dart';

@GenerateMocks([SessionRepository])
void main() {
  group('LoadSessionConfig', () {
    late LoadSessionConfig usecase;
    late MockSessionRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRepository();
      usecase = LoadSessionConfig(mockRepository);
    });

    test('should load session config from repository', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      when(
        mockRepository.loadSessionConfig(),
      ).thenAnswer((_) async => testConfig);

      // act
      final result = await usecase();

      // assert
      expect(result, Right(testConfig));
      verify(mockRepository.loadSessionConfig());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'should return CacheFailure when repository throws exception',
      () async {
        // arrange
        when(
          mockRepository.loadSessionConfig(),
        ).thenThrow(Exception('Load failed'));

        // act
        final result = await usecase();

        // assert
        expect(result, isA<Left<Failure, SessionConfig>>());
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(mockRepository.loadSessionConfig());
      },
    );

    test('should include error message in failure', () async {
      // arrange
      const errorMessage = 'File not found';
      when(
        mockRepository.loadSessionConfig(),
      ).thenThrow(Exception(errorMessage));

      // act
      final result = await usecase();

      // assert
      result.fold(
        (failure) => expect(failure.message, contains(errorMessage)),
        (_) => fail('Should return failure'),
      );
    });

    test('should handle different config durations correctly', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(minutes: 45),
        lastUsed: null,
      );
      when(
        mockRepository.loadSessionConfig(),
      ).thenAnswer((_) async => testConfig);

      // act
      final result = await usecase();

      // assert
      result.fold((_) => fail('Should return success'), (config) {
        expect(config.duration, const Duration(minutes: 45));
        expect(config.difficulty, DifficultyLevel.intermediate);
      });
    });
  });
}
