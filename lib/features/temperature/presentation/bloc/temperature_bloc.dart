import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/repositories/temperature_repository.dart';
import '../../domain/usecases/get_temperature_stream_usecase.dart';
import 'temperature_event.dart';
import 'temperature_state.dart';

class TemperatureBloc extends Bloc<TemperatureEvent, TemperatureState> {
  final TemperatureRepository repository;
  final GetTemperatureStream getTemperatureStream;

  StreamSubscription<Either<Failure, Temperature>>? _streamSub;
  final List<Temperature> _history = [];

  TemperatureBloc({
    required this.repository,
    required this.getTemperatureStream,
  }) : super(TempInitial()) {
    on<StartScan>(_onStartScan);
    on<SelectDevice>(_onSelectDevice);
    on<StopTemperature>(_onStop);
    on<ReadNowEvent>(_onReadNow);
    on<TemperatureReceived>(_onTemperatureReceived);
    on<TemperatureStreamError>(_onTemperatureStreamError);
  }

  Future<void> _onStartScan(
    StartScan event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TempLoading());
    // ejemplo: discovery; repo.discoverDevices() -> Either
    final result = await repository.discoverDevices();
    result.fold(
      (failure) => emit(TempError(failure.message)),
      (devices) => emit(DevicesLoaded(devices)),
    );
  }

  Future<void> _onSelectDevice(
    SelectDevice event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TempConnecting());

    // cancelar suscripción previa si existe
    await _streamSub?.cancel();
    _streamSub = null;

    final res = await repository.connectToDevice(event.address);

    res.fold(
      (failure) {
        emit(TempError(failure.message));
      },
      (r) {
        // Nos suscribimos, pero NO emitimos aquí; reenviamos eventos al Bloc
        _streamSub = repository.temperatureStream().listen(
          (either) {
            either.fold(
              (failure) {
                // reemitir como evento de error
                add(TemperatureStreamError(failure.message));
              },
              (temp) {
                add(TemperatureReceived(temp));
              },
            );
          },
          onError: (e) {
            add(TemperatureStreamError(e.toString()));
          },
        );

        emit(
          TempConnected(
            latest: Temperature(
              celsius: 0,
              humidity: 0,
              timestamp: DateTime.now(),
            ),
            history: List.from(_history),
          ),
        ); // o un estado conectado inicial
      },
    );
  }

  Future<void> _onTemperatureReceived(
    TemperatureReceived event,
    Emitter<TemperatureState> emit,
  ) async {
    _history.add(event.temperature);
    if (_history.length > 100) _history.removeAt(0);
    emit(
      TempConnected(latest: event.temperature, history: List.from(_history)),
    );
  }

  Future<void> _onTemperatureStreamError(
    TemperatureStreamError event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TempError(event.message));
  }

  Future<void> _onReadNow(
    ReadNowEvent event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TempLoading());
    final res = await repository.readNow();
    res.fold((failure) => emit(TempError(failure.message)), (temp) {
      _history.add(temp);
      if (_history.length > 100) _history.removeAt(0);
      emit(TempConnected(latest: temp, history: List.from(_history)));
    });
  }

  Future<void> _onStop(
    StopTemperature event,
    Emitter<TemperatureState> emit,
  ) async {
    await _streamSub?.cancel();
    final res = await repository.disconnect();
    res.fold(
      (failure) => emit(TempError(failure.message)),
      (_) => emit(TempDisconnected()),
    );
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}
