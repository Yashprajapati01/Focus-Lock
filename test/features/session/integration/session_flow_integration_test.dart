import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/data/repositories/session_repository_impl.dart';
import 'package:focuslock/features/session/data/datasources/session_local_datasource.dart';
import 'package:focuslock/features/session/data/services/device_admin_service.dart';
import 'package:focuslock/features/session/data/models/session_config_model.dart';
import 'package:focuslock/features/session/domain/usecases/start_session.dart';
import 'package:focuslock/features/session/domain/usecases/cancel_session.dart';
import 'package:focuslock/features/session/domain/usecases/load_session_config.dart';
import 'package:focuslock/features/session/domain/usecases/save_session_config.dart';

@GenerateMocks([SessionLocalDataSource, DeviceAdminService])
import 'session_flow_integration_test.mocks.dart';

void main() {
  group('Session Flow Integration', () {
    late SessionRepositoryImpl repository;
    late MockSessionLocalDataSource mockLocalDataSource;
    late MockDeviceAdminService mockDeviceAdminService;
    late StartSession startSession;
    late CancelSession cancelSession;
    late LoadSessionConfig loadSessionConfig;
    late SaveSessionConfig saveSessionConfig;

    setUp(() {
      mockLocalDataSource = MockSessionLocalDataSource();
      mockDeviceAdminService = MockDeviceAdminService();
      repository = SessionRepositoryImpl(
        localDataSource: mockLocalDataSource,
        deviceAdminService: mockDeviceAdminService,
      );
      startSession = StartSession(repository);
      cancelSession = CancelSession(repository);
      loadSessionConfig = LoadSessionConfig(repository);
      saveSessionConfig = SaveSessionConfig(repository);
    });

    group('Complete Session Flow', () {
      testWidgets('successfully completes full session lifecycle', (
        tester,
      ) async {
        const testConfig = SessionConfig(duration: Duration(minutes: 30));

        // Mock successful permissions
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);
        when(mockDeviceAdminService.startDeviceLock()).thenAnswer((_) async {});
        when(mockDeviceAdminService.endDeviceLock()).thenAnswer((_) async {});

        // Mock data source operations
        when(
          mockLocalDataSource.cacheSessionConfig(any),
        ).thenAnswer((_) async {});

        // 1. Start session
        final startResult = await startSession(testConfig);
        expect(startResult.isRight(), isTrue);

        // Verify device lock was started
        verify(mockDeviceAdminService.startDeviceLock()).called(1);
        verify(mockLocalDataSource.cacheSessionConfig(any)).called(1);

        // 2. Cancel session
        final cancelResult = await cancelSession();
        expect(cancelResult.isRight(), isTrue);

        // Verify device lock was ended
        verify(mockDeviceAdminService.endDeviceLock()).called(1);
      });

      testWidgets('fails to start session without device admin permission', (
        tester,
      ) async {
        const testConfig = SessionConfig(duration: Duration(minutes: 30));

        // Mock missing device admin permission
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => false);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        final result = await startSession(testConfig);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure.message,
            contains('Required permissions not granted'),
          ),
          (_) => fail('Expected failure'),
        );

        // Verify device lock was not started
        verifyNever(mockDeviceAdminService.startDeviceLock());
      });

      testWidgets('fails to start session without overlay permission', (
        tester,
      ) async {
        const testConfig = SessionConfig(duration: Duration(minutes: 30));

        // Mock missing overlay permission
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => false);

        final result = await startSession(testConfig);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure.message,
            contains('Required permissions not granted'),
          ),
          (_) => fail('Expected failure'),
        );

        // Verify device lock was not started
        verifyNever(mockDeviceAdminService.startDeviceLock());
      });

      testWidgets('handles device lock failure gracefully', (tester) async {
        const testConfig = SessionConfig(duration: Duration(minutes: 30));

        // Mock successful permissions but device lock failure
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.startDeviceLock(),
        ).thenThrow(Exception('Device lock failed'));

        // Mock data source operations
        when(
          mockLocalDataSource.cacheSessionConfig(any),
        ).thenAnswer((_) async {});

        final result = await startSession(testConfig);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure.message, contains('Failed to start session')),
          (_) => fail('Expected failure'),
        );
      });

      testWidgets(
        'handles session cancellation even when device unlock fails',
        (tester) async {
          // Mock device unlock failure
          when(
            mockDeviceAdminService.endDeviceLock(),
          ).thenThrow(Exception('Device unlock failed'));

          final result = await cancelSession();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure.message, contains('Failed to cancel session')),
            (_) => fail('Expected failure'),
          );
        },
      );
    });

    group('Configuration Management', () {
      testWidgets('saves and loads session configuration', (tester) async {
        const testConfig = SessionConfig(
          duration: Duration(minutes: 45),
          lastUsed: null,
        );

        // Mock successful save
        when(
          mockLocalDataSource.cacheSessionConfig(any),
        ).thenAnswer((_) async {});

        // Save configuration
        final saveResult = await saveSessionConfig(testConfig);
        expect(saveResult.isRight(), isTrue);

        verify(mockLocalDataSource.cacheSessionConfig(any)).called(1);

        // Mock successful load
        when(
          mockLocalDataSource.getSessionConfig(),
        ).thenAnswer((_) async => SessionConfigModel.fromEntity(testConfig));

        // Load configuration
        final loadResult = await loadSessionConfig();
        expect(loadResult.isRight(), isTrue);

        loadResult.fold(
          (_) => fail('Expected success'),
          (config) => expect(config.duration, equals(testConfig.duration)),
        );
      });

      testWidgets('returns default config when loading fails', (tester) async {
        // Mock load failure
        when(
          mockLocalDataSource.getSessionConfig(),
        ).thenThrow(Exception('Load failed'));

        final result = await loadSessionConfig();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success'),
          (config) =>
              expect(config.duration, equals(const Duration(minutes: 30))),
        );
      });

      testWidgets('handles save failure gracefully', (tester) async {
        const testConfig = SessionConfig(duration: Duration(minutes: 30));

        // Mock save failure
        when(
          mockLocalDataSource.cacheSessionConfig(any),
        ).thenThrow(Exception('Save failed'));

        final result = await saveSessionConfig(testConfig);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure.message,
            contains('Failed to save session config'),
          ),
          (_) => fail('Expected failure'),
        );
      });
    });

    group('Permission Checking', () {
      testWidgets('correctly identifies when all permissions are granted', (
        tester,
      ) async {
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => true);

        final hasPermissions = await repository.hasRequiredPermissions();
        expect(hasPermissions, isTrue);
      });

      testWidgets(
        'correctly identifies when device admin permission is missing',
        (tester) async {
          when(
            mockDeviceAdminService.hasDeviceAdminPermission(),
          ).thenAnswer((_) async => false);
          when(
            mockDeviceAdminService.hasOverlayPermission(),
          ).thenAnswer((_) async => true);

          final hasPermissions = await repository.hasRequiredPermissions();
          expect(hasPermissions, isFalse);
        },
      );

      testWidgets('correctly identifies when overlay permission is missing', (
        tester,
      ) async {
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => true);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => false);

        final hasPermissions = await repository.hasRequiredPermissions();
        expect(hasPermissions, isFalse);
      });

      testWidgets('correctly identifies when both permissions are missing', (
        tester,
      ) async {
        when(
          mockDeviceAdminService.hasDeviceAdminPermission(),
        ).thenAnswer((_) async => false);
        when(
          mockDeviceAdminService.hasOverlayPermission(),
        ).thenAnswer((_) async => false);

        final hasPermissions = await repository.hasRequiredPermissions();
        expect(hasPermissions, isFalse);
      });
    });
  });
}
