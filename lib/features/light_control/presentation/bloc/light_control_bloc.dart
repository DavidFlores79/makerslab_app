// lib/features/light_control/presentation/bloc/light_control_bloc.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/usecases/bluetooth/get_bluetooth_data_stream.dart';
import '../../../../core/domain/usecases/bluetooth/send_bluetooth_string.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';

part 'light_control_event.dart';
part 'light_control_state.dart';

class LightControlBloc extends Bloc<LightControlEvent, LightControlState> {
  final GetBluetoothDataStreamUseCase getDataStreamUseCase;
  final SendBluetoothStringUseCase sendStringUseCase;
  final BluetoothBloc bluetoothBloc;
  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSubscription;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();

  LightControlBloc({
    required this.getDataStreamUseCase,
    required this.sendStringUseCase,
    required this.bluetoothBloc,
  }) : super(LightControlInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<LightControlToggleRequested>(_onToggleRequested);
    on<_LightStatusUpdated>(_onLightStatusUpdated);
    on<_LightStreamFailed>(_onLightStreamFailed);
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
    Emitter<LightControlState> emit,
  ) async {
    await _cleanup();
    emit(LightControlLoading());

    final stream = getDataStreamUseCase();
    _dataSubscription = stream.listen(
      (either) {
        either.fold((failure) => add(_LightStreamFailed(failure.message)), (
          rawData,
        ) {
          _resetTimeout();
          _processRawData(rawData);
        });
      },
      onError: (e) => add(_LightStreamFailed(e.toString())),
      onDone: () => add(StopMonitoring()),
    );

    _startHeartbeat();
    _resetTimeout();
    // Inicia con el LED apagado por defecto
    emit(LightControlConnected(isLightOn: false));
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<LightControlState> emit,
  ) async {
    await _cleanup();
    emit(LightControlDisconnected());
  }

  Future<void> _onLightStatusUpdated(
    _LightStatusUpdated event,
    Emitter<LightControlState> emit,
  ) async {
    emit(LightControlConnected(isLightOn: event.isLightOn));
  }

  Future<void> _onLightStreamFailed(
    _LightStreamFailed event,
    Emitter<LightControlState> emit,
  ) async {
    emit(LightControlError(event.message));
  }

  Future<void> _onToggleRequested(
    LightControlToggleRequested event,
    Emitter<LightControlState> emit,
  ) async {
    if (bluetoothBloc.state is BluetoothConnected &&
        state is LightControlConnected) {
      final currentState = state as LightControlConnected;
      final newStatus = !currentState.isLightOn;
      final command =
          newStatus ? '1\n' : '0\n'; // Comando para encender o apagar

      final result = await sendStringUseCase(command);
      result.fold((failure) => emit(LightControlError(failure.message)), (_) {
        // Actualización optimista: actualiza la UI inmediatamente
        emit(LightControlConnected(isLightOn: newStatus));
      });
    } else {
      emit(
        LightControlError(
          "No se puede cambiar el estado: Dispositivo no conectado.",
        ),
      );
    }
  }

  void _processRawData(Uint8List data) {
    try {
      final chunk = String.fromCharCodes(data);
      if (chunk.trim() == 'K') {
        return; // ACK del heartbeat, no hacer nada.
      }

      _dataBuffer.write(chunk);
      String content = _dataBuffer.toString();

      while (content.contains('\n')) {
        final newlineIndex = content.indexOf('\n');
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) continue;

        final parsedStatus = _parseLine(line);
        if (parsedStatus != null) {
          add(_LightStatusUpdated(parsedStatus));
        }
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e) {
      add(_LightStreamFailed('Error de parseo: $e'));
    }
  }

  /// Parsea la línea de entrada buscando '1' o '0'.
  /// Retorna `true` para '1', `false` para '0', y `null` para cualquier otra cosa.
  bool? _parseLine(String line) {
    final s = line.trim();
    if (s == '1') {
      return true;
    }
    if (s == '0') {
      return false;
    }
    return null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Envía un 'ping' ('P\n') para mantener la conexión activa.
      final result = await sendStringUseCase('P\n');
      result.fold(
        (failure) =>
            add(_LightStreamFailed('Heartbeat falló: ${failure.message}')),
        (_) {},
      );
    });
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      // Si no se reciben datos en 45 segundos, asume desconexión.
      add(StopMonitoring());
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
