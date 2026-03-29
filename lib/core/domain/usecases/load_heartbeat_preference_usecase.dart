// ABOUTME: This file defines the LoadHeartbeatPreferenceUseCase for retrieving the heartbeat toggle state
// ABOUTME: It follows Clean Architecture by encapsulating the read operation in a single-purpose use case

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';
import '../repositories/heartbeat_repository.dart';

class LoadHeartbeatPreferenceUseCase {
  final HeartbeatRepository repository;

  LoadHeartbeatPreferenceUseCase({required this.repository});

  Future<Either<Failure, bool>> call() {
    return repository.getHeartbeatEnabled();
  }
}
