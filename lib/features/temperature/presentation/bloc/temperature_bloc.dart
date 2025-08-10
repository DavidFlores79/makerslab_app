import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_temperature_data_usecase.dart';
import 'temperature_event.dart';
import 'temperature_state.dart';

class TemperatureBloc extends Bloc<TemperaturesEvent, TemperaturesState> {
  final GetTemperatureDataUseCase getTemperatureData;

  TemperatureBloc({required this.getTemperatureData})
    : super(InitialDataLoading()) {
    on<LoadTemperatures>(_onLoadTemperatures);
  }

  Future<void> _onLoadTemperatures(
    LoadTemperatures event,
    Emitter<TemperaturesState> emit,
  ) async {
    emit(TemperaturesLoading());
    final result = await getTemperatureData();
    result.fold(
      (error) => emit(TemperaturesError(error.message)),
      (data) => emit(
        TemperaturesLoaded(data: data),
      ), // CAMBIO AQU�: 'data' en lugar de 'temperatures'
    );
  }
}
