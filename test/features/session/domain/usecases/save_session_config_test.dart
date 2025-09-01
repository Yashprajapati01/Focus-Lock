import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/core/error/failures.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/domain/repositories/session_repository.dart';
import 'package:focuslock/features/session/domain/usecases/save_session_config.dart';

import 'save_session_config_test.mocks.dart';

@GenerateMocks([SessionRepository])
void main() {
  group('SaveSessionConfig', () {
    late SaveSessionConfig usecase;
    late MockSessionRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRepository();
      usecase = SaveSessionConfig(mockRepository);
    });

    test('should save session config through repository', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      when(mockRepository.saveSessionConfig(any)).thenAnswer((_) async {});

      // act
      final result = await usecase(testConfig);

      // assert
      expect(result, const Right(null));
      verify(mockRepository.saveSessionConfig(testConfig));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'should return CacheFailure when repository throws exception',
      () async {
        // arrange
        const testConfig = SessionConfig(
          duration: Duration(hours: 1),
          lastUsed: null,
        );
        when(
          mockRepository.saveSessionConfig(any),
        ).thenThrow(Exception('Save failed'));

        // act
        final result = await usecase(testConfig);

        // assert
        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(mockRepository.saveSessionConfig(testConfig));
      },
    );

    test('should include error message in failure', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      const errorMessage = 'Database connection failed';
      when(
        mockRepository.saveSessionConfig(any),
      ).thenThrow(Exception(errorMessage));

      // act
      final result = await usecase(testConfig);

      // assert
      result.fold(
        (failure) => expect(failure.message, contains(errorMessage)),
        (_) => fail('Should return failure'),
      );
    });
  });
}
