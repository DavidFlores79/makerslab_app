import 'package:dartz/dartz.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as btcs;

import '../../../../core/error/failure.dart';

abstract class ServoRepository {
  /// Descubre dispositivos Bluetooth disponibles.
  Future<Either<Failure, List<btcs.BluetoothDevice>>> discoverDevices();

  /// Conecta al dispositivo por dirección MAC.
  Future<Either<Failure, void>> connectToDevice(String address);

  /// Stream que emite la posición actual del servo (ángulo 0..180).
  /// El stream debe emitir Either<Failure,double> para permitir propagar errores.
  Stream<Either<Failure, double>> positionStream();

  /// Envía una posición (ángulo 0..180) al servo.
  Future<Either<Failure, void>> sendPosition(double angle);

  /// Desconecta del dispositivo actual.
  Future<Either<Failure, void>> disconnect();

  /// Comprueba si hay una conexión activa.
  Future<bool> isConnected();

  /// Libera recursos si aplica.
  void dispose();
}
