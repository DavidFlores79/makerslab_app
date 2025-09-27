import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as btcs;
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/repositories/temperature_repository.dart';
import '../datasources/temperature_local_datasource.dart';

class TemperatureRepositoryImpl implements TemperatureRepository {
  final BluetoothService btService; // tu wrapper, adaptado abajo
  final TemperatureLocalDataSource local;

  String? _connectedDeviceAddress;
  StreamController<Either<Failure, Temperature>>? _controller;
  StreamSubscription<btcs.BluetoothData>?
  _dataSub; // suscripción al stream global del plugin

  TemperatureRepositoryImpl({required this.btService, required this.local});

  @override
  Future<Either<Failure, List<btcs.BluetoothDevice>>> discoverDevices() async {
    try {
      final devices =
          await btService
              .getPairedDevices(); // debe devolver List<btcs.BluetoothDevice>
      // Aquí lo dejamos como Right([]) si no quieres mapearlo a Temperature
      return Right(devices);
    } on btcs.BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    } catch (e, st) {
      return Left(UnknownFailure('Unknown discovery error: $e', st));
    }
  }

  @override
  Future<Either<Failure, void>> connectToDevice(String address) async {
    debugPrint('Connecting to device $address');
    try {
      // Usa la misma instancia que tu BluetoothService expone.
      final bt = btService;
      // (Asume que BluetoothService expone la instancia; si no, usa un getter)

      final connected = await btService.connect(address);
      if (!connected) {
        debugPrint('Failed to connect to device $address');
        return Left(BluetoothFailure('Failed to connect to device $address'));
      }

      debugPrint('Connected to device $address');

      _connectedDeviceAddress = address;

      // Cierra suscripciones anteriores si las hay
      await _dataSub?.cancel();
      _controller?.close();

      _controller = StreamController<Either<Failure, Temperature>>.broadcast();

      // buffer por dispositivo para reconstruir líneas si vienen fragmentadas
      final StringBuffer buffer = StringBuffer();

      _dataSub = bt.onDataReceived
          .where((bd) => bd.deviceAddress == _connectedDeviceAddress)
          .listen(
            (bd) {
              try {
                // bd.data es List<int>
                final bytes = bd.data;
                final chunk = utf8.decode(bytes, allowMalformed: true);
                debugPrint(
                  'Chunk recibido: "$chunk" desde ${bd.deviceAddress}',
                );

                buffer.write(chunk);

                // procesa por líneas (soporta \n y \r\n)
                final content = buffer.toString();
                final lines = content.split(RegExp(r'(\r\n|\n)'));
                // split devuelve partes intercaladas; mejor reconstruir manualmente:
                final newlineIndex = content.lastIndexOf('\n');
                if (newlineIndex == -1) {
                  // aún sin newline completo, esperar más datos
                  return;
                }

                final complete = content.substring(0, newlineIndex + 1);
                final rest = content.substring(newlineIndex + 1);
                // procesa cada línea completa
                for (final line in complete.split(RegExp(r'[\r\n]+'))) {
                  final trimmed = line.trim();
                  if (trimmed.isEmpty) continue;
                  debugPrint('Linea completa procesada: "$trimmed"');
                  final parsed = _parseLine(trimmed);
                  if (parsed != null) {
                    local.cacheLastTemperature(parsed);
                    _controller!.add(Right(parsed));
                  } else {
                    debugPrint('Parse devolvió null para: $trimmed');
                  }
                }
                // deja en buffer lo que quedó después del último newline
                buffer.clear();
                buffer.write(rest);
              } catch (e, st) {
                debugPrint('Error al procesar data: $e');
                _controller!.add(Left(UnknownFailure('Parse error: $e', st)));
              }
            },
            onError: (e) {
              debugPrint('Data stream error: $e');
              _controller!.add(Left(BluetoothFailure('Data stream error: $e')));
            },
            onDone: () {
              debugPrint('Data stream done');
              _controller!.close();
            },
          );

      debugPrint('Returning from connectToDevice');
      return const Right(null);
    } on btcs.BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    } catch (e, st) {
      return Left(UnknownFailure('Connection error: $e', st));
    }
  }

  @override
  Stream<Either<Failure, Temperature>> temperatureStream() {
    if (_controller != null) return _controller!.stream;
    final controller = StreamController<Either<Failure, Temperature>>();
    controller.add(Left(BluetoothFailure('Not connected')));
    controller.close();
    return controller.stream;
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _dataSub?.cancel();
      // usa el wrapper para desconectar (el plugin ofrece disconnect() sin args)
      final disconnected = await btService.disconnect();
      _connectedDeviceAddress = null;
      _controller?.close();
      if (!disconnected) {
        // no fatal, pero reportamos
        return Left(BluetoothFailure('Disconnect reported failure'));
      }
      return const Right(null);
    } on btcs.BluetoothException catch (e, st) {
      return Left(BluetoothFailure(e.message, st));
    } catch (e, st) {
      return Left(UnknownFailure('Disconnect error: $e', st));
    }
  }

  @override
  Future<Either<Failure, Temperature>> readNow() async {
    try {
      if (_connectedDeviceAddress == null)
        return Left(BluetoothFailure('Not connected'));
      // Si el firmware soporta petición, envía comando:
      // tu BluetoothService debería exponer sendString(address?, message) o sendToConnected(message)
      final writeOk = await btService.sendString(
        'R\n',
      ); // implementa esto en tu BluetoothService
      if (!writeOk)
        return Left(BluetoothFailure('Failed to send read command'));
      // Espera next reading from stream; aquí, como simplificación, devolvemos cached si existe
      final cached = local.getLastTemperature();
      if (cached != null) return Right(cached);
      return Left(
        BluetoothFailure('No cached reading and no immediate response'),
      );
    } on CacheException catch (e, st) {
      return Left(CacheFailure(e.message, st));
    } catch (e, st) {
      return Left(UnknownFailure('ReadNow error: $e', st));
    }
  }

  // Parser privado (igual)
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
}
