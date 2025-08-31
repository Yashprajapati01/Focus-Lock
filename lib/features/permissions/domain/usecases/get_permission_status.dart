import 'package:equatable/equatable.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../repositories/permission_repository.dart';

class GetPermissionStatusParams extends Equatable {
  const GetPermissionStatusParams({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}

@lazySingleton
class GetPermissionStatus
    extends UsecaseWithParams<Permission, GetPermissionStatusParams> {
  const GetPermissionStatus(this._repository);

  final PermissionRepository _repository;

  @override
  ResultFuture<Permission> call(GetPermissionStatusParams params) async {
    return _repository.getPermissionStatus(params.type);
  }
}
