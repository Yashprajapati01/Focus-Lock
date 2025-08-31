import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../repositories/permission_repository.dart';

@lazySingleton
class GetAllPermissions extends UsecaseWithoutParams<List<Permission>> {
  const GetAllPermissions(this._repository);

  final PermissionRepository _repository;

  @override
  ResultFuture<List<Permission>> call() async {
    return _repository.getAllPermissionStatuses();
  }
}
