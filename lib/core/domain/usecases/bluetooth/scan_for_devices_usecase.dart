import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class ScanForDevicesUsecase {
  final BluetoothRepository repository;

  ScanForDevicesUsecase(this.repository);

  Future<Either<Failure, List<BluetoothDeviceEntity>>> call() {
    return repository.discoverDevices();
  }
}
