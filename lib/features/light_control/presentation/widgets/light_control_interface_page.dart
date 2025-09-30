// lib/features/led_control/presentation/pages/led_control_interface_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:makerslab_app/core/ui/bluetooth_dialogs.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:makerslab_app/di/service_locator.dart';
import 'package:makerslab_app/shared/widgets/index.dart'; // Para los widgets de estado
import 'package:makerslab_app/theme/app_color.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../bloc/light_control_bloc.dart';

class LightControlInterfacePage extends StatefulWidget {
  static const String routeName = '/light-control/interface';
  const LightControlInterfacePage({super.key});

  @override
  State<LightControlInterfacePage> createState() =>
      _LightControlInterfacePageState();
}

class _LightControlInterfacePageState extends State<LightControlInterfacePage> {
  @override
  void initState() {
    KeepScreenOn.turnOn();
    super.initState();
  }

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              getIt<
                LightControlBloc
              >(), // Asegúrate de registrarlo en service_locator
      child: BlocListener<BluetoothBloc, BluetoothState>(
        listener: (context, state) {
          if (state is BluetoothConnected) {
            SnackbarService().show(
              message:
                  'Conectado a ${state.device.name ?? state.device.address}',
            );
          } else if (state is BluetoothError) {
            SnackbarService().show(
              message: 'Error de conexión: ${state.message}',
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Control de LED'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final bluetoothState = context.read<BluetoothBloc>().state;
                if (bluetoothState is BluetoothConnected) {
                  BluetoothDialogs.showDisconnectDialog(
                    context,
                    popPageAfter: true,
                  );
                } else {
                  context.pop();
                }
              },
            ),
            actions: [
              BlocSelector<BluetoothBloc, BluetoothState, bool>(
                selector: (state) => state is BluetoothConnected,
                builder: (context, isConnected) {
                  return IconButton(
                    tooltip: isConnected ? 'Desconectar' : 'Buscar dispositivo',
                    icon: Icon(
                      Icons.bluetooth,
                      color:
                          isConnected
                              ? AppColors.lightGreen
                              : AppColors.redAccent,
                    ),
                    onPressed: () {
                      if (isConnected) {
                        BluetoothDialogs.showDisconnectDialog(context);
                      } else {
                        BluetoothDialogs.showDeviceSelectionModal(
                          context,
                          instructionalText:
                              'Selecciona tu ESP32 para encender y apagar el LED.',
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<LightControlBloc, LightControlState>(
                builder: (context, state) {
                  if (state is LightControlLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (context.select(
                    (BluetoothBloc b) => b.state is BluetoothConnecting,
                  )) {
                    return const ConnectingView();
                  }
                  if (state is LightControlConnected) {
                    return _ConnectedView(isLightOn: state.isLightOn);
                  }
                  if (state is LightControlError) {
                    return ErrorView(
                      message: state.message,
                      onRetry:
                          () => BluetoothDialogs.showDeviceSelectionModal(
                            context,
                            instructionalText:
                                'Selecciona tu ESP32 para encender y apagar el LED.',
                          ),
                    );
                  }
                  // Asumimos que un estado BluetoothDisconnected se maneja
                  // escuchando el BluetoothBloc y emitiendo un estado desde LightControlBloc
                  return const InitialView();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================
// WIDGETS DE LA VISTA CONECTADA
// ==============================
class _ConnectedView extends StatelessWidget {
  final bool isLightOn;

  const _ConnectedView({required this.isLightOn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            _LightToggleButton(isLightOn: isLightOn),
            const SizedBox(height: 30),
            Text(
              isLightOn ? 'Encendido' : 'Apagado',
              style: theme.headlineMedium?.copyWith(
                color: isLightOn ? AppColors.lightGreen : AppColors.gray600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.description_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                // TODO: Implementar la lógica para mostrar las instrucciones
                SnackbarService().show(message: 'Mostrar instrucciones (TODO)');
              },
              label: const Text('Ver Instrucciones'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _LightToggleButton extends StatelessWidget {
  final bool isLightOn;
  const _LightToggleButton({required this.isLightOn});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = (size.width < 600) ? size.width * 0.7 : size.width * 0.4;

    return GestureDetector(
      onTap: () {
        // Enviar evento al BLoC para cambiar el estado del LED
        context.read<LightControlBloc>().add(LightControlToggleRequested());
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors:
                isLightOn
                    ? [
                      const Color.fromARGB(255, 9, 241, 86),
                      const Color.fromARGB(255, 72, 184, 75),
                    ]
                    : [Colors.black54, Colors.grey],
          ),
        ),
        child: _InnerCirclePowerIcon(
          isLedOn: isLightOn,
          parentSize: buttonSize,
        ),
      ),
    );
  }
}

class _InnerCirclePowerIcon extends StatelessWidget {
  final bool isLedOn;
  final double parentSize;

  const _InnerCirclePowerIcon({
    required this.isLedOn,
    required this.parentSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0), // Un gris claro para el fondo
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            height: parentSize * 0.3,
            width: parentSize * 0.3,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade500,
                  offset: const Offset(4, 4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.power_settings_new_outlined,
              size: parentSize * 0.15,
              color:
                  isLedOn
                      ? const Color.fromARGB(255, 9, 241, 86)
                      : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
