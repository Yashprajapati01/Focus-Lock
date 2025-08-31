import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/features/permissions/domain/repositories/permission_repository.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_progress.dart';

import 'get_permission_progress_test.mocks.dart';

@GenerateMocks([PermissionRepository])
void main() {
  late GetPermissionProgress usecase;
  late MockPermissionRepository mockPermissionRepository;

  setUp(() {
    mockPermissionRepository = MockPermissionRepository();
    usecase = GetPermissionProgress(mockPermissionRepository);
  });

  const tProgress = PermissionProgress(
    totalPermissions: 4,
    grantedPermissions: 2,
    progressPercentage: 0.5,
    isComplete: false,
  );

  test('should get permission progress from the repository', () async {
    // arrange
    when(
      mockPermissionRepository.getPermissionProgress(),
    ).thenAnswer((_) async => const Right(tProgress));

    // act
    final result = await usecase();

    // assert
    expect(result, const Right(tProgress));
    verify(mockPermissionRepository.getPermissionProgress());
    verifyNoMoreInteractions(mockPermissionRepository);
  });
}
