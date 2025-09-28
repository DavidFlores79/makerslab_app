import 'dart:typed_data';
import 'package:dartz/dartz.dart';

import '../../../error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class GetDataStreamUsecase {
  final BluetoothRepository repository;

  GetDataStreamUsecase(this.repository);

  Stream<Either<Failure, Uint8List>> call() {
    return repository.dataStream;
  }
}
