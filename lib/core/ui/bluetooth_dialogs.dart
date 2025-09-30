import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:makerslab_app/core/presentation/bloc/bluetooth/bluetooth_event.dart';
import 'package:makerslab_app/core/presentation/bloc/bluetooth/bluetooth_state.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:makerslab_app/theme/app_color.dart';

/// Una clase de utilidad para mostrar diálogos comunes relacionados con Bluetooth.
class BluetoothDialogs {
  // Hacemos el constructor privado para que esta clase no pueda ser instanciada.
  BluetoothDialogs._();

  /// Muestra un diálogo de confirmación para desconectar un dispositivo Bluetooth.
  static void showDisconnectDialog(
    BuildContext pageContext, {
    bool popPageAfter = false,
  }) {
    final theme = Theme.of(pageContext).textTheme;
    showDialog(
      context: pageContext,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              '¿Desconectar?',
              textAlign: TextAlign.center,
              style: theme.titleLarge,
            ),
            content: Text(
              '¿Estás seguro de que quieres desconectarte del dispositivo?',
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  pageContext.read<BluetoothBloc>().add(
                    BluetoothDisconnectRequested(),
                  );
                  dialogContext.pop();
                  if (popPageAfter) {
                    pageContext.pop();
                  }
                },
                child: const Text('Desconectar'),
              ),
            ],
          ),
    );
  }

  /// Muestra un modal para escanear y seleccionar un dispositivo Bluetooth.
  ///
  /// [instructionalText] es el texto que se muestra al usuario para guiarlo,
  /// específico para cada módulo.
  static void showDeviceSelectionModal(
    BuildContext context, {
    required String instructionalText,
  }) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    bluetoothBloc.add(BluetoothScanRequested());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        final theme = Theme.of(modalContext).textTheme;
        return BlocProvider<BluetoothBloc>.value(
          value: bluetoothBloc,
          child: BlocListener<BluetoothBloc, BluetoothState>(
            listener: (context, state) {
              if (state is BluetoothError) {
                SnackbarService().show(message: 'Error: ${state.message}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: MediaQuery.of(modalContext).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Dispositivos Bluetooth Disponibles',
                            style: theme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.gray600,
                          ),
                          onPressed:
                              () => context.read<BluetoothBloc>().add(
                                BluetoothScanRequested(),
                              ),
                          tooltip: 'Actualizar lista',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Usamos el parámetro para el texto instructivo
                    Text(
                      instructionalText,
                      style: theme.bodyMedium?.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.gray300),
                    Expanded(
                      child: BlocBuilder<BluetoothBloc, BluetoothState>(
                        builder: (context, state) {
                          if (state is BluetoothScanning ||
                              state is BluetoothConnecting) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.gray600,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Buscando dispositivos...',
                                    style: TextStyle(color: AppColors.gray500),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (state is BluetoothScanLoaded) {
                            final sortedDevices = List.of(state.devices);

                            sortedDevices.sort((a, b) {
                              final aIsESP32 =
                                  a.name?.toLowerCase().contains('esp32') ??
                                  false;
                              final bIsESP32 =
                                  b.name?.toLowerCase().contains('esp32') ??
                                  false;

                              if (aIsESP32 && !bIsESP32) {
                                return -1;
                              } else if (!aIsESP32 && bIsESP32) {
                                return 1;
                              } else {
                                return 0;
                              }
                            });

                            if (sortedDevices.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 50,
                                      color: AppColors.gray500,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No se encontraron dispositivos.\nAsegúrate de que tu ESP32 esté encendido y visible.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors
                                                .gray600, // Gris oscuro para botón
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () => context
                                              .read<BluetoothBloc>()
                                              .add(BluetoothScanRequested()),
                                      child: const Text('Reintentar búsqueda'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: sortedDevices.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(color: AppColors.gray300),
                              itemBuilder: (context, index) {
                                final d = sortedDevices[index];
                                final name =
                                    (d.name != null && d.name!.isNotEmpty)
                                        ? d.name!
                                        : 'Dispositivo desconocido';
                                final subtitle = d.address;
                                final isESP32 = name.toLowerCase().contains(
                                  'esp32',
                                );
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color:
                                      isESP32
                                          ? AppColors.gray200
                                          : AppColors.gray100,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Icon(
                                      Icons.bluetooth,
                                      color:
                                          isESP32
                                              ? AppColors.gray700
                                              : AppColors.gray600,
                                      size: 32,
                                    ),
                                    title: Text(
                                      name,
                                      style: theme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      style: theme.bodyMedium?.copyWith(
                                        color: AppColors.gray600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    trailing:
                                        isESP32
                                            ? const Chip(
                                              side: BorderSide(
                                                color: AppColors.primaryLight,
                                              ),
                                              label: Text('Recomendado'),
                                              backgroundColor:
                                                  AppColors.primary,
                                              labelStyle: TextStyle(
                                                color: AppColors.white,
                                              ),
                                            )
                                            : null,
                                    onTap: () {
                                      context.read<BluetoothBloc>().add(
                                        BluetoothDeviceSelected(d),
                                      );
                                      context.pop();
                                    },
                                  ),
                                );
                              },
                            );
                          }
                          if (state is BluetoothError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color:
                                        AppColors
                                            .gray600, // Gris en lugar de rojo
                                    size: 50,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Error: ${state.message}',
                                    style: theme.bodySmall?.copyWith(
                                      color: AppColors.gray600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Center(
                            child: Text('Iniciando búsqueda...'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
