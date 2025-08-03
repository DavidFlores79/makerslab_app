import 'package:flutter_bloc/flutter_bloc.dart';
import 'servo_event.dart';
import 'servo_state.dart';
import '../../domain/usecases/get_servo_data_usecase.dart';

class ServosBloc extends Bloc<ServosEvent, ServosState> {
  final GetServoDataUseCase getServoData;

  ServosBloc({
    required this.getServoData,
  }) : super(InitialDataLoading()) {
    on<LoadServos>(_onLoadServos);
  }

  Future<void> _onLoadServos(
    LoadServos event,
    Emitter<ServosState> emit,
  ) async {
    emit(ServosLoading());
    final result = await getServoData();
    result.fold(
      (error) => emit(ServosError(error.message)),
      (data) => emit(ServosLoaded(data: data)), // CAMBIO AQUÍ: 'data' en lugar de 'servos'
    );
  }
}