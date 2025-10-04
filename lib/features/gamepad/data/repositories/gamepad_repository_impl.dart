import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/domain/repositories/bluetooth_repository.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/gamepad_repository.dart';

class GamepadRepositoryImpl implements GamepadRepository {
  final BluetoothRepository bluetoothRepository;
  final ILogger logger = LoggerService();

  // StreamController que emite Either<Failure, String> con líneas de telemetría.
  StreamController<Either<Failure, String>>? _controller;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSub;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  GamepadRepositoryImpl({required this.bluetoothRepository}) {
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
    logger.info('[GamepadRepo] Conectando al dispositivo: $address');
    await _cleanupPreviousConnection();
    final connectionResult = await bluetoothRepository.connect(address);
    return connectionResult.fold(
      (failure) {
        logger.error('[GamepadRepo] Falló la conexión: ${failure.message}');
        return Left(failure);
      },
      (_) {
        logger.info('[GamepadRepo] Conexión exitosa. Configurando stream...');
        _setupDataStream();
        // _startHeartbeat(); // descomenta si quieres heartbeat
        _resetTimeout();
        return const Right(null);
      },
    );
  }

  @override
  Stream<Either<Failure, String>> telemetryStream() {
    if (_controller != null && !_controller!.isClosed) {
      logger.info('[GamepadRepo] Escuchando stream de telemetría...');
      return _controller!.stream;
    }
    logger.warning(
      '[GamepadRepo] Intento de escuchar telemetría sin conexión.',
    );
    return Stream.value(Left(BluetoothFailure('No conectado')));
  }

  @override
  Future<Either<Failure, void>> sendCommand(String command) async {
    final formatted = command.endsWith('\n') ? command : '$command\n';
    logger.info('[GamepadRepo] Enviando comando: "$formatted"');
    final result = await bluetoothRepository.sendString(formatted);
    return result;
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    logger.info('[GamepadRepo] Desconectando del dispositivo...');
    await _cleanupPreviousConnection();
    return bluetoothRepository.disconnect();
  }

  @override
  void dispose() {
    _cleanupPreviousConnection();
  }

  // =======================================================================
  // LÓGICA INTERNA: SETUP STREAM, PARSEO, HEARTBEAT, TIMEOUT, CLEANUP
  // =======================================================================
  void _setupDataStream() {
    _controller = StreamController<Either<Failure, String>>.broadcast();

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
        logger.error('[GamepadRepo] Error en el stream de datos: $error');
        _controller?.add(
          Left(BluetoothFailure('Stream de datos falló: $error')),
        );
        _handleDisconnect();
      },
      onDone: () {
        logger.info('[GamepadRepo] El stream de datos se cerró (onDone).');
        _handleDisconnect();
      },
    );
  }

  void _processRawData(Uint8List data) {
    try {
      final chunk = utf8.decode(data, allowMalformed: true);
      debugPrint('[GamepadRepo] Chunk recibido: "$chunk"');

      // Ignorar ACK simple 'K' si viene solo
      if (chunk.trim() == 'K') {
        debugPrint('[GamepadRepo] ACK de heartbeat recibido.');
        return;
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        debugPrint('[GamepadRepo] Línea telemetría procesada: "$line"');
        // Emitimos la línea como Right(String)
        _controller?.add(Right(line));
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e, st) {
      _controller?.add(Left(UnknownFailure('Error de parseo: $e', st)));
    }
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
    logger.info('[GamepadRepo] Enviando heartbeat "P"');
    final result = await bluetoothRepository.sendString('P\n');
    result.fold((failure) {
      logger.error(
        '[GamepadRepo] Falló el envío del heartbeat: ${failure.message}',
      );
      _handleDisconnect();
    }, (_) => logger.info('[GamepadRepo] Heartbeat enviado con éxito.'));
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      logger.warning(
        '[GamepadRepo] Timeout: No se recibieron datos en 45 segundos.',
      );
      _handleDisconnect();
    });
  }

  void _handleDisconnect() {
    if (_controller?.isClosed == false) {
      _controller?.add(Left(BluetoothFailure('Conexión perdida')));
    }
    // Asegura limpieza completa y desconexión del BluetoothRepository
    disconnect();
  }
}
