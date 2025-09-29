import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class DiscoverDevicesUseCase {
  final BluetoothRepository repository;
  DiscoverDevicesUseCase({required this.repository});

  Future<Either<Failure, List<BluetoothDeviceEntity>>> call() {
    return repository.discoverDevices();
  }
}
