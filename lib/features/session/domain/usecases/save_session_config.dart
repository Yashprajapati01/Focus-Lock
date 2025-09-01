import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/session_config.dart';
import '../repositories/session_repository.dart';
import '../../../session/core/error/failures.dart';

@lazySingleton
class SaveSessionConfig {
  final SessionRepository repository;

  SaveSessionConfig(this.repository);

  Future<Either<Failure, void>> call(SessionConfig config) async {
    try {
      await repository.saveSessionConfig(config);
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Failed to save session config: ${e.toString()}'),
      );
    }
  }
}
