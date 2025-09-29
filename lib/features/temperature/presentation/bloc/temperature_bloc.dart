import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/usecases/bluetooth/get_bluetooth_data_stream.dart';
import '../../../../core/domain/usecases/bluetooth/send_bluetooth_string.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../data/datasources/temperature_local_datasource.dart';
import '../../domain/entities/temperature_entity.dart';
import 'temperature_event.dart';
import 'temperature_state.dart';

class TemperatureBloc extends Bloc<TemperatureEvent, TemperatureState> {
  final GetBluetoothDataStreamUseCase getDataStreamUseCase;
  final SendBluetoothStringUseCase sendStringUseCase;
  final TemperatureLocalDataSource localDataSource; // Agrega para cache
  final BluetoothBloc bluetoothBloc;
  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription<Either<Failure, Uint8List>>? _dataSubscription;
  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;
  final StringBuffer _dataBuffer = StringBuffer();
  final List<Temperature> _history = [];

  TemperatureBloc({
    required this.getDataStreamUseCase,
    required this.sendStringUseCase,
    required this.localDataSource,
    required this.bluetoothBloc,
  }) : super(TempInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<ReadNow>(_onReadNow);
    on<TemperatureDataReceived>(_onTemperatureDataReceived);
    on<TemperatureStreamFailed>(_onTemperatureStreamFailed);
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
    Emitter<TemperatureState> emit,
  ) async {
    await _cleanup();
    emit(TempLoading());

    final stream = getDataStreamUseCase();
    _dataSubscription = stream.listen(
      (either) {
        either.fold(
          (failure) => add(TemperatureStreamFailed(failure.message)),
          (rawData) {
            _resetTimeout();
            _processRawData(rawData);
          },
        );
      },
      onError: (e) => add(TemperatureStreamFailed(e.toString())),
      // onDone: () => emit(TempDisconnected()),
      onDone: () => add(StopMonitoring()),
    );

    _startHeartbeat();
    _resetTimeout();
    emit(
      TempConnected(
        latest: Temperature(celsius: 0, humidity: 0),
        history: List.from(_history),
      ),
    );
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<TemperatureState> emit,
  ) async {
    await _cleanup();
    _history.clear();
    emit(TempDisconnected());
  }

  Future<void> _onTemperatureDataReceived(
    TemperatureDataReceived event,
    Emitter<TemperatureState> emit,
  ) async {
    localDataSource.cacheLastTemperature(event.temperature); // Cachea
    _history.add(event.temperature);
    if (_history.length > 10) _history.removeAt(0);
    emit(
      TempConnected(latest: event.temperature, history: List.from(_history)),
    );
  }

  Future<void> _onTemperatureStreamFailed(
    TemperatureStreamFailed event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TempError(event.message));
  }

  Future<void> _onReadNow(ReadNow event, Emitter<TemperatureState> emit) async {
    if (bluetoothBloc.state is BluetoothConnected) {
      final result = await sendStringUseCase('R\n');
      result.fold((failure) => emit(TempError(failure.message)), (_) {
        // Respuesta via stream; retorna cached si no
        final cached = localDataSource.getLastTemperature();
        if (cached != null) {
          add(TemperatureDataReceived(cached));
        } else {
          emit(TempError('Comando enviado, pero no hay lectura en caché.'));
        }
      });
    } else {
      emit(TempError("No se puede leer: Dispositivo no conectado."));
    }
  }

  // Lógica movida de repository: Procesamiento raw
  void _processRawData(Uint8List data) {
    try {
      final chunk = String.fromCharCodes(data);
      if (chunk.trim() == 'K') {
        return; // ACK heartbeat
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
          add(TemperatureDataReceived(parsed));
        }
      }

      _dataBuffer.clear();
      _dataBuffer.write(content);
    } catch (e) {
      add(TemperatureStreamFailed('Error de parseo: $e'));
    }
  }

  // Parseo específico (de tu repo)
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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await sendStringUseCase('P\n');
      result.fold(
        (failure) =>
            add(TemperatureStreamFailed('Heartbeat falló: ${failure.message}')),
        (_) {},
      );
    });
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
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
