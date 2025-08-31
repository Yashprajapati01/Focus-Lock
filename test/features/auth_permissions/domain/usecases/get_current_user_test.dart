import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/domain/entities/user.dart';
import 'package:focuslock/features/auth/domain/repositories/auth_repository.dart';
import 'package:focuslock/features/auth/domain/usecases/get_current_user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_current_user_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockAuthRepository);
  });

  const tUser = User(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isAuthenticated: true,
  );

  test('should get current user from the repository', () async {
    // arrange
    when(
      mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase();

    // assert
    expect(result, const Right(tUser));
    verify(mockAuthRepository.getCurrentUser());
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
