import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

class AuthSkipRequested extends AuthEvent {
  const AuthSkipRequested();
}

class AuthGetCurrentUserRequested extends AuthEvent {
  const AuthGetCurrentUserRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
