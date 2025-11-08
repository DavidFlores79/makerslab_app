import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../error/failure.dart';

typedef BluetoothDeviceEntity = fbs.BluetoothDevice;

abstract class BluetoothRepository {
  Stream<Either<Failure, Uint8List>> get dataStream;
  Future<bool> get isConnected;
  Future<Either<Failure, List<BluetoothDeviceEntity>>> discoverDevices();
  Future<Either<Failure, void>> connect(String address);
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, void>> sendString(String data);
}
