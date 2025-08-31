import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SkipAuthentication extends UsecaseWithoutParams<User> {
  const SkipAuthentication(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<User> call() async {
    return _repository.skipAuthentication();
  }
}
