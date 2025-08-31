import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/permissions/domain/repositories/permission_repository.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_status.dart';

import 'get_permission_status_test.mocks.dart';

@GenerateMocks([PermissionRepository])
void main() {
  late GetPermissionStatus usecase;
  late MockPermissionRepository mockRepository;

  setUp(() {
    mockRepository = MockPermissionRepository();
    usecase = GetPermissionStatus(mockRepository);
  });

  const tPermissionType = PermissionType.notification;
  const tPermission = Permission(
    type: PermissionType.notification,
    status: PermissionStatus.granted,
    title: 'Notifications',
    description: 'Allow the app to send you notifications',
    icon: Icons.notifications,
  );

  test('should get permission status from repository', () async {
    // arrange
    when(
      mockRepository.getPermissionStatus(any),
    ).thenAnswer((_) async => const Right(tPermission));

    // act
    final result = await usecase(
      const GetPermissionStatusParams(type: tPermissionType),
    );

    // assert
    expect(result, const Right(tPermission));
    verify(mockRepository.getPermissionStatus(tPermissionType));
    verifyNoMoreInteractions(mockRepository);
  });
}
