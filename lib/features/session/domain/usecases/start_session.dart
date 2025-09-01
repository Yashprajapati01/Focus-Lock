import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/session_config.dart';
import '../repositories/session_repository.dart';
import '../../../session/core/error/failures.dart';

@lazySingleton
class StartSession {
  final SessionRepository repository;

  StartSession(this.repository);

  Future<Either<Failure, void>> call(SessionConfig config) async {
    try {
      // Check permissions before starting session
      final hasPermissions = await repository.hasRequiredPermissions();
      if (!hasPermissions) {
        return Left(PermissionFailure('Required permissions not granted'));
      }

      // Save the configuration
      await repository.saveSessionConfig(config);

      // Start device lock with duration
      await repository.startDeviceLockWithDuration(config.duration);

      return const Right(null);
    } catch (e) {
      return Left(SessionFailure('Failed to start session: ${e.toString()}'));
    }
  }
}
