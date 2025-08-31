// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:focuslock/features/auth/data/datasources/google_sign_in_service.dart'
    as _i750;
import 'package:focuslock/features/auth/data/datasources/local_storage_service.dart'
    as _i850;
import 'package:focuslock/features/auth/data/repositories/auth_repository_impl.dart'
    as _i759;
import 'package:focuslock/features/auth/domain/repositories/auth_repository.dart'
    as _i428;
import 'package:focuslock/features/auth/domain/usecases/get_current_user.dart'
    as _i863;
import 'package:focuslock/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i1030;
import 'package:focuslock/features/auth/domain/usecases/skip_authentication.dart'
    as _i405;
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_bloc.dart'
    as _i874;
import 'package:focuslock/features/permissions/data/datasources/permission_service.dart'
    as _i470;
import 'package:focuslock/features/permissions/data/datasources/permission_storage_service.dart'
    as _i727;
import 'package:focuslock/features/permissions/data/datasources/platform_permission_service.dart'
    as _i752;
import 'package:focuslock/features/permissions/data/repositories/permission_repository_impl.dart'
    as _i856;
import 'package:focuslock/features/permissions/domain/repositories/permission_repository.dart'
    as _i885;
import 'package:focuslock/features/permissions/domain/usecases/get_all_permissions.dart'
    as _i602;
import 'package:focuslock/features/permissions/domain/usecases/get_permission_progress.dart'
    as _i577;
import 'package:focuslock/features/permissions/domain/usecases/get_permission_status.dart'
    as _i909;
import 'package:focuslock/features/permissions/domain/usecases/open_permission_settings.dart'
    as _i904;
import 'package:focuslock/features/permissions/domain/usecases/request_permission.dart'
    as _i594;
import 'package:focuslock/features/permissions/presentation/bloc/permission_bloc.dart'
    as _i855;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final localStorageModule = _$LocalStorageModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => localStorageModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i752.PlatformPermissionService>(
      () => _i752.PlatformPermissionServiceImpl(),
    );
    gh.lazySingleton<_i727.PermissionStorageService>(
      () => _i727.PermissionStorageServiceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i850.LocalStorageService>(
      () => _i850.LocalStorageServiceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i750.GoogleSignInService>(
      () => _i750.GoogleSignInServiceImpl(),
    );
    gh.lazySingleton<_i470.PermissionService>(
      () => _i470.PermissionServiceImpl(gh<_i752.PlatformPermissionService>()),
    );
    gh.lazySingleton<_i428.AuthRepository>(
      () => _i759.AuthRepositoryImpl(
        gh<_i750.GoogleSignInService>(),
        gh<_i850.LocalStorageService>(),
      ),
    );
    gh.lazySingleton<_i885.PermissionRepository>(
      () => _i856.PermissionRepositoryImpl(
        gh<_i470.PermissionService>(),
        gh<_i727.PermissionStorageService>(),
      ),
    );
    gh.lazySingleton<_i863.GetCurrentUser>(
      () => _i863.GetCurrentUser(gh<_i428.AuthRepository>()),
    );
    gh.lazySingleton<_i1030.SignInWithGoogle>(
      () => _i1030.SignInWithGoogle(gh<_i428.AuthRepository>()),
    );
    gh.lazySingleton<_i405.SkipAuthentication>(
      () => _i405.SkipAuthentication(gh<_i428.AuthRepository>()),
    );
    gh.factory<_i874.AuthBloc>(
      () => _i874.AuthBloc(
        gh<_i1030.SignInWithGoogle>(),
        gh<_i405.SkipAuthentication>(),
        gh<_i863.GetCurrentUser>(),
      ),
    );
    gh.lazySingleton<_i602.GetAllPermissions>(
      () => _i602.GetAllPermissions(gh<_i885.PermissionRepository>()),
    );
    gh.lazySingleton<_i577.GetPermissionProgress>(
      () => _i577.GetPermissionProgress(gh<_i885.PermissionRepository>()),
    );
    gh.lazySingleton<_i909.GetPermissionStatus>(
      () => _i909.GetPermissionStatus(gh<_i885.PermissionRepository>()),
    );
    gh.lazySingleton<_i904.OpenPermissionSettings>(
      () => _i904.OpenPermissionSettings(gh<_i885.PermissionRepository>()),
    );
    gh.lazySingleton<_i594.RequestPermission>(
      () => _i594.RequestPermission(gh<_i885.PermissionRepository>()),
    );
    gh.factory<_i855.PermissionBloc>(
      () => _i855.PermissionBloc(
        getAllPermissions: gh<_i602.GetAllPermissions>(),
        requestPermission: gh<_i594.RequestPermission>(),
        getPermissionStatus: gh<_i909.GetPermissionStatus>(),
        getPermissionProgress: gh<_i577.GetPermissionProgress>(),
        openPermissionSettings: gh<_i904.OpenPermissionSettings>(),
      ),
    );
    return this;
  }
}

class _$LocalStorageModule extends _i850.LocalStorageModule {}
