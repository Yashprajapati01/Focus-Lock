import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  String get message;

  @override
  List<Object> get props => [];
}

// Authentication failures
class AuthenticationFailure extends Failure {
  @override
  final String message;

  const AuthenticationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class GoogleSignInFailure extends AuthenticationFailure {
  const GoogleSignInFailure(super.message);
}

class NetworkFailure extends Failure {
  @override
  final String message;

  const NetworkFailure(this.message);

  @override
  List<Object> get props => [message];
}

// Permission failures
class PermissionFailure extends Failure {
  @override
  final String message;
  
  const PermissionFailure(this.message);
  
  @override
  List<Object> get props => [message];
  
  @override
  String toString() => 'PermissionFailure: $message';
}

class PermissionDeniedFailure extends PermissionFailure {
  const PermissionDeniedFailure(super.message);
}

class PermissionUnavailableFailure extends PermissionFailure {
  const PermissionUnavailableFailure(super.message);
}

class SystemFailure extends Failure {
  @override
  final String message;

  const SystemFailure(this.message);

  @override
  List<Object> get props => [message];
}
