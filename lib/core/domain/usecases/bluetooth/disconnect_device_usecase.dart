import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class DisconnectDeviceUsecase {
  final BluetoothRepository repository;

  DisconnectDeviceUsecase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.disconnect();
  }
}
