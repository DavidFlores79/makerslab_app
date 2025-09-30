import 'package:dartz/dartz.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as btcs;
import '../../../../core/error/failure.dart';

abstract class LightControlRepository {
  /// Descubre dispositivos Bluetooth disponibles. (Genérico)
  Future<Either<Failure, List<btcs.BluetoothDevice>>> discoverDevices();

  /// Se conecta a un dispositivo por su dirección. (Genérico)
  Future<Either<Failure, void>> connectToDevice(String address);

  /// Devuelve un stream que emite el estado del LED (`true` para encendido, `false` para apagado).
  Stream<Either<Failure, bool>> lightStateStream();

  /// Envía un comando para cambiar el estado del LED.
  Future<Either<Failure, void>> toggleLight(bool isCurrentlyOn);

  /// Se desconecta del dispositivo actual. (Genérico)
  Future<Either<Failure, void>> disconnect();

  /// Comprueba si hay una conexión activa. (Genérico)
  Future<bool> isConnected();

  /// Libera los recursos del repositorio. (Genérico)
  void dispose();
}
