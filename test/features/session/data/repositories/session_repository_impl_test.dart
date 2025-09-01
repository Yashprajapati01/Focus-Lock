import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/session/data/datasources/session_local_datasource.dart';
import 'package:focuslock/features/session/data/models/session_config_model.dart';
import 'package:focuslock/features/session/data/repositories/session_repository_impl.dart';
import 'package:focuslock/features/session/data/services/device_admin_service.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';

import 'session_repository_impl_test.mocks.dart';

@GenerateMocks([SessionLocalDataSource, DeviceAdminService])
void main() {
  group('SessionRepositoryImpl', () {
    late SessionRepositoryImpl repository;
    late MockSessionLocalDataSource mockLocalDataSource;
    late MockDeviceAdminService mockDeviceAdminService;

    setUp(() {
      mockLocalDataSource = MockSessionLocalDataSource();
      mockDeviceAdminService = MockDeviceAdminService();
      repository = SessionRepositoryImpl(
        localDataSource: mockLocalDataSource,
        deviceAdminService: mockDeviceAdminService,
      );
    });

    group('loadSessionConfig', () {
      test('should return session config from local data source', () async {
        // arrange
        const testConfig = SessionConfigModel(
          duration: Duration(hours: 1),
          lastUsed: null,
        );
        when(
          mockLocalDataSource.getSessionConfig(),
        ).thenAnswer((_) async => testConfig);

        // act
        final result = await repository.loadSessionConfig();

        // assert
        expect(result, testConfig);
        verify(mockLocalDataSource.getSessionConfig());
      });

      test(
        'should return default config when local data source throws',
        () async {
          // arrange
          when(
            mockLocalDataSource.getSessionConfig(),
          ).thenThrow(Exception('Cache error'));

          // act
          final result = await repository.loadSessionConfig();

          // assert
          expect(result.duration, const Duration(minutes: 30));
          expect(result.lastUsed, isNull);
          verify(mockLocalDataSource.getSessionConfig());
        },
      );
    });

    group('saveSessionConfig', () {
      test('should save session config to local data source', () async {
        // arrange
        const testConfig = SessionConfig(
          duration: Duration(hours: 1),
          lastUsed: null,
        );
        when(
          mockLocalDataSource.cacheSessionConfig(any),
        ).thenAnswer((_) async {});

        // act
        await repository.saveSessionConfig(testConfig);

        // assert
        verify(mockLocalDataSource.cacheSessionConfig(any));
      });

      test('should convert entity to model before saving', () async {
        // arrange
        const testConfig = SessionConfig(
          duration: Duration(hours: 1),
          lastUsed: null,
        );

        SessionConfigModel? capturedModel;
        when(mockLocalDataSource.cacheSessionConfig(any)).thenAnswer((
          invocation,
        ) async {
          capturedModel =
              invocation.positionalArguments[0] as SessionConfigModel;
        });

        // act
        await repository.saveSessionConfig(testConfig);

        // assert
        expect(capturedModel, isNotNull);
        expect(capturedModel!.duration, testConfig.duration);
        expect(capturedModel!.lastUsed, testConfig.lastUsed);
      });
    });

    group('startDeviceLock', () {
      test('should start device lock when permissions are granted', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);
        when(mockDeviceAdminService.startDeviceLock()).thenAnswer((_) async {});

        // act
        await repository.startDeviceLock();

        // assert
        verify(mockDeviceAdminService.hasDeviceAdminPermission());
        verify(mockDeviceAdminService.hasOverlayPermission());
        verify(mockDeviceAdminService.startDeviceLock());
      });

      test('should throw exception when admin permission is missing', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => false);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        // act & assert
        expect(() => repository.startDeviceLock(), throwsA(isA<Exception>()));

        verify(mockDeviceAdminService.hasDeviceAdminPermission());
        verify(mockDeviceAdminService.hasOverlayPermission());
        verifyNever(mockDeviceAdminService.startDeviceLock());
      });

      test(
        'should throw exception when overlay permission is missing',
        () async {
          // arrange
          when(
            mockDeviceAdminService.hasDeviceAdminPermission(),
          ).thenAnswer((_) async => true);
          when(
            mockDeviceAdminService.hasOverlayPermission(),
          ).thenAnswer((_) async => false);

          // act & assert
          expect(() => repository.startDeviceLock(), throwsA(isA<Exception>()));

          verify(mockDeviceAdminService.hasDeviceAdminPermission());
          verify(mockDeviceAdminService.hasOverlayPermission());
          verifyNever(mockDeviceAdminService.startDeviceLock());
        },
      );
    });

    group('endDeviceLock', () {
      test('should end device lock', () async {
        // arrange
        when(mockDeviceAdminService.endDeviceLock()).thenAnswer((_) async {});

        // act
        await repository.endDeviceLock();

        // assert
        verify(mockDeviceAdminService.endDeviceLock());
      });
    });

    group('hasRequiredPermissions', () {
      test('should return true when both permissions are granted', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        // act
        final result = await repository.hasRequiredPermissions();

        // assert
        expect(result, isTrue);
        verify(mockDeviceAdminService.hasDeviceAdminPermission());
        verify(mockDeviceAdminService.hasOverlayPermission());
      });

      test('should return false when admin permission is missing', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => false);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        // act
        final result = await repository.hasRequiredPermissions();

        // assert
        expect(result, isFalse);
        verify(mockDeviceAdminService.hasDeviceAdminPermission());
        verify(mockDeviceAdminService.hasOverlayPermission());
      });

      test('should return false when overlay permission is missing', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => false);

        // act
        final result = await repository.hasRequiredPermissions();

        // assert
        expect(result, isFalse);
        verify(mockDeviceAdminService.hasDeviceAdminPermission());
        verify(mockDeviceAdminService.hasOverlayPermission());
      });
    });

    group('hasDeviceAdminPermission', () {
      test('should return device admin permission status', () async {
        // arrange
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);

        // act
        final result = await repository.hasDeviceAdminPermission();

        // assert
        expect(result, isTrue);
        verify(mockDeviceAdminService.hasDeviceAdminPermission());
      });
    });

    group('hasOverlayPermission', () {
      test('should return overlay permission status', () async {
        // arrange
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        // act
        final result = await repository.hasOverlayPermission();

        // assert
        expect(result, isTrue);
        verify(mockDeviceAdminService.hasOverlayPermission());
      });
    });
  });
}
