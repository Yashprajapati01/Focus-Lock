import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/core/error/failures.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/domain/repositories/session_repository.dart';
import 'package:focuslock/features/session/domain/usecases/start_session.dart';

import 'start_session_test.mocks.dart';

@GenerateMocks([SessionRepository])
void main() {
  group('StartSession', () {
    late StartSession usecase;
    late MockSessionRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRepository();
      usecase = StartSession(mockRepository);
    });

    test('should start session when permissions are granted', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      when(
        mockRepository.hasRequiredPermissions(),
      ).thenAnswer((_) async => true);
      when(mockRepository.saveSessionConfig(any)).thenAnswer((_) async {});
      when(mockRepository.startDeviceLock()).thenAnswer((_) async {});

      // act
      final result = await usecase(testConfig);

      // assert
      expect(result, const Right(null));
      verify(mockRepository.hasRequiredPermissions());
      verify(mockRepository.saveSessionConfig(testConfig));
      verify(mockRepository.startDeviceLock());
    });

    test(
      'should return PermissionFailure when permissions are not granted',
      () async {
        // arrange
        const testConfig = SessionConfig(
          duration: Duration(hours: 1),
          lastUsed: null,
        );
        when(
          mockRepository.hasRequiredPermissions(),
        ).thenAnswer((_) async => false);

        // act
        final result = await usecase(testConfig);

        // assert
        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(mockRepository.hasRequiredPermissions());
        verifyNever(mockRepository.saveSessionConfig(any));
        verifyNever(mockRepository.startDeviceLock());
      },
    );

    test(
      'should return SessionFailure when saveSessionConfig throws',
      () async {
        // arrange
        const testConfig = SessionConfig(
          duration: Duration(hours: 1),
          lastUsed: null,
        );
        when(
          mockRepository.hasRequiredPermissions(),
        ).thenAnswer((_) async => true);
        when(
          mockRepository.saveSessionConfig(any),
        ).thenThrow(Exception('Save failed'));

        // act
        final result = await usecase(testConfig);

        // assert
        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) => expect(failure, isA<SessionFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(mockRepository.hasRequiredPermissions());
        verify(mockRepository.saveSessionConfig(testConfig));
        verifyNever(mockRepository.startDeviceLock());
      },
    );

    test('should return SessionFailure when startDeviceLock throws', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      when(
        mockRepository.hasRequiredPermissions(),
      ).thenAnswer((_) async => true);
      when(mockRepository.saveSessionConfig(any)).thenAnswer((_) async {});
      when(
        mockRepository.startDeviceLock(),
      ).thenThrow(Exception('Device lock failed'));

      // act
      final result = await usecase(testConfig);

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure, isA<SessionFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.hasRequiredPermissions());
      verify(mockRepository.saveSessionConfig(testConfig));
      verify(mockRepository.startDeviceLock());
    });

    test('should include error message in SessionFailure', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      const errorMessage = 'Device admin not available';
      when(
        mockRepository.hasRequiredPermissions(),
      ).thenAnswer((_) async => true);
      when(mockRepository.saveSessionConfig(any)).thenAnswer((_) async {});
      when(mockRepository.startDeviceLock()).thenThrow(Exception(errorMessage));

      // act
      final result = await usecase(testConfig);

      // assert
      result.fold(
        (failure) => expect(failure.message, contains(errorMessage)),
        (_) => fail('Should return failure'),
      );
    });

    test('should save config before starting device lock', () async {
      // arrange
      const testConfig = SessionConfig(
        duration: Duration(hours: 1),
        lastUsed: null,
      );
      final callOrder = <String>[];

      when(
        mockRepository.hasRequiredPermissions(),
      ).thenAnswer((_) async => true);
      when(mockRepository.saveSessionConfig(any)).thenAnswer((_) async {
        callOrder.add('save');
      });
      when(mockRepository.startDeviceLock()).thenAnswer((_) async {
        callOrder.add('lock');
      });

      // act
      await usecase(testConfig);

      // assert
      expect(callOrder, ['save', 'lock']);
    });
  });
}
