import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class ConnectDeviceUseCase {
  final BluetoothRepository repository;
  ConnectDeviceUseCase({required this.repository});

  Future<Either<Failure, void>> call(String address) {
    return repository.connect(address);
  }
}
