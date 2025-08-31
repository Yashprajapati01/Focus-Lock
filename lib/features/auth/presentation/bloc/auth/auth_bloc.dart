import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/sign_in_with_google.dart';
import '../../../domain/usecases/skip_authentication.dart';
import '../../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle _signInWithGoogle;
  final SkipAuthentication _skipAuthentication;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;

  AuthBloc(
    this._signInWithGoogle,
    this._skipAuthentication,
    this._getCurrentUser,
    this._signOut,
  ) : super(const AuthInitial()) {
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSkipRequested>(_onSkipRequested);
    on<AuthGetCurrentUserRequested>(_onGetCurrentUserRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithGoogle();

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user.isAuthenticated) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> _onSkipRequested(
    AuthSkipRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _skipAuthentication();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onGetCurrentUserRequested(
    AuthGetCurrentUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCurrentUser();

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user.isAuthenticated) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signOut();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
