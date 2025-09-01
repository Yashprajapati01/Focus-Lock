import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../repositories/session_repository.dart';
import '../../../session/core/error/failures.dart';

@lazySingleton
class CancelSession {
  final SessionRepository repository;

  CancelSession(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      // End device lock if active
      await repository.endDeviceLock();

      return const Right(null);
    } catch (e) {
      return Left(SessionFailure('Failed to cancel session: ${e.toString()}'));
    }
  }
}
