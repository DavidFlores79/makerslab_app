import 'package:dartz/dartz.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../../../core/error/failure.dart';

abstract class GamepadRepository {
  /// Descubre dispositivos Bluetooth disponibles.
  Future<Either<Failure, List<fbs.BluetoothDevice>>> discoverDevices();

  /// Conecta al dispositivo por dirección MAC.
  Future<Either<Failure, void>> connectToDevice(String address);

  /// Stream que emite líneas de telemetría o mensajes (texto) provenientes del dispositivo.
  Stream<Either<Failure, String>> telemetryStream();

  /// Envía un comando ya formateado al dispositivo (ej. "B01", "Y00", "S00", etc).
  Future<Either<Failure, void>> sendCommand(String command);

  /// Desconecta del dispositivo actual.
  Future<Either<Failure, void>> disconnect();

  /// Comprueba si hay una conexión activa.
  Future<bool> isConnected();

  /// Libera recursos si aplica.
  void dispose();
}
