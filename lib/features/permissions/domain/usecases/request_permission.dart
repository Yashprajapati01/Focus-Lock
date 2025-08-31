import 'package:equatable/equatable.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../repositories/permission_repository.dart';

class RequestPermissionParams extends Equatable {
  const RequestPermissionParams({required this.type});

  final PermissionType type;

  @override
  List<Object> get props => [type];
}

@lazySingleton
class RequestPermission
    extends UsecaseWithParams<Permission, RequestPermissionParams> {
  const RequestPermission(this._repository);

  final PermissionRepository _repository;

  @override
  ResultFuture<Permission> call(RequestPermissionParams params) async {
    return _repository.requestPermission(params.type);
  }
}
