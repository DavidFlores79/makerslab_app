// lib/features/temperature/presentation/pages/temperature_interface_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_event.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../../../di/service_locator.dart';
import '../../../../theme/app_color.dart';
import '../../domain/entities/temperature_entity.dart';
import '../bloc/temperature_bloc.dart';
import '../bloc/temperature_state.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // For SfRadialGauge
import 'package:keep_screen_on/keep_screen_on.dart'; // Assuming you have this package for keep screen on

class TemperatureInterfacePage extends StatefulWidget {
  static const String routeName = '/temperature/interface';
  const TemperatureInterfacePage({super.key});

  @override
  State<TemperatureInterfacePage> createState() =>
      _TemperatureInterfacePageState();
}

class _TemperatureInterfacePageState extends State<TemperatureInterfacePage> {
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

  void _showDisconnectDialog(
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Paso 1: Inicia la desconexión
                  pageContext.read<BluetoothBloc>().add(
                    BluetoothDisconnectRequested(),
                  );

                  // Paso 2: Cierra el diálogo
                  Navigator.of(dialogContext).pop();

                  // --- LÓGICA CONDICIONAL ---
                  // Paso 3 (Opcional): Cierra la página solo si se especificó.
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

  // Actualiza la función _showDeviceSelectionModal en _TemperatureInterfacePageState
  void _showDeviceSelectionModal(BuildContext context) {
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
                SnackbarService().show(
                  message: 'Error: ${state.message}',
                  // isError: true,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(
                16.0,
              ), // Aumenta el padding para mejor legibilidad
              child: SizedBox(
                height: MediaQuery.of(modalContext).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado educativo
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
                            color: AppColors.gray600, // Gris medio
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
                    Text(
                      'Selecciona tu sensor ESP32 para conectar y aprender sobre temperatura y humedad.',
                      style: theme.bodyMedium?.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      color: AppColors.gray300,
                    ), // Divider para separación limpia
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
                                      AppColors.gray600, // Gris discreto
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
                            final devices = state.devices;

                            // 1. Creamos una copia mutable de la lista para poder ordenarla.
                            final sortedDevices = List.of(
                              state.devices,
                            ); // <--- NUEVO

                            // 2. Ordenamos la lista.
                            sortedDevices.sort((a, b) {
                              // <--- NUEVO
                              final aIsESP32 =
                                  a.name?.toLowerCase().contains('esp32') ??
                                  false;
                              final bIsESP32 =
                                  b.name?.toLowerCase().contains('esp32') ??
                                  false;

                              if (aIsESP32 && !bIsESP32) {
                                return -1; // 'a' (ESP32) va antes que 'b'.
                              } else if (!aIsESP32 && bIsESP32) {
                                return 1; // 'b' (ESP32) va antes que 'a'.
                              } else {
                                return 0; // Son iguales, se mantiene el orden relativo.
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
                                ); // Resalta si es ESP32 para fines educativos
                                return Card(
                                  elevation:
                                      1, // Elevación baja para discreción
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color:
                                      isESP32
                                          ? AppColors
                                              .gray200 // Gris claro para highlight sutil
                                          : AppColors.gray100, // Gris muy claro
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ), // Padding para evitar desbordes
                                    leading: Icon(
                                      Icons.bluetooth,
                                      color:
                                          isESP32
                                              ? AppColors
                                                  .gray700 // Gris oscuro
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
                                              //border color
                                              side: BorderSide(
                                                color: AppColors.primaryLight,
                                              ),
                                              label: Text('Recomendado'),
                                              backgroundColor:
                                                  AppColors
                                                      .primary, // Gris medio
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

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppColors.gray200;

    return BlocProvider(
      create: (context) => getIt<TemperatureBloc>(),
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
              // isError: true,
            );
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            // Assuming you have PxBackAppBar or replace with standard AppBar
            title: const Text('Temperatura'),
            backgroundColor: backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final bluetoothState = context.read<BluetoothBloc>().state;
                debugPrint(
                  'Back button pressed. Bluetooth state is $bluetoothState',
                );

                // Comprueba si el estado es BluetoothConnected.
                if (bluetoothState is BluetoothConnected) {
                  _showDisconnectDialog(context, popPageAfter: true);
                } else {
                  // Si no está conectado, simplemente navega hacia atrás.
                  // Usamos GoRouter.pop() en este caso.
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
                        _showDisconnectDialog(context);
                      } else {
                        _showDeviceSelectionModal(context);
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
              child: BlocBuilder<TemperatureBloc, TemperatureState>(
                builder: (context, state) {
                  if (state is TempLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (context.select(
                    (BluetoothBloc b) => b.state is BluetoothConnecting,
                  )) {
                    return const _ConnectingView();
                  }
                  if (state is TempConnected) {
                    return _ConnectedView(
                      latest: state.latest,
                      history: state.history,
                    );
                  }
                  if (state is TempError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => _showDeviceSelectionModal(context),
                    );
                  }
                  if (state is TempDisconnected) {
                    return const _DisconnectedView();
                  }
                  return const _InitialView();
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
class _ConnectedView extends StatefulWidget {
  final Temperature latest;
  final List<Temperature> history;

  const _ConnectedView({required this.latest, required this.history});

  @override
  State<_ConnectedView> createState() => _ConnectedViewState();
}

class _ConnectedViewState extends State<_ConnectedView> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPageIndex) {
        setState(() {
          _currentPageIndex = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConnectionStatusHeader(
          timestamp: widget.latest.timestamp ?? DateTime.now(),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: PageView(
            controller: _pageController,
            children: [
              _DataGaugeView.temperature(value: widget.latest.celsius),
              _DataGaugeView.humidity(value: widget.latest.humidity),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PageIndicator(pageCount: 2, currentPageIndex: _currentPageIndex),
        const SizedBox(height: 24),
        if (widget.history.isNotEmpty) _HistoryLogView(history: widget.history),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ConnectionStatusHeader extends StatelessWidget {
  final DateTime timestamp;
  const _ConnectionStatusHeader({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('Conectado', style: theme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Última lectura: ${DateFormat('HH:mm:ss').format(timestamp.toLocal())}',
          style: theme.bodyMedium?.copyWith(color: AppColors.gray600),
        ),
      ],
    );
  }
}

class _DataGaugeView extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double value;
  final String unit;
  final double min, max;
  final Gradient gradient;

  const _DataGaugeView({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.gradient,
  });

  factory _DataGaugeView.temperature({required double value}) {
    return _DataGaugeView(
      title: 'Temperatura',
      icon: Icons.thermostat,
      iconColor: AppColors.redAccent,
      value: value,
      unit: '°C',
      min: -10,
      max: 60,
      gradient: const SweepGradient(
        colors: [
          AppColors.blue,
          AppColors.lightGreen,
          AppColors.orange,
          AppColors.red,
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ),
    );
  }

  factory _DataGaugeView.humidity({required double value}) {
    return _DataGaugeView(
      title: 'Humedad',
      icon: Icons.water_drop_outlined,
      iconColor: AppColors.blueAccent,
      value: value,
      unit: '%',
      min: 0,
      max: 100,
      gradient: const SweepGradient(
        colors: [Colors.yellow, AppColors.lightGreen, AppColors.blueAccent],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    const backgroundColor = AppColors.gray100; // Color base para Neumorfismo

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray500,
            offset: const Offset(4, 4),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 8),
              Text(title, style: theme.titleLarge),
            ],
          ),
          Expanded(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.2,
                    cornerStyle: CornerStyle.bothCurve,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: value,
                      width: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                      gradient: gradient,
                      enableAnimation: true,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '${value.toStringAsFixed(1)}$unit',
                        style: theme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      angle: 90,
                      positionFactor: 0.1,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPageIndex;

  const _PageIndicator({
    required this.pageCount,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPageIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color:
                currentPageIndex == index
                    ? Theme.of(context).primaryColor
                    : AppColors.gray400,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET DE LOG DE DATOS
// =========================================================================

class _HistoryLogView extends StatelessWidget {
  final List<Temperature> history;
  const _HistoryLogView({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final recentHistory =
        history.length > 5 ? history.sublist(history.length - 5) : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log de Datos Recientes', style: theme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 120, // Altura fija para el log
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray800, // Fondo oscuro para estética de consola
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray700),
          ),
          child: ListView(
            reverse: true, // Muestra lo más nuevo arriba
            children:
                recentHistory.reversed.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: AppColors.gray300,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '[${DateFormat('HH:mm:ss').format(item.timestamp.toLocal())}] ',
                          ),
                          const TextSpan(text: 'RX -> '),
                          TextSpan(
                            text:
                                'T: ${item.celsius.toStringAsFixed(1).padLeft(4)}°C, ',
                            style: const TextStyle(color: AppColors.lightGreen),
                          ),
                          TextSpan(
                            text:
                                'H: ${item.humidity.toStringAsFixed(0).padLeft(2)}%',
                            style: const TextStyle(color: AppColors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
//                        WIDGETS DE ESTADO
// =========================================================================
class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Conectando al dispositivo...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.redAccent, size: 50),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueAccent,
              foregroundColor: AppColors.white,
            ),
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_disabled, size: 50, color: AppColors.gray600),
          SizedBox(height: 16),
          Text(
            'Desconectado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona el ícono de Bluetooth para reconectar',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 50,
            color: AppColors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(
            'Presiona el ícono de Bluetooth para conectar con el ESP32',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
