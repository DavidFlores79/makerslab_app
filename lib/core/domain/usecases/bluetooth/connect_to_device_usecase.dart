//example
// class GetTemperatureStreamUsecase {
//   final TemperatureRepository repository;
//   GetTemperatureStreamUsecase({required this.repository});

//   Stream<Either<Failure, Temperature>> call() {
//     return repository.temperatureStream();
//   }
// }

import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class ConnectToDeviceUsecase {
  final BluetoothRepository repository;

  ConnectToDeviceUsecase({required this.repository});

  Future<Either<Failure, void>> call(String address) {
    return repository.connect(address);
  }
}
