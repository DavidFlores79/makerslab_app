// ABOUTME: This file defines the SaveHeartbeatPreferenceUseCase for persisting the heartbeat toggle state
// ABOUTME: It follows Clean Architecture by encapsulating the write operation in a single-purpose use case

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';
import '../repositories/heartbeat_repository.dart';

class SaveHeartbeatPreferenceUseCase {
  final HeartbeatRepository repository;

  SaveHeartbeatPreferenceUseCase({required this.repository});

  Future<Either<Failure, void>> call(bool enabled) {
    return repository.saveHeartbeatEnabled(enabled);
  }
}
