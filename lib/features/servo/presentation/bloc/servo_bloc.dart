import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/domain/usecases/bluetooth/get_bluetooth_data_stream.dart';
import '../../../../core/domain/usecases/bluetooth/send_bluetooth_string.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';

part 'servo_event.dart';
part 'servo_state.dart';

class ServoBloc extends Bloc<ServoEvent, ServoState> {
  final GetBluetoothDataStreamUseCase getDataStreamUseCase;
  final SendBluetoothStringUseCase sendStringUseCase;
  final BluetoothBloc bluetoothBloc;

  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSubscription;

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  ServoBloc({
    required this.getDataStreamUseCase,
    required this.sendStringUseCase,
    required this.bluetoothBloc,
  }) : super(ServoInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<ServoPositionRequested>(_onPositionRequested);
    on<ServoPositionPreviewRequested>(_onPositionPreviewRequested);
    on<_ServoPositionUpdated>(_onPositionUpdated);
    on<_ServoStreamFailed>(_onStreamFailed);

    _subscribeToBluetoothState();
  }

  void _subscribeToBluetoothState() {
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
    Emitter<ServoState> emit,
  ) async {
    await _cleanup();
    emit(ServoLoading());

    final stream = getDataStreamUseCase();
    _dataSubscription = stream.listen(
      (either) {
        either.fold((failure) => add(_ServoStreamFailed(failure.message)), (
          rawData,
        ) {
          _resetTimeout();
          _processRawData(rawData);
        });
      },
      onError: (e) => add(_ServoStreamFailed(e.toString())),
      onDone: () => add(StopMonitoring()),
    );

    _startHeartbeat();
    _resetTimeout();
    // Inicia con posición 0 por defecto (puedes cambiarlo).
    emit(ServoConnected(position: 0));
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<ServoState> emit,
  ) async {
    await _cleanup();
    emit(ServoDisconnected());
  }

  /// Enviar la posición final (evento disparado por el usuario).
  Future<void> _onPositionRequested(
    ServoPositionRequested event,
    Emitter<ServoState> emit,
  ) async {
    if (bluetoothBloc.state is BluetoothConnected && state is ServoConnected) {
      final clamped = event.angle.clamp(0.0, 180.0);
      final command = '${clamped.toInt()}\n';
      final result = await sendStringUseCase(command);

      result.fold((failure) => emit(ServoError(failure.message)), (_) {
        // Optimistic update: mostramos la nueva posición inmediatamente.
        emit(ServoConnected(position: clamped));
      });
    } else {
      emit(ServoError('No se puede enviar: dispositivo no conectado.'));
    }
  }

  /// Mientras se desliza (preview). Aquí enviamos un preview y actualizamos estado
  /// para reflejar la posición en la UI si así lo deseas.
  Future<void> _onPositionPreviewRequested(
    ServoPositionPreviewRequested event,
    Emitter<ServoState> emit,
  ) async {
    if (bluetoothBloc.state is BluetoothConnected && state is ServoConnected) {
      final clamped = event.angle.clamp(0.0, 180.0);
      final command = '${clamped.toInt()}\n';
      // Intentamos enviar el preview, pero no forzamos error si falla; igual actualizamos la UI.
      final result = await sendStringUseCase(command);
      result.fold(
        (failure) {
          // Solo reportamos el fallo si quieres; por ahora lo emitimos para que la UI lo muestre.
          emit(ServoError(failure.message));
        },
        (_) {
          emit(ServoConnected(position: clamped));
        },
      );
    } else {
      // Si no está conectado, no hacemos nada o podemos emitir error silencioso.
      // emit(ServoError('No conectado para preview'));
    }
  }

  Future<void> _onPositionUpdated(
    _ServoPositionUpdated event,
    Emitter<ServoState> emit,
  ) async {
    emit(ServoConnected(position: event.angle));
  }

  Future<void> _onStreamFailed(
    _ServoStreamFailed event,
    Emitter<ServoState> emit,
  ) async {
    emit(ServoError(event.message));
  }

  // ------------------------
  // Procesamiento del stream
  // ------------------------
  void _processRawData(Uint8List data) {
    try {
      final chunk = String.fromCharCodes(data);
      if (chunk.trim() == 'K') {
        // ACK del heartbeat, ignorar
        return;
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        final parsed = _parseLine(line);
        if (parsed != null) {
          add(_ServoPositionUpdated(parsed));
        }
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e) {
      add(_ServoStreamFailed('Error de parseo: $e'));
    }
  }

  /// Intenta parsear una línea buscando un entero 0..180 o un float.
  /// Retorna null si no es válido.
  double? _parseLine(String line) {
    final s = line.trim();
    // Intentar parse int o double
    final intVal = int.tryParse(s);
    if (intVal != null) {
      if (intVal >= 0 && intVal <= 180) return intVal.toDouble();
      return null;
    }
    final doubleVal = double.tryParse(s);
    if (doubleVal != null) {
      if (doubleVal >= 0.0 && doubleVal <= 180.0) return doubleVal;
    }
    return null;
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      // Si no se reciben datos en 45 segundos, asumimos desconexión.
      add(StopMonitoring());
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await sendStringUseCase('P\n');
      result.fold(
        (failure) =>
            add(_ServoStreamFailed('Heartbeat falló: ${failure.message}')),
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
