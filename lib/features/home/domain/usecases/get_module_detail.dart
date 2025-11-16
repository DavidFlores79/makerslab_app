// ABOUTME: Use case for fetching a single module detail by ID
// ABOUTME: Returns Either with Failure or ModuleDetail entity

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/module_detail.dart';
import '../repositories/home_repository.dart';

class GetModuleDetail {
  final HomeRepository repository;

  GetModuleDetail({required this.repository});

  Future<Either<Failure, ModuleDetail>> call(String moduleId) async {
    return await repository.getModuleDetailById(moduleId);
  }
}
