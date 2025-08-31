
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_all_permissions.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_progress.dart';
import 'package:focuslock/features/permissions/domain/usecases/get_permission_status.dart';
import 'package:focuslock/features/permissions/domain/usecases/open_permission_settings.dart';
import 'package:focuslock/features/permissions/domain/usecases/request_permission.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_bloc_exports.dart';
import 'package:injectable/injectable.dart';

@injectable
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  PermissionBloc({
    required GetAllPermissions getAllPermissions,
    required RequestPermission requestPermission,
    required GetPermissionStatus getPermissionStatus,
    required GetPermissionProgress getPermissionProgress,
    required OpenPermissionSettings openPermissionSettings,
  }) : _getAllPermissions = getAllPermissions,
       _requestPermission = requestPermission,
       _getPermissionStatus = getPermissionStatus,
       _getPermissionProgress = getPermissionProgress,
       _openPermissionSettings = openPermissionSettings,
       super(const PermissionInitial()) {
    on<LoadAllPermissions>(_onLoadAllPermissions);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<CheckPermissionStatus>(_onCheckPermissionStatus);
    on<RefreshPermissionProgress>(_onRefreshPermissionProgress);
    on<OpenPermissionSettingsEvent>(_onOpenPermissionSettings);
  }

  final GetAllPermissions _getAllPermissions;
  final RequestPermission _requestPermission;
  final GetPermissionStatus _getPermissionStatus;
  final GetPermissionProgress _getPermissionProgress;
  final OpenPermissionSettings _openPermissionSettings;

  Future<void> _onLoadAllPermissions(
    LoadAllPermissions event,
    Emitter<PermissionState> emit,
  ) async {
    emit(const PermissionLoading());

    final permissionsResult = await _getAllPermissions();
    final progressResult = await _getPermissionProgress();

    permissionsResult.fold(
      (failure) => emit(PermissionError(message: failure.message)),
      (permissions) {
        progressResult.fold(
          (failure) => emit(
            PermissionError(message: failure.message, permissions: permissions),
          ),
          (progress) {
            if (progress.isComplete) {
              emit(
                PermissionAllGranted(
                  permissions: permissions,
                  progress: progress,
                ),
              );
            } else {
              emit(
                PermissionLoaded(permissions: permissions, progress: progress),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    final currentState = state;
    if (currentState is PermissionLoaded) {
      emit(
        PermissionRequestInProgress(
          permissions: currentState.permissions,
          progress: currentState.progress,
          requestingType: event.type,
        ),
      );

      final result = await _requestPermission(
        RequestPermissionParams(type: event.type),
      );

      await result.fold(
        (failure) async => emit(
          PermissionError(
            message: failure.message,
            permissions: currentState.permissions,
            progress: currentState.progress,
          ),
        ),
        (updatedPermission) async {
          // Update the permissions list with the new permission status
          final updatedPermissions = currentState.permissions.map((permission) {
            return permission.type == event.type
                ? updatedPermission
                : permission;
          }).toList();

          // Refresh progress
          final progressResult = await _getPermissionProgress();
          if (!emit.isDone) {
            progressResult.fold(
              (failure) => emit(
                PermissionError(
                  message: failure.message,
                  permissions: updatedPermissions,
                  progress: currentState.progress,
                ),
              ),
              (newProgress) {
                if (newProgress.isComplete) {
                  emit(
                    PermissionAllGranted(
                      permissions: updatedPermissions,
                      progress: newProgress,
                    ),
                  );
                } else {
                  emit(
                    PermissionUpdated(
                      permissions: updatedPermissions,
                      progress: newProgress,
                      updatedPermission: updatedPermission,
                    ),
                  );
                }
              },
            );
          }
        },
      );
    }
  }

  Future<void> _onCheckPermissionStatus(
    CheckPermissionStatus event,
    Emitter<PermissionState> emit,
  ) async {
    final result = await _getPermissionStatus(
      GetPermissionStatusParams(type: event.type),
    );

    result.fold(
      (failure) {
        if (state is PermissionLoaded) {
          final currentState = state as PermissionLoaded;
          emit(
            PermissionError(
              message: failure.message,
              permissions: currentState.permissions,
              progress: currentState.progress,
            ),
          );
        } else {
          emit(PermissionError(message: failure.message));
        }
      },
      (permission) {
        if (state is PermissionLoaded) {
          final currentState = state as PermissionLoaded;
          final updatedPermissions = currentState.permissions.map((p) {
            return p.type == event.type ? permission : p;
          }).toList();

          emit(
            PermissionLoaded(
              permissions: updatedPermissions,
              progress: currentState.progress,
            ),
          );
        }
      },
    );
  }

  Future<void> _onRefreshPermissionProgress(
    RefreshPermissionProgress event,
    Emitter<PermissionState> emit,
  ) async {
    final result = await _getPermissionProgress();

    result.fold(
      (failure) {
        if (state is PermissionLoaded) {
          final currentState = state as PermissionLoaded;
          emit(
            PermissionError(
              message: failure.message,
              permissions: currentState.permissions,
              progress: currentState.progress,
            ),
          );
        } else {
          emit(PermissionError(message: failure.message));
        }
      },
      (progress) {
        if (state is PermissionLoaded) {
          final currentState = state as PermissionLoaded;
          emit(
            PermissionLoaded(
              permissions: currentState.permissions,
              progress: progress,
            ),
          );
        }
      },
    );
  }

  Future<void> _onOpenPermissionSettings(
    OpenPermissionSettingsEvent event,
    Emitter<PermissionState> emit,
  ) async {
    final result = await _openPermissionSettings(
      OpenPermissionSettingsParams(type: event.type),
    );

    result.fold(
      (failure) {
        if (state is PermissionLoaded) {
          final currentState = state as PermissionLoaded;
          emit(
            PermissionError(
              message: failure.message,
              permissions: currentState.permissions,
              progress: currentState.progress,
            ),
          );
        } else {
          emit(PermissionError(message: failure.message));
        }
      },
      (_) {
        // Settings opened successfully, no state change needed
        // The user will return to the app and we can check status again
      },
    );
  }
}
