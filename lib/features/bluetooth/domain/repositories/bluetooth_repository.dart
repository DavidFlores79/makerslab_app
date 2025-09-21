import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/bluetooth_entity.dart';

abstract class BluetoothRepository {
  Future<Either<Failure, List<BluetoothEntity>>> getBluetoothData();
}