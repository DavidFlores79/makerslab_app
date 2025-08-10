import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_light_control_data_usecase.dart';
import 'light_control_event.dart';
import 'light_control_state.dart';

class LightControlsBloc extends Bloc<LightControlsEvent, LightControlsState> {
  final GetLightControlDataUseCase getLightControlData;

  LightControlsBloc({required this.getLightControlData})
    : super(InitialDataLoading()) {
    on<LoadLightControls>(_onLoadLightControls);
  }

  Future<void> _onLoadLightControls(
    LoadLightControls event,
    Emitter<LightControlsState> emit,
  ) async {
    emit(LightControlsLoading());
    final result = await getLightControlData();
    result.fold(
      (error) => emit(LightControlsError(error.message)),
      (data) => emit(
        LightControlsLoaded(data: data),
      ), // CAMBIO AQU�: 'data' en lugar de 'light_controls'
    );
  }
}
