import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/domain/repositories/bluetooth_repository.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/light_control_repository.dart';

class LightControlRepositoryImpl implements LightControlRepository {
  final BluetoothRepository bluetoothRepository;
  final ILogger logger = LoggerService();

  // El StreamController ahora maneja `bool` para el estado del LED.
  StreamController<Either<Failure, bool>>? _controller;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSub;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  LightControlRepositoryImpl({required this.bluetoothRepository}) {
    _setupDataStream();
  }

  // =======================================================================
  // MÉTODOS PÚBLICOS DE LA INTERFAZ
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
    logger.info('[LightControlRepo] Conectando al dispositivo: $address');
    await _cleanupPreviousConnection();
    final connectionResult = await bluetoothRepository.connect(address);
    return connectionResult.fold(
      (failure) {
        logger.error(
          '[LightControlRepo] Falló la conexión: ${failure.message}',
        );
        return Left(failure);
      },
      (_) {
        logger.info(
          '[LightControlRepo] Conexión exitosa. Configurando stream...',
        );
        _setupDataStream();
        // _startHeartbeat();
        _resetTimeout();
        return const Right(null);
      },
    );
  }

  @override
  Stream<Either<Failure, bool>> lightStateStream() {
    if (_controller != null && !_controller!.isClosed) {
      logger.info('[LightControlRepo] Escuchando el estado de la luz...');
      return _controller!.stream;
    }
    // Si no está conectado, devuelve un stream con un error.
    logger.warning(
      '[LightControlRepo] Intento de escuchar el estado de la luz sin conexión.',
    );
    return Stream.value(Left(BluetoothFailure('No conectado')));
  }

  @override
  Future<Either<Failure, void>> toggleLight(bool isCurrentlyOn) async {
    // Si el LED está encendido, enviamos '0' para apagarlo. Si está apagado, enviamos '1'.
    final command = isCurrentlyOn ? '0\n' : '1\n';
    logger.info('[LightControlRepo] Enviando comando: "$command"');
    return bluetoothRepository.sendString(command);
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    logger.info('[LightControlRepo] Desconectando del dispositivo...');
    await _cleanupPreviousConnection();
    return bluetoothRepository.disconnect();
  }

  @override
  void dispose() {
    _cleanupPreviousConnection();
  }

  // =======================================================================
  // LÓGICA INTERNA DE PROCESAMIENTO Y MANEJO DE CONEXIÓN
  // =======================================================================

  void _setupDataStream() {
    _controller = StreamController<Either<Failure, bool>>.broadcast();

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
        logger.error('[LightControlRepo] Error en el stream de datos: $error');
        _controller?.add(
          Left(BluetoothFailure('Stream de datos falló: $error')),
        );
        _handleDisconnect();
      },
      onDone: () {
        logger.info('[LightControlRepo] El stream de datos se cerró (onDone).');
        _handleDisconnect();
      },
    );
  }

  void _processRawData(Uint8List data) {
    try {
      final chunk = utf8.decode(data, allowMalformed: true);
      debugPrint('[LightControlRepo] Chunk recibido: "$chunk"');

      // El dispositivo puede enviar una 'K' como respuesta al heartbeat 'P'.
      if (chunk.trim() == 'K') {
        debugPrint('[LightControlRepo] ACK de heartbeat recibido.');
        return; // No necesita más procesamiento.
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        debugPrint('[LightControlRepo] Línea completa procesada: "$line"');
        final parsed = _parseLine(line);

        if (parsed != null) {
          // Emite el nuevo estado del LED (true o false)
          _controller?.add(Right(parsed));
        } else {
          debugPrint(
            '[LightControlRepo] El parseo devolvió null para la línea: "$line"',
          );
        }
      }
      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e, st) {
      _controller?.add(Left(UnknownFailure('Error de parseo: $e', st)));
    }
  }

  /// Lógica de parseo específica para el estado del LED.
  /// Retorna `true` si la línea es "1", `false` si es "0", y `null` en otro caso.
  bool? _parseLine(String line) {
    final s = line.trim();
    if (s == '1') {
      return true; // LED encendido
    }
    if (s == '0') {
      return false; // LED apagado
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
    logger.info('[LightControlRepo] Enviando heartbeat "P"');
    final result = await bluetoothRepository.sendString('P\n');
    result.fold((failure) {
      logger.error(
        '[LightControlRepo] Falló el envío del heartbeat: ${failure.message}',
      );
      _handleDisconnect();
    }, (_) => logger.info('[LightControlRepo] Heartbeat enviado con éxito.'));
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      logger.warning(
        '[LightControlRepo] Timeout: No se recibieron datos en 45 segundos.',
      );
      _handleDisconnect();
    });
  }

  void _handleDisconnect() {
    if (_controller?.isClosed == false) {
      _controller?.add(Left(BluetoothFailure('Conexión perdida')));
    }
    // Llama a la función pública para asegurar una limpieza completa.
    disconnect();
  }
}
