// send_bluetooth_string.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class SendBluetoothStringUseCase {
  final BluetoothRepository repository;
  SendBluetoothStringUseCase({required this.repository});

  Future<Either<Failure, void>> call(String data) {
    return repository.sendString(data);
  }
}
