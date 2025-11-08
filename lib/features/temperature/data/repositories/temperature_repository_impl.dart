import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../../../core/domain/repositories/bluetooth_repository.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/repositories/temperature_repository.dart';
import '../datasources/temperature_local_datasource.dart';

class TemperatureRepositoryImpl implements TemperatureRepository {
  final BluetoothRepository bluetoothRepository;
  final TemperatureLocalDataSource local;

  StreamController<Either<Failure, Temperature>>? _controller;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSub;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  TemperatureRepositoryImpl({
    required this.bluetoothRepository,
    required this.local,
  }) {
    _setupDataStream();
    // Constructor
  }

  @override
  Future<Either<Failure, List<fbs.BluetoothDevice>>> discoverDevices() async {
    final devices = await bluetoothRepository.discoverDevices();
    return devices;
  }

  @override
  Future<Either<Failure, void>> connectToDevice(String address) async {
    debugPrint('[TemperatureRepo] Conectando al dispositivo: $address');
    await _cleanupPreviousConnection();
    final connectionResult = await bluetoothRepository.connect(address);
    return connectionResult.fold(
      (failure) {
        debugPrint('[TemperatureRepo] Falló la conexión: ${failure.message}');
        return Left(failure);
      },
      (_) {
        debugPrint(
          '[TemperatureRepo] Conexión exitosa. Configurando stream de datos...',
        );
        _setupDataStream();
        _startHeartbeat();
        _resetTimeout();
        return const Right(null);
      },
    );
  }

  // =======================================================================
  // SUBFUNCIONES (Helpers)
  // =======================================================================

  /// Se suscribe al stream de datos crudos del BluetoothRepository y procesa los datos.
  void _setupDataStream() {
    _controller = StreamController<Either<Failure, Temperature>>.broadcast();

    _dataSub = bluetoothRepository.dataStream.listen(
      (eitherData) {
        // `eitherData` es `Either<Failure, Uint8List>`
        eitherData.fold(
          (failure) {
            // Si el stream de Bluetooth reporta un error, lo propagamos.
            debugPrint(
              '[TemperatureRepo] Error en el stream de datos: ${failure.message}',
            );
            _controller?.add(Left(failure));
            _handleDisconnect();
          },
          (rawData) {
            // Al recibir datos crudos, reiniciamos el timeout.
            _resetTimeout();
            // Procesamos los bytes recibidos para convertirlos en Temperatura.
            _processRawData(rawData);
          },
        );
      },
      onError: (error) {
        debugPrint('[TemperatureRepo] Error fatal en el stream: $error');
        _controller?.add(
          Left(BluetoothFailure('Stream de datos falló: $error')),
        );
        _handleDisconnect();
      },
      onDone: () {
        debugPrint('[TemperatureRepo] El stream de datos se cerró (onDone).');
        _handleDisconnect();
      },
    );
  }

  /// Convierte los bytes crudos en entidades de Temperatura.
  /// Esta es la lógica específica del feature de temperatura.
  void _processRawData(Uint8List data) {
    try {
      final chunk = utf8.decode(data, allowMalformed: true);
      debugPrint('[TemperatureRepo] Chunk recibido: "$chunk"');

      // El dispositivo puede enviar una 'K' como respuesta al heartbeat 'P'.
      if (chunk.trim() == 'K') {
        debugPrint('[TemperatureRepo] ACK de heartbeat recibido.');
        return; // No necesita más procesamiento.
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      // Busca líneas completas (terminadas en '\n').
      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        debugPrint('[TemperatureRepo] Línea completa procesada: "$line"');
        final parsed = _parseLine(line);

        if (parsed != null) {
          // Si el parseo es exitoso:
          // 1. Guarda la última lectura en el caché local.
          local.cacheLastTemperature(parsed);
          // 2. Emite la nueva lectura de temperatura en el stream del repositorio.
          _controller?.add(Right(parsed));
        } else {
          debugPrint(
            '[TemperatureRepo] El parseo devolvió null para la línea: "$line"',
          );
        }
      }

      // Lo que queda en `content` es un fragmento de la siguiente línea.
      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e, st) {
      debugPrint('[TemperatureRepo] Error al procesar datos: $e');
      _controller?.add(Left(UnknownFailure('Error de parseo: $e', st)));
    }
  }

  /// Limpia todos los recursos relacionados con una conexión activa.
  Future<void> _cleanupPreviousConnection() async {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    await _dataSub?.cancel();
    if (_controller?.isClosed == false) {
      await _controller?.close();
    }
    _dataBuffer.clear();

    _heartbeatTimer = null;
    _timeoutTimer = null;
    _dataSub = null;
    _controller = null;
  }

  /// Inicia un temporizador que envía un 'ping' ('P') periódicamente.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendHeartbeat();
    });
  }

  /// Envía el carácter de 'ping' al dispositivo.
  Future<void> _sendHeartbeat() async {
    debugPrint('[TemperatureRepo] Enviando heartbeat "P"');
    final result = await bluetoothRepository.sendString('P\n');
    result.fold((failure) {
      debugPrint(
        '[TemperatureRepo] Falló el envío del heartbeat: ${failure.message}',
      );
      // Si no podemos enviar, la conexión probablemente se perdió.
      _handleDisconnect();
    }, (_) => debugPrint('[TemperatureRepo] Heartbeat enviado con éxito.'));
  }

  /// Reinicia el temporizador de inactividad. Si no se reciben datos
  /// en 45 segundos, se asume que la conexión se perdió.
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      debugPrint(
        '[TemperatureRepo] Timeout: No se recibieron datos en 45 segundos.',
      );
      _handleDisconnect();
    });
  }

  /// Rutina centralizada para gestionar una desconexión inesperada.
  void _handleDisconnect() {
    if (_controller?.isClosed == false) {
      _controller?.add(Left(BluetoothFailure('Conexión perdida')));
    }
    // Llama a la función pública para asegurar una limpieza completa.
    disconnect();
  }

  @override
  Future<bool> isConnected() async {
    return bluetoothRepository.isConnected;
  }

  @override
  Stream<Either<Failure, Temperature>> temperatureStream() {
    if (_controller != null && !_controller!.isClosed) {
      return _controller!.stream;
    }
    return Stream.value(Left(BluetoothFailure('Not connected')));
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    await _dataSub?.cancel();
    final result = await bluetoothRepository.disconnect();
    if (_controller?.isClosed == false) {
      _controller?.close();
      _controller = null;
    }
    return result;
  }

  @override
  Future<Either<Failure, Temperature>> readNow() async {
    try {
      final sendResult = await bluetoothRepository.sendString('R\n');
      return sendResult.fold((failure) => Left(failure), (_) {
        // Después de enviar 'R', la respuesta llegará por el stream.
        // Aquí, solo podemos devolver la última lectura cacheada.
        final cached = local.getLastTemperature();
        if (cached != null) return Right(cached);

        return Left(
          CacheFailure(
            'Comando enviado, pero no hay lectura en caché disponible.',
          ),
        );
      });
    } on CacheException catch (e, st) {
      return Left(CacheFailure(e.message, st));
    }
  }

  Temperature? _parseLine(String line) {
    final s = line.trim();
    final reg = RegExp(r'^t([-+]?\d*\.?\d+)h([-+]?\d*\.?\d+)$');
    final m = reg.firstMatch(s);
    if (m == null) return null;
    final t = double.tryParse(m.group(1)!);
    final h = double.tryParse(m.group(2)!);
    if (t == null || h == null) return null;
    return Temperature(celsius: t, humidity: h);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    _dataSub?.cancel();
    _controller?.close();
  }
}
