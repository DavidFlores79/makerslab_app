// ABOUTME: This file contains the UpdateProfile use case
// ABOUTME: It handles updating user profile information (name, email, phone, image)

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository repository;

  UpdateProfile({required this.repository});

  Future<Either<Failure, User>> call({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? image,
  }) {
    return repository.updateProfile(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      image: image,
    );
  }
}
