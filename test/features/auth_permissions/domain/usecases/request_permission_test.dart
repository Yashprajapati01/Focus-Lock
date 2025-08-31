import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/permissions/domain/repositories/permission_repository.dart';
import 'package:focuslock/features/permissions/domain/usecases/request_permission.dart';

import 'request_permission_test.mocks.dart';

@GenerateMocks([PermissionRepository])
void main() {
  late RequestPermission usecase;
  late MockPermissionRepository mockPermissionRepository;

  setUp(() {
    mockPermissionRepository = MockPermissionRepository();
    usecase = RequestPermission(mockPermissionRepository);
  });

  const tPermission = Permission(
    type: PermissionType.notification,
    status: PermissionStatus.granted,
    title: 'Notifications',
    description: 'Allow notifications',
    icon: Icons.notifications,
  );

  const tParams = RequestPermissionParams(type: PermissionType.notification);

  test('should request permission from the repository', () async {
    // arrange
    when(
      mockPermissionRepository.requestPermission(any),
    ).thenAnswer((_) async => const Right(tPermission));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Right(tPermission));
    verify(
      mockPermissionRepository.requestPermission(PermissionType.notification),
    );
    verifyNoMoreInteractions(mockPermissionRepository);
  });
}
