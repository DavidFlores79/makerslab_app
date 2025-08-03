import 'package:dartz/dartz.dart';

import '../../../../core/entities/balance.dart';
import '../../../../core/error/failure.dart';
import '../repositories/home_repository.dart';

class GetBalance {
  final HomeRepository repository;

  GetBalance({required this.repository});

  Future<Either<Failure, Balance>> call() async {
    return await repository.getBalance();
  }
}
