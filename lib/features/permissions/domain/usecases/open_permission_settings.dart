import 'package:equatable/equatable.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../repositories/permission_repository.dart';

class OpenPermissionSettingsParams extends Equatable {
  const OpenPermissionSettingsParams({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}

@lazySingleton
class OpenPermissionSettings
    extends UsecaseWithParams<void, OpenPermissionSettingsParams> {
  const OpenPermissionSettings(this._repository);

  final PermissionRepository _repository;

  @override
  ResultVoid call(OpenPermissionSettingsParams params) async {
    return _repository.openPermissionSettings(params.type);
  }
}
