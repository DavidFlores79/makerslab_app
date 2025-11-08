import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/user.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class GetUserFromCache {
  final AuthRepository repository;

  GetUserFromCache({required this.repository});

  Future<Either<Failure, User>> call() {
    return repository.getUserFromCache();
  }
}
