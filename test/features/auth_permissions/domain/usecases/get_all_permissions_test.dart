import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/permissions/domain/repositories/permission_repository.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_all_permissions.dart';

import 'get_all_permissions_test.mocks.dart';

@GenerateMocks([PermissionRepository])
void main() {
  late GetAllPermissions usecase;
  late MockPermissionRepository mockPermissionRepository;

  setUp(() {
    mockPermissionRepository = MockPermissionRepository();
    usecase = GetAllPermissions(mockPermissionRepository);
  });

  const tPermissions = [
    Permission(
      type: PermissionType.notification,
      status: PermissionStatus.granted,
      title: 'Notifications',
      description: 'Allow notifications',
      icon: Icons.notifications,
    ),
    Permission(
      type: PermissionType.admin,
      status: PermissionStatus.pending,
      title: 'Device Admin',
      description: 'Allow device admin',
      icon: Icons.admin_panel_settings,
    ),
  ];

  test('should get all permissions from the repository', () async {
    // arrange
    when(
      mockPermissionRepository.getAllPermissionStatuses(),
    ).thenAnswer((_) async => const Right(tPermissions));

    // act
    final result = await usecase();

    // assert
    expect(result, const Right(tPermissions));
    verify(mockPermissionRepository.getAllPermissionStatuses());
    verifyNoMoreInteractions(mockPermissionRepository);
  });
}
