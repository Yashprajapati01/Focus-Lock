import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/domain/entities/user.dart';
import 'package:focuslock/features/auth/domain/usecases/get_current_user.dart';
import 'package:focuslock/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:focuslock/features/auth/domain/usecases/skip_authentication.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/core/errors/failures.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([SignInWithGoogle, SkipAuthentication, GetCurrentUser])
void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSkipAuthentication mockSkipAuthentication;
  late MockGetCurrentUser mockGetCurrentUser;

  setUp(() {
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSkipAuthentication = MockSkipAuthentication();
    mockGetCurrentUser = MockGetCurrentUser();
    authBloc = AuthBloc(
      mockSignInWithGoogle,
      mockSkipAuthentication,
      mockGetCurrentUser,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const tUser = User(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isAuthenticated: true,
  );

  const tUnauthenticatedUser = User.unauthenticated();

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    group('AuthSignInWithGoogleRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthAuthenticated] when sign in is successful',
        build: () {
          when(
            mockSignInWithGoogle(),
          ).thenAnswer((_) async => const Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
        expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
        verify: (_) {
          verify(mockSignInWithGoogle()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(mockSignInWithGoogle()).thenAnswer(
            (_) async => const Left(GoogleSignInFailure('Sign in failed')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
        expect: () => [const AuthLoading(), const AuthError('Sign in failed')],
        verify: (_) {
          verify(mockSignInWithGoogle()).called(1);
        },
      );
    });

    group('AuthSkipRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthUnauthenticated] when skip is successful',
        build: () {
          when(
            mockSkipAuthentication(),
          ).thenAnswer((_) async => const Right(tUnauthenticatedUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSkipRequested()),
        expect: () => [const AuthLoading(), const AuthUnauthenticated()],
        verify: (_) {
          verify(mockSkipAuthentication()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthError] when skip fails',
        build: () {
          when(
            mockSkipAuthentication(),
          ).thenAnswer((_) async => const Left(SystemFailure('Skip failed')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSkipRequested()),
        expect: () => [const AuthLoading(), const AuthError('Skip failed')],
        verify: (_) {
          verify(mockSkipAuthentication()).called(1);
        },
      );
    });

    group('AuthGetCurrentUserRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthAuthenticated] when user is authenticated',
        build: () {
          when(
            mockGetCurrentUser(),
          ).thenAnswer((_) async => const Right(tUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthGetCurrentUserRequested()),
        expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
        verify: (_) {
          verify(mockGetCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit [AuthLoading, AuthUnauthenticated] when user is not authenticated',
        build: () {
          when(
            mockGetCurrentUser(),
          ).thenAnswer((_) async => const Right(tUnauthenticatedUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthGetCurrentUserRequested()),
        expect: () => [const AuthLoading(), const AuthUnauthenticated()],
        verify: (_) {
          verify(mockGetCurrentUser()).called(1);
        },
      );
    });
  });
}
