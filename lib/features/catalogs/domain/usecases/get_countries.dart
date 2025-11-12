// ABOUTME: This file contains the GetCountries use case
// ABOUTME: It fetches the list of countries from the repository

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/country_model.dart';
import '../repositories/catalogs_repository.dart';

class GetCountries {
  final CatalogsRepository repository;

  GetCountries({required this.repository});

  Future<Either<Failure, List<CountryModel>>> call() async {
    return await repository.getCountries();
  }
}
