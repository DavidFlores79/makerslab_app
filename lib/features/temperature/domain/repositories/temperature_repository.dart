import 'package:dartz/dartz.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as btcs;
import '../../../../core/error/failure.dart';
import '../entities/temperature_entity.dart';

abstract class TemperatureRepository {
  Future<Either<Failure, List<btcs.BluetoothDevice>>> discoverDevices();
  Future<Either<Failure, void>> connectToDevice(String address);
  Stream<Either<Failure, Temperature>> temperatureStream();
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, Temperature>> readNow();
}
