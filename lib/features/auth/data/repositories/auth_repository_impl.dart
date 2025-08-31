import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_sign_in_service.dart';
import '../datasources/local_storage_service.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final GoogleSignInService _googleSignInService;
  final LocalStorageService _localStorageService;

  AuthRepositoryImpl(this._googleSignInService, this._localStorageService);

  @override
  ResultFuture<User> signInWithGoogle() async {
    try {
      final user = await _googleSignInService.signInWithGoogle();
      await _localStorageService.saveUser(user);
      return Right(user);
    } on GoogleSignInFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        AuthenticationFailure(
          'Unexpected error during sign in: ${e.toString()}',
        ),
      );
    }
  }

  @override
  ResultFuture<User> skipAuthentication() async {
    try {
      const user = UserModel.unauthenticated();
      await _localStorageService.saveUser(user);
      return const Right(user);
    } catch (e) {
      return Left(
        SystemFailure('Failed to skip authentication: ${e.toString()}'),
      );
    }
  }

  @override
  ResultFuture<User> getCurrentUser() async {
    try {
      final cachedUser = await _localStorageService.getUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }

      // Check if user is still signed in with Google
      final googleUser = await _googleSignInService.getCurrentUser();
      if (googleUser != null) {
        await _localStorageService.saveUser(googleUser);
        return Right(googleUser);
      }

      // Return unauthenticated user if no cached or Google user found
      const unauthenticatedUser = UserModel.unauthenticated();
      return const Right(unauthenticatedUser);
    } catch (e) {
      return Left(SystemFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  ResultVoid signOut() async {
    try {
      await _googleSignInService.signOut();
      await _localStorageService.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to sign out: ${e.toString()}'));
    }
  }

  @override
  ResultFuture<bool> isAuthenticated() async {
    try {
      final userResult = await getCurrentUser();
      return userResult.fold(
        (failure) => Left(failure),
        (user) => Right(user.isAuthenticated),
      );
    } catch (e) {
      return Left(
        SystemFailure('Failed to check authentication status: ${e.toString()}'),
      );
    }
  }
}
