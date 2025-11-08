// lib/features/servo_control/data/repositories/servo_control_repository_impl.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/domain/repositories/bluetooth_repository.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/servo_repository.dart';

class ServoRepositoryImpl implements ServoRepository {
  final BluetoothRepository bluetoothRepository;
  final ILogger logger = LoggerService();

  // StreamController maneja Either<Failure, double> para la posición del servo.
  StreamController<Either<Failure, double>>? _controller;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSub;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  ServoRepositoryImpl({required this.bluetoothRepository}) {
    _setupDataStream();
  }

  // =======================================================================
  // INTERFAZ PÚBLICA
  // =======================================================================

  @override
  Future<Either<Failure, List<fbs.BluetoothDevice>>> discoverDevices() async {
    return bluetoothRepository.discoverDevices();
  }

  @override
  Future<bool> isConnected() async {
    return bluetoothRepository.isConnected;
  }

  @override
  Future<Either<Failure, void>> connectToDevice(String address) async {
    logger.info('[ServoRepo] Conectando al dispositivo: $address');
    await _cleanupPreviousConnection();
    final connectionResult = await bluetoothRepository.connect(address);
    return connectionResult.fold(
      (failure) {
        logger.error('[ServoRepo] Falló la conexión: ${failure.message}');
        return Left(failure);
      },
      (_) {
        logger.info('[ServoRepo] Conexión exitosa. Configurando stream...');
        _setupDataStream();
        // _startHeartbeat();
        _resetTimeout();
        return const Right(null);
      },
    );
  }

  @override
  Stream<Either<Failure, double>> positionStream() {
    if (_controller != null && !_controller!.isClosed) {
      logger.info('[ServoRepo] Escuchando stream de posición del servo...');
      return _controller!.stream;
    }
    logger.warning('[ServoRepo] Intento de escuchar posición sin conexión.');
    return Stream.value(Left(BluetoothFailure('No conectado')));
  }

  @override
  Future<Either<Failure, void>> sendPosition(double angle) async {
    final clamped = angle.clamp(0.0, 180.0);
    final command =
        '${clamped.toInt()}\n'; // Enviamos entero seguido de nueva línea
    logger.info('[ServoRepo] Enviando posición: $command');
    return bluetoothRepository.sendString(command);
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    logger.info('[ServoRepo] Desconectando del dispositivo...');
    await _cleanupPreviousConnection();
    return bluetoothRepository.disconnect();
  }

  @override
  void dispose() {
    _cleanupPreviousConnection();
  }

  // =======================================================================
  // LÓGICA INTERNA: STREAM, PARSEO, HEARTBEAT, TIMEOUT
  // =======================================================================

  void _setupDataStream() {
    _controller = StreamController<Either<Failure, double>>.broadcast();

    _dataSub = bluetoothRepository.dataStream.listen(
      (eitherData) {
        eitherData.fold(
          (failure) {
            _controller?.add(Left(failure));
            _handleDisconnect();
          },
          (rawData) {
            _resetTimeout();
            _processRawData(rawData);
          },
        );
      },
      onError: (error) {
        logger.error('[ServoRepo] Error en el stream de datos: $error');
        _controller?.add(
          Left(BluetoothFailure('Stream de datos falló: $error')),
        );
        _handleDisconnect();
      },
      onDone: () {
        logger.info('[ServoRepo] El stream de datos se cerró (onDone).');
        _handleDisconnect();
      },
    );
  }

  void _processRawData(Uint8List data) {
    try {
      final chunk = utf8.decode(data, allowMalformed: true);
      debugPrint('[ServoRepo] Chunk recibido: "$chunk"');

      // El dispositivo puede enviar 'K' como ACK al heartbeat.
      if (chunk.trim() == 'K') {
        debugPrint('[ServoRepo] ACK de heartbeat recibido.');
        return;
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        debugPrint('[ServoRepo] Línea completa procesada: "$line"');
        final parsed = _parseLine(line);

        if (parsed != null) {
          _controller?.add(Right(parsed));
        } else {
          debugPrint('[ServoRepo] Parseo devolvió null para la línea: "$line"');
        }
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e, st) {
      _controller?.add(Left(UnknownFailure('Error de parseo: $e', st)));
    }
  }

  /// Intenta parsear varias formas comunes:
  /// - "90" o "90.0"
  /// - "POS:90" o "POS=90"
  /// - "ANGLE:90" etc.
  /// Retorna double (0..180) o null si no válido.
  double? _parseLine(String line) {
    final s = line.trim();

    // Ignorar ACKs que vengan mezclados
    if (s == 'K') return null;

    // 1) Intenta parse directo (int o double)
    final intVal = int.tryParse(s);
    if (intVal != null && intVal >= 0 && intVal <= 180) {
      return intVal.toDouble();
    }
    final doubleVal = double.tryParse(s);
    if (doubleVal != null && doubleVal >= 0.0 && doubleVal <= 180.0) {
      return doubleVal;
    }

    // 2) Intenta formatos con separador (ej. "POS:90", "ANGLE=90")
    final regex = RegExp(r'[-]?\d+(\.\d+)?');
    final match = regex.firstMatch(s);
    if (match != null) {
      final found = match.group(0);
      if (found != null) {
        final parsed = double.tryParse(found);
        if (parsed != null && parsed >= 0.0 && parsed <= 180.0) {
          return parsed;
        }
      }
    }

    return null;
  }

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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    logger.info('[ServoRepo] Enviando heartbeat "P"');
    final result = await bluetoothRepository.sendString('P\n');
    result.fold((failure) {
      logger.error(
        '[ServoRepo] Falló el envío del heartbeat: ${failure.message}',
      );
      _handleDisconnect();
    }, (_) => logger.info('[ServoRepo] Heartbeat enviado con éxito.'));
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      logger.warning(
        '[ServoRepo] Timeout: No se recibieron datos en 45 segundos.',
      );
      _handleDisconnect();
    });
  }

  void _handleDisconnect() {
    if (_controller?.isClosed == false) {
      _controller?.add(Left(BluetoothFailure('Conexión perdida')));
    }
    // Asegura limpieza completa y llama al BluetoothRepository.disconnect()
    disconnect();
  }
}
