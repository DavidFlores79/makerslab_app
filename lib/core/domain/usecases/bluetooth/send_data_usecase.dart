import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class SendDataUsecase {
  final BluetoothRepository repository;

  SendDataUsecase(this.repository);

  Future<Either<Failure, void>> call(String string) {
    return repository.sendString(string);
  }
}
