import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class SessionFailure extends Failure {
  const SessionFailure(String message) : super(message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

class DeviceAdminFailure extends Failure {
  const DeviceAdminFailure(String message) : super(message);
}

class DataFailure extends Failure {
  const DataFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}
