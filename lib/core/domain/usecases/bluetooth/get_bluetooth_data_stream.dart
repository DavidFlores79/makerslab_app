// get_bluetooth_data_stream.dart
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../repositories/bluetooth_repository.dart';

class GetBluetoothDataStreamUseCase {
  final BluetoothRepository repository;
  GetBluetoothDataStreamUseCase({required this.repository});

  Stream<Either<Failure, Uint8List>> call() {
    return repository.dataStream;
  }
}
