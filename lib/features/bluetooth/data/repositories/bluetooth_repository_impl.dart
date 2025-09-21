import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/bluetooth_entity.dart';
import '../../domain/repositories/bluetooth_repository.dart';
import '../datasources/bluetooth_local_datasource.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  final BluetoothLocalDatasource localDatasource;

  BluetoothRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<BluetoothEntity>>> getBluetoothData() async {
    try {
      final data = await localDatasource.getBluetoothData(); // CAMBIO AQUÍ: 'data' en lugar de 'bluetooths'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'bluetooths'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}