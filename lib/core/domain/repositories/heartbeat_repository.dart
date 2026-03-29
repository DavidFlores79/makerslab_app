// ABOUTME: This file defines the HeartbeatRepository interface for the domain layer
// ABOUTME: It declares contracts for reading and saving the global heartbeat toggle preference

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';

abstract class HeartbeatRepository {
  Future<Either<Failure, bool>> getHeartbeatEnabled();
  Future<Either<Failure, void>> saveHeartbeatEnabled(bool enabled);
}
