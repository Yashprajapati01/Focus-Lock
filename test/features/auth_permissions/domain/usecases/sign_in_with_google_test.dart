import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/domain/entities/user.dart';
import 'package:focuslock/features/auth/domain/repositories/auth_repository.dart';
import 'package:focuslock/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_current_user_test.mocks.dart';


@GenerateMocks([AuthRepository])
void main() {
  late SignInWithGoogle usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithGoogle(mockAuthRepository);
  });

  const tUser = User(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isAuthenticated: true,
  );

  test(
    'should get user from the repository when sign in is successful',
    () async {
      // arrange
      when(
        mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Right(tUser));

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(tUser));
      verify(mockAuthRepository.signInWithGoogle());
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );
}
