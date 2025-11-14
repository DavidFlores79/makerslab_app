import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/domain/usecases/bluetooth/get_bluetooth_data_stream.dart';
import '../../../../core/domain/usecases/bluetooth/send_bluetooth_string.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';

part 'gamepad_event.dart';
part 'gamepad_state.dart';

/// GamepadBloc: encolar eventos de joystick y botones y manejar stream entrante.
class GamepadBloc extends Bloc<GamepadEvent, GamepadState> {
  final GetBluetoothDataStreamUseCase getDataStreamUseCase;
  final SendBluetoothStringUseCase sendStringUseCase;
  final BluetoothBloc bluetoothBloc;

  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSubscription;

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  GamepadBloc({
    required this.getDataStreamUseCase,
    required this.sendStringUseCase,
    required this.bluetoothBloc,
  }) : super(GamepadInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<GamepadDirectionChanged>(_onDirectionChanged);
    on<GamepadButtonPressed>(_onButtonPressed);
    on<GamepadStopRequested>(_onStopRequested);
    on<_GamepadStreamReceived>(_onStreamReceived);
    on<_GamepadStreamFailed>(_onStreamFailed);

    _subscribeToBluetoothState();
  }

  void _subscribeToBluetoothState() {
    // CRITICAL FIX: Check current state first before listening to stream
    // If Bluetooth is already connected when GamepadBloc is created,
    // we need to start monitoring immediately
    final currentState = bluetoothBloc.state;
    if (currentState is BluetoothConnected) {
      add(StartMonitoring());
    }

    // Then listen to future state changes
    _bluetoothStateSubscription = bluetoothBloc.stream.listen((state) {
      if (state is BluetoothConnected) {
        add(StartMonitoring());
      } else if (state is BluetoothDisconnected || state is BluetoothError) {
        add(StopMonitoring());
      }
    });
  }

  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<GamepadState> emit,
  ) async {
    await _cleanup();
    emit(GamepadLoading());

    final stream = getDataStreamUseCase();
    _dataSubscription = stream.listen(
      (either) {
        either.fold((failure) => add(_GamepadStreamFailed(failure.message)), (
          rawData,
        ) {
          _resetTimeout();
          _processRawData(rawData);
        });
      },
      onError: (e) => add(_GamepadStreamFailed(e.toString())),
      onDone: () => add(StopMonitoring()),
    );

    _resetTimeout();
    _startHeartbeat();
    emit(GamepadConnected());
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<GamepadState> emit,
  ) async {
    await _cleanup();
    emit(GamepadDisconnected());
  }

  Future<void> _onDirectionChanged(
    GamepadDirectionChanged event,
    Emitter<GamepadState> emit,
  ) async {
    // Intentamos enviar el comando de dirección inmediatamente.
    if (bluetoothBloc.state is BluetoothConnected &&
        state is GamepadConnected) {
      final command = '${event.command}\n';
      debugPrint('🎮 GamepadBloc: Sending direction command: $command');
      final result = await sendStringUseCase(command);
      result.fold(
        (failure) {
          debugPrint(
            '❌ GamepadBloc: Failed to send command - ${failure.message}',
          );
          emit(GamepadError(failure.message));
        },
        (_) {
          debugPrint('✅ GamepadBloc: Command sent successfully');
          // No emitimos un nuevo estado por cada dirección para evitar rebuilds; si quieres telemetry, úsalo.
        },
      );
    } else {
      debugPrint('❌ GamepadBloc: Not connected - cannot send direction');
      emit(GamepadError('No conectado: imposible enviar dirección.'));
    }
  }

  Future<void> _onButtonPressed(
    GamepadButtonPressed event,
    Emitter<GamepadState> emit,
  ) async {
    if (bluetoothBloc.state is BluetoothConnected &&
        state is GamepadConnected) {
      final command = '\n${event.code}\n';
      final result = await sendStringUseCase(command);
      result.fold((failure) => emit(GamepadError(failure.message)), (_) {
        // Opcional: emitir algún feedback si quieres
      });
    } else {
      emit(GamepadError('No conectado: imposible enviar código de botón.'));
    }
  }

  Future<void> _onStopRequested(
    GamepadStopRequested event,
    Emitter<GamepadState> emit,
  ) async {
    if (bluetoothBloc.state is BluetoothConnected &&
        state is GamepadConnected) {
      final result = await sendStringUseCase('S00\n');
      result.fold((failure) => emit(GamepadError(failure.message)), (_) {});
    }
  }

  Future<void> _onStreamReceived(
    _GamepadStreamReceived event,
    Emitter<GamepadState> emit,
  ) async {
    // Actualiza estado con la última línea de telemetría recibida
    emit(GamepadConnected(lastTelemetryLine: event.line));
  }

  Future<void> _onStreamFailed(
    _GamepadStreamFailed event,
    Emitter<GamepadState> emit,
  ) async {
    emit(GamepadError(event.message));
  }

  // ------------------------
  // Procesamiento del stream
  // ------------------------
  void _processRawData(Uint8List data) {
    try {
      final chunk = utf8.decode(data, allowMalformed: true);

      // Ignorar ACK 'K' si viene solo
      if (chunk.trim() == 'K') return;

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        // Emitir evento interno con la línea parseada
        add(_GamepadStreamReceived(line));
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e) {
      add(_GamepadStreamFailed('Error de parseo: $e'));
    }
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      add(StopMonitoring());
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await sendStringUseCase('P\n');
      result.fold(
        (failure) =>
            add(_GamepadStreamFailed('Heartbeat falló: ${failure.message}')),
        (_) {},
      );
    });
  }

  Future<void> _cleanup() async {
    _heartbeatTimer?.cancel();
    _timeoutTimer?.cancel();
    await _dataSubscription?.cancel();
    _dataBuffer.clear();
    _heartbeatTimer = null;
    _timeoutTimer = null;
    _dataSubscription = null;
  }

  @override
  Future<void> close() {
    _bluetoothStateSubscription?.cancel();
    _cleanup();
    return super.close();
  }
}
