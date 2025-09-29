// lib/features/temperature/presentation/widgets/device_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    show BluetoothDevice;

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_event.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../../../theme/app_color.dart';
// Asumo que tienes un widget de botón personalizado, lo incluyo como referencia
// import 'package:yourapp/presentation/widgets/main_app_button.dart';

class DevicePicker {
  /// Muestra el modal para seleccionar un dispositivo Bluetooth.
  ///
  /// Ahora este método es el orquestador:
  /// 1. Dispara el evento para escanear.
  /// 2. Muestra el BottomSheet que escucha al [BluetoothBloc].
  /// 3. Devuelve el dispositivo seleccionado por el usuario.
  static Future<BluetoothDevice?> show(BuildContext context) {
    // Obtenemos la instancia del BLoC global que está disponible en el contexto.
    final bluetoothBloc = context.read<BluetoothBloc>();

    // Inmediatamente disparamos el evento para que comience a escanear.
    bluetoothBloc.add(BluetoothScanRequested());

    return showModalBottomSheet<BluetoothDevice?>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        // Proveemos el BLoC al sub-árbol del modal para que pueda ser accedido.
        // Esto es importante si el BLoC no fue proveído en la raíz de la app.
        // Si ya está disponible globalmente, este BlocProvider no es estrictamente necesario.
        return BlocProvider.value(
          value: bluetoothBloc,
          child: const _DevicePickerSheet(),
        );
      },
    );
  }
}

/// El widget interno que construye la UI del selector de dispositivos.
class _DevicePickerSheet extends StatelessWidget {
  const _DevicePickerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Handle para arrastrar el modal
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Encabezado con título y botón de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Dispositivo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // El botón ahora simplemente dispara un evento al BLoC.
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buscar de nuevo'),
                    onPressed:
                        () => context.read<BluetoothBloc>().add(
                          BluetoothScanRequested(),
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // El cuerpo del selector, que reacciona a los estados del BluetoothBloc.
            Expanded(
              child: BlocBuilder<BluetoothBloc, BluetoothState>(
                builder: (context, state) {
                  // Muestra un indicador de progreso mientras se escanea.
                  if (state is BluetoothScanning ||
                      state is BluetoothConnecting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Muestra la lista de dispositivos cuando se han cargado.
                  if (state is BluetoothScanLoaded) {
                    if (state.devices.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron dispositivos.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: state.devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final device = state.devices[i];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.name ?? 'Dispositivo Desconocido'),
                          subtitle: Text(device.address),
                          trailing: ElevatedButton(
                            child: const Text('Conectar'),
                            onPressed: () {
                              // Al presionar "Conectar", cerramos el modal y devolvemos el dispositivo.
                              Navigator.of(context).pop(device);
                            },
                          ),
                        );
                      },
                    );
                  }

                  // Muestra un mensaje de error si algo falla.
                  if (state is BluetoothError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: AppColors.red),
                      ),
                    );
                  }

                  // Estado inicial o por defecto.
                  return const Center(
                    child: Text('Presiona "Buscar de nuevo" para iniciar.'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
