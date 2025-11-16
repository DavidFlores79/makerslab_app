// ABOUTME: Use case for fetching all module details from datasource
// ABOUTME: Used for preloading or cache warming scenarios

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/module_detail.dart';
import '../repositories/home_repository.dart';

class GetAllModuleDetails {
  final HomeRepository repository;

  GetAllModuleDetails({required this.repository});

  Future<Either<Failure, List<ModuleDetail>>> call() async {
    return await repository.getAllModuleDetails();
  }
}
