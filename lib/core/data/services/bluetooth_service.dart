import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:makerslab_app/core/data/services/logger_service.dart';
import '../../error/exceptions.dart';

class BluetoothService {
  BluetoothConnection? _connection;
  final FlutterBluetoothSerial _bluetoothSerial =
      FlutterBluetoothSerial.instance;
  final ILogger logger = LoggerService();

  Stream<BluetoothDiscoveryResult>? _discoveryStream;

  // Propiedad para verificar si la conexión está activa.
  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Devuelve la lista de dispositivos Bluetooth previamente emparejados.
  Future<List<BluetoothDevice>> discoverDevices() async {
    try {
      logger.info('Discovering devices...');
      return await _bluetoothSerial.getBondedDevices();
    } catch (e, st) {
      logger.error('getPairedDevices failed: $e', e, st);
      throw BluetoothException('getPairedDevices failed: $e', st);
    }
  }

  /// Inicia el descubrimiento de dispositivos cercanos.
  /// Devuelve un Stream con los resultados de los dispositivos encontrados.
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    try {
      logger.info('Starting discovery...');
      _discoveryStream = _bluetoothSerial.startDiscovery();
      return _discoveryStream!;
    } catch (e, st) {
      logger.error('startDiscovery failed: $e', e, st);
      throw BluetoothException('startDiscovery failed: $e', st);
    }
  }

  /// Detiene el proceso de descubrimiento si está activo.
  void stopDiscovery() {
    logger.info('Stopping discovery...');
    if (_discoveryStream != null) {
      _discoveryStream = null;
    }
    _bluetoothSerial.cancelDiscovery();
  }

  /// Intenta establecer una conexión con un dispositivo a través de su dirección.
  Future<void> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      logger.info('Connected to device **** $address');
    } catch (e, st) {
      _connection = null;
      logger.error('connect failed: $e', e, st);
      throw BluetoothException('connect failed: $e', st);
    }
  }

  /// Cierra la conexión Bluetooth actual.
  Future<void> disconnect() async {
    try {
      if (_connection != null && _connection!.isConnected) {
        logger.info('Disconnecting from device...');
        await _connection!.close();
        _connection = null;
      }
    } catch (e, st) {
      logger.error('disconnect failed: $e', e, st);
      throw BluetoothException('disconnect failed: $e', st);
    }
  }

  /// Envía un string de datos al dispositivo conectado.
  Future<void> sendString(String msg) async {
    if (!isConnected) {
      logger.error(
        'sendString/write failed: Not connected',
        null,
        StackTrace.current,
      );
      throw BluetoothException(
        'sendString/write failed: Not connected',
        StackTrace.current,
      );
    }
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(msg)));
      logger.info('sendString/write succeeded: $msg');
      await _connection!
          .output
          .allSent; // Espera a que se envíen todos los datos.
    } catch (e, st) {
      logger.error('sendString failed: $e', e, st);
      throw BluetoothException('sendString failed: $e', st);
    }
  }

  /// Stream para escuchar los datos recibidos del dispositivo.
  Stream<Uint8List>? get onDataReceived {
    if (_connection != null) {
      logger.info('Listening for data...');
      return _connection!.input;
    }
    return null;
  }
}
