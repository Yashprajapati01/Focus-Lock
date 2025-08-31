import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/core/errors/failures.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_all_permissions.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_progress.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_status.dart';
import 'package:focuslock/features/permissions/domain/usecases/open_permission_settings.dart';
import 'package:focuslock/features/permissions/domain/usecases/request_permission.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_bloc.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_event.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_state.dart';

import 'permission_bloc_test.mocks.dart';

@GenerateMocks([
  GetAllPermissions,
  RequestPermission,
  GetPermissionStatus,
  GetPermissionProgress,
  OpenPermissionSettings,
])
void main() {
  late PermissionBloc bloc;
  late MockGetAllPermissions mockGetAllPermissions;
  late MockRequestPermission mockRequestPermission;
  late MockGetPermissionStatus mockGetPermissionStatus;
  late MockGetPermissionProgress mockGetPermissionProgress;
  late MockOpenPermissionSettings mockOpenPermissionSettings;

  setUp(() {
    mockGetAllPermissions = MockGetAllPermissions();
    mockRequestPermission = MockRequestPermission();
    mockGetPermissionStatus = MockGetPermissionStatus();
    mockGetPermissionProgress = MockGetPermissionProgress();
    mockOpenPermissionSettings = MockOpenPermissionSettings();

    bloc = PermissionBloc(
      getAllPermissions: mockGetAllPermissions,
      requestPermission: mockRequestPermission,
      getPermissionStatus: mockGetPermissionStatus,
      getPermissionProgress: mockGetPermissionProgress,
      openPermissionSettings: mockOpenPermissionSettings,
    );
  });

  const tPermissions = [
    Permission(
      type: PermissionType.notification,
      status: PermissionStatus.pending,
      title: 'Notifications',
      description: 'Allow notifications',
      icon: Icons.notifications,
    ),
    Permission(
      type: PermissionType.admin,
      status: PermissionStatus.denied,
      title: 'Device Admin',
      description: 'Allow device admin',
      icon: Icons.admin_panel_settings,
    ),
  ];

  const tProgress = PermissionProgress(
    totalPermissions: 4,
    grantedPermissions: 0,
    progressPercentage: 0.0,
    isComplete: false,
  );

  const tUpdatedPermission = Permission(
    type: PermissionType.notification,
    status: PermissionStatus.granted,
    title: 'Notifications',
    description: 'Allow notifications',
    icon: Icons.notifications,
  );

  group('PermissionBloc', () {
    test('initial state is PermissionInitial', () {
      expect(bloc.state, const PermissionInitial());
    });

    group('LoadAllPermissions', () {
      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionLoading, PermissionLoaded] when successful',
        build: () {
          when(
            mockGetAllPermissions(),
          ).thenAnswer((_) async => const Right(tPermissions));
          when(
            mockGetPermissionProgress(),
          ).thenAnswer((_) async => const Right(tProgress));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAllPermissions()),
        expect: () => [
          const PermissionLoading(),
          const PermissionLoaded(
            permissions: tPermissions,
            progress: tProgress,
          ),
        ],
      );

      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionLoading, PermissionError] when get permissions fails',
        build: () {
          when(mockGetAllPermissions()).thenAnswer(
            (_) async =>
                const Left(PermissionFailure('Failed to get permissions')),
          );
          when(
            mockGetPermissionProgress(),
          ).thenAnswer((_) async => const Right(tProgress));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAllPermissions()),
        expect: () => [
          const PermissionLoading(),
          const PermissionError(message: 'Failed to get permissions'),
        ],
      );
    });

    group('RequestPermissionEvent', () {
      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionRequestInProgress, PermissionUpdated] when successful',
        build: () {
          when(
            mockRequestPermission(any),
          ).thenAnswer((_) async => const Right(tUpdatedPermission));
          when(
            mockGetPermissionProgress(),
          ).thenAnswer((_) async => const Right(tProgress));
          return bloc;
        },
        seed: () => const PermissionLoaded(
          permissions: tPermissions,
          progress: tProgress,
        ),
        act: (bloc) => bloc.add(
          const RequestPermissionEvent(type: PermissionType.notification),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const PermissionRequestInProgress(
            permissions: tPermissions,
            progress: tProgress,
            requestingType: PermissionType.notification,
          ),
          PermissionUpdated(
            permissions: [
              tUpdatedPermission,
              tPermissions[1], // admin permission unchanged
            ],
            progress: tProgress,
            updatedPermission: tUpdatedPermission,
          ),
        ],
      );

      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionRequestInProgress, PermissionError] when request fails',
        build: () {
          when(mockRequestPermission(any)).thenAnswer(
            (_) async => const Left(PermissionFailure('Permission denied')),
          );
          return bloc;
        },
        seed: () => const PermissionLoaded(
          permissions: tPermissions,
          progress: tProgress,
        ),
        act: (bloc) => bloc.add(
          const RequestPermissionEvent(type: PermissionType.notification),
        ),
        expect: () => [
          const PermissionRequestInProgress(
            permissions: tPermissions,
            progress: tProgress,
            requestingType: PermissionType.notification,
          ),
          const PermissionError(
            message: 'Permission denied',
            permissions: tPermissions,
            progress: tProgress,
          ),
        ],
      );
    });

    group('CheckPermissionStatus', () {
      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionLoaded] with updated permission when successful',
        build: () {
          when(
            mockGetPermissionStatus(any),
          ).thenAnswer((_) async => const Right(tUpdatedPermission));
          return bloc;
        },
        seed: () => const PermissionLoaded(
          permissions: tPermissions,
          progress: tProgress,
        ),
        act: (bloc) => bloc.add(
          const CheckPermissionStatus(type: PermissionType.notification),
        ),
        expect: () => [
          PermissionLoaded(
            permissions: [
              tUpdatedPermission,
              tPermissions[1], // admin permission unchanged
            ],
            progress: tProgress,
          ),
        ],
      );
    });

    group('RefreshPermissionProgress', () {
      const tNewProgress = PermissionProgress(
        totalPermissions: 4,
        grantedPermissions: 2,
        progressPercentage: 0.5,
        isComplete: false,
      );

      blocTest<PermissionBloc, PermissionState>(
        'emits [PermissionLoaded] with updated progress when successful',
        build: () {
          when(
            mockGetPermissionProgress(),
          ).thenAnswer((_) async => const Right(tNewProgress));
          return bloc;
        },
        seed: () => const PermissionLoaded(
          permissions: tPermissions,
          progress: tProgress,
        ),
        act: (bloc) => bloc.add(const RefreshPermissionProgress()),
        expect: () => [
          const PermissionLoaded(
            permissions: tPermissions,
            progress: tNewProgress,
          ),
        ],
      );
    });
  });
}
