// disconnect_device.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class DisconnectDeviceUseCase {
  final BluetoothRepository repository;
  DisconnectDeviceUseCase({required this.repository});

  Future<Either<Failure, void>> call() {
    return repository.disconnect();
  }
}
