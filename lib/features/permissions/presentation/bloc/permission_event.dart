import 'package:equatable/equatable.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';

abstract class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object> get props => [];
}

class LoadAllPermissions extends PermissionEvent {
  const LoadAllPermissions();
}

class RequestPermissionEvent extends PermissionEvent {
  const RequestPermissionEvent({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}

class CheckPermissionStatus extends PermissionEvent {
  const CheckPermissionStatus({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}

class RefreshPermissionProgress extends PermissionEvent {
  const RefreshPermissionProgress();
}

class OpenPermissionSettingsEvent extends PermissionEvent {
  const OpenPermissionSettingsEvent({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}
