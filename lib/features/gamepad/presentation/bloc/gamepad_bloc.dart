import 'package:flutter_bloc/flutter_bloc.dart';
import 'gamepad_event.dart';
import 'gamepad_state.dart';
import '../../domain/usecases/get_gamepad_data_usecase.dart';

class GamepadsBloc extends Bloc<GamepadsEvent, GamepadsState> {
  final GetGamepadDataUseCase getGamepadData;

  GamepadsBloc({required this.getGamepadData}) : super(InitialDataLoading()) {
    on<LoadGamepads>(_onLoadGamepads);
  }

  Future<void> _onLoadGamepads(
    LoadGamepads event,
    Emitter<GamepadsState> emit,
  ) async {
    emit(GamepadsLoading());
    final result = await getGamepadData();
    result.fold(
      (error) => emit(GamepadsError(error.message)),
      (data) => emit(
        GamepadsLoaded(data: data),
      ), // CAMBIO AQU�: 'data' en lugar de 'gamepads'
    );
  }
}
