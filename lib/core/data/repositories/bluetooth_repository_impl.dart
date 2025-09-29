// lib/core/bluetooth/data/repositories/bluetooth_repository_impl.dart
import 'dart:typed_data';
import 'package:dartz/dartz.dart';

import '../../domain/repositories/bluetooth_repository.dart';
import '../../error/exceptions.dart';
import '../../error/failure.dart';
import '../services/bluetooth_service.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  final BluetoothService btService;

  BluetoothRepositoryImpl({required this.btService});

  @override
  Stream<Either<Failure, Uint8List>> get dataStream {
    if (btService.onDataReceived == null) {
      return Stream.error(
        BluetoothFailure('Not connected or stream unavailable.'),
      );
    }
    return btService.onDataReceived!
        .map((data) => Right<Failure, Uint8List>(data))
        .handleError(
          (e, st) => Left<Failure, Uint8List>(
            BluetoothFailure('Data stream error: $e', st),
          ),
        );
  }

  @override
  Future<bool> get isConnected => Future.value(btService.isConnected);

  @override
  Future<Either<Failure, List<BluetoothDeviceEntity>>> discoverDevices() async {
    try {
      final devices =
          await btService
              .discoverDevices(); // Cambié a discoverDevices; ajusta si es getPairedDevices
      return Right(devices);
    } on BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    }
  }

  @override
  Future<Either<Failure, void>> connect(String address) async {
    try {
      await btService.connect(address);
      return const Right(null);
    } on BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await btService.disconnect();
      return const Right(null);
    } on BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    }
  }

  @override
  Future<Either<Failure, void>> sendString(String data) async {
    try {
      await btService.sendString(data);
      return const Right(null);
    } on BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    }
  }
}
