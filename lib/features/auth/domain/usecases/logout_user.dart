// domain/usecases/logout_user.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class LogoutUser {
  final AuthRepository repository;

  LogoutUser({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.logout();
  }
}
