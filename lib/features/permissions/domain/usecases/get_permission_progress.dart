import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../repositories/permission_repository.dart';

@lazySingleton
class GetPermissionProgress extends UsecaseWithoutParams<PermissionProgress> {
  const GetPermissionProgress(this._repository);

  final PermissionRepository _repository;

  @override
  ResultFuture<PermissionProgress> call() async {
    return _repository.getPermissionProgress();
  }
}
