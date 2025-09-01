import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/session_config.dart';
import '../repositories/session_repository.dart';
import '../../../session/core/error/failures.dart';

@lazySingleton
class LoadSessionConfig {
  final SessionRepository repository;

  LoadSessionConfig(this.repository);

  Future<Either<Failure, SessionConfig>> call() async {
    try {
      final config = await repository.loadSessionConfig();
      return Right(config);
    } catch (e) {
      return Left(
        CacheFailure('Failed to load session config: ${e.toString()}'),
      );
    }
  }
}
