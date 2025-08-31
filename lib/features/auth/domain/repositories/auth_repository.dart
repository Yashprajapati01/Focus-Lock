import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Sign in with Google
  ResultFuture<User> signInWithGoogle();

  /// Skip authentication and continue as unauthenticated user
  ResultFuture<User> skipAuthentication();

  /// Get current user from local storage
  ResultFuture<User> getCurrentUser();

  /// Sign out current user
  ResultVoid signOut();

  /// Check if user is currently authenticated
  ResultFuture<bool> isAuthenticated();
}
