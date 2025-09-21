import 'package:flutter_bloc/flutter_bloc.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';
import '../../domain/usecases/get_bluetooth_data_usecase.dart';

class BluetoothsBloc extends Bloc<BluetoothsEvent, BluetoothsState> {
  final GetBluetoothDataUseCase getBluetoothData;

  BluetoothsBloc({
    required this.getBluetoothData,
  }) : super(InitialDataLoading()) {
    on<LoadBluetooths>(_onLoadBluetooths);
  }

  Future<void> _onLoadBluetooths(
    LoadBluetooths event,
    Emitter<BluetoothsState> emit,
  ) async {
    emit(BluetoothsLoading());
    final result = await getBluetoothData();
    result.fold(
      (error) => emit(BluetoothsError(error.message)),
      (data) => emit(BluetoothsLoaded(data: data)), // CAMBIO AQUÍ: 'data' en lugar de 'bluetooths'
    );
  }
}