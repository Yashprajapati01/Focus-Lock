import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/core/error/failures.dart';
import 'package:focuslock/features/session/domain/repositories/session_repository.dart';
import 'package:focuslock/features/session/domain/usecases/cancel_session.dart';

import 'cancel_session_test.mocks.dart';

@GenerateMocks([SessionRepository])
void main() {
  group('CancelSession', () {
    late CancelSession usecase;
    late MockSessionRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRepository();
      usecase = CancelSession(mockRepository);
    });

    test('should cancel session successfully', () async {
      // arrange
      when(mockRepository.endDeviceLock()).thenAnswer((_) async {});

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(null));
      verify(mockRepository.endDeviceLock());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return SessionFailure when endDeviceLock throws', () async {
      // arrange
      when(
        mockRepository.endDeviceLock(),
      ).thenThrow(Exception('Unlock failed'));

      // act
      final result = await usecase();

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure, isA<SessionFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.endDeviceLock());
    });

    test('should include error message in SessionFailure', () async {
      // arrange
      const errorMessage = 'Device admin permission revoked';
      when(mockRepository.endDeviceLock()).thenThrow(Exception(errorMessage));

      // act
      final result = await usecase();

      // assert
      result.fold(
        (failure) => expect(failure.message, contains(errorMessage)),
        (_) => fail('Should return failure'),
      );
    });

    test('should handle different types of exceptions', () async {
      // arrange
      when(
        mockRepository.endDeviceLock(),
      ).thenThrow(StateError('Invalid state'));

      // act
      final result = await usecase();

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<SessionFailure>());
        expect(failure.message, contains('Invalid state'));
      }, (_) => fail('Should return failure'));
    });

    test('should work even if device was not locked', () async {
      // arrange
      when(
        mockRepository.endDeviceLock(),
      ).thenAnswer((_) async {}); // No-op if not locked

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(null));
      verify(mockRepository.endDeviceLock());
    });
  });
}
