import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/bluetooth_entity.dart';
import '../repositories/bluetooth_repository.dart';

class GetBluetoothDataUseCase {
  final BluetoothRepository repository;

  GetBluetoothDataUseCase(this.repository);

  Future<Either<Failure, List<BluetoothEntity>>> call() async {
    return await repository.getBluetoothData();
  }
}