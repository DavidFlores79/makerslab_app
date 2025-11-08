import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/permission_handler.dart';
import '../../../domain/usecases/bluetooth/discover_devices.dart';
import '../../../domain/usecases/bluetooth/connect_device.dart';
import '../../../domain/usecases/bluetooth/disconnect_device.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final DiscoverDevicesUseCase discoverDevicesUseCase;
  final ConnectDeviceUseCase connectDeviceUseCase;
  final DisconnectDeviceUseCase disconnectDeviceUseCase;
  final PermissionService permissionService;

  BluetoothBloc({
    required this.discoverDevicesUseCase,
    required this.connectDeviceUseCase,
    required this.disconnectDeviceUseCase,
    required this.permissionService,
  }) : super(BluetoothInitial()) {
    on<BluetoothScanRequested>(_onScanRequested);
    on<BluetoothDeviceSelected>(_onDeviceSelected);
    on<BluetoothDisconnectRequested>(_onDisconnectRequested);
  }

  Future<void> _onScanRequested(
    BluetoothScanRequested event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(BluetoothScanning()); // Emite scanning temprano para UI
    try {
      final granted = await permissionService.requestBluetoothPermissions();
      if (!granted) {
        emit(
          BluetoothError(
            'Permisos requeridos. Habilita Bluetooth en settings.',
          ),
        );
        return;
      }
      final result = await discoverDevicesUseCase();
      result.fold(
        (failure) => emit(BluetoothError(failure.message)),
        (devices) => emit(BluetoothScanLoaded(devices)),
      );
    } catch (e) {
      emit(
        BluetoothError(
          'Error con permisos o manifest: $e. Verifica configuración.',
        ),
      );
    }
  }

  Future<void> _onDeviceSelected(
    BluetoothDeviceSelected event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(BluetoothConnecting());
    final result = await connectDeviceUseCase(event.device.address);
    result.fold(
      (failure) => emit(BluetoothError(failure.message)),
      (_) => emit(BluetoothConnected(event.device)),
    );
  }

  Future<void> _onDisconnectRequested(
    BluetoothDisconnectRequested event,
    Emitter<BluetoothState> emit,
  ) async {
    final result = await disconnectDeviceUseCase();
    result.fold(
      (failure) => emit(BluetoothError(failure.message)),
      (_) => emit(BluetoothDisconnected()),
    );
  }
}
