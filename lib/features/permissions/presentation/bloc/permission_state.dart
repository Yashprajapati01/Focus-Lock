import 'package:equatable/equatable.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';

abstract class PermissionState extends Equatable {
  const PermissionState();

  @override
  List<Object> get props => [];
}

class PermissionInitial extends PermissionState {
  const PermissionInitial();
}

class PermissionLoading extends PermissionState {
  const PermissionLoading();
}

class PermissionLoaded extends PermissionState {
  const PermissionLoaded({required this.permissions, required this.progress});

  final List<Permission> permissions;
  final PermissionProgress progress;

  @override
  List<Object> get props => [permissions, progress];
}

class PermissionUpdated extends PermissionState {
  const PermissionUpdated({
    required this.permissions,
    required this.progress,
    required this.updatedPermission,
  });

  final List<Permission> permissions;
  final PermissionProgress progress;
  final Permission updatedPermission;

  @override
  List<Object> get props => [permissions, progress, updatedPermission];
}

class PermissionError extends PermissionState {
  const PermissionError({
    required this.message,
    this.permissions = const [],
    this.progress,
  });

  final String message;
  final List<Permission> permissions;
  final PermissionProgress? progress;

  @override
  List<Object> get props => [message, permissions, progress ?? ''];
}

class PermissionRequestInProgress extends PermissionState {
  const PermissionRequestInProgress({
    required this.permissions,
    required this.progress,
    required this.requestingType,
  });

  final List<Permission> permissions;
  final PermissionProgress progress;
  final PermissionType requestingType;

  @override
  List<Object> get props => [permissions, progress, requestingType];
}

class PermissionAllGranted extends PermissionState {
  const PermissionAllGranted({
    required this.permissions,
    required this.progress,
  });

  final List<Permission> permissions;
  final PermissionProgress progress;

  @override
  List<Object> get props => [permissions, progress];
}
