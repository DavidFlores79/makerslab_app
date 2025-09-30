// lib/features/temperature/presentation/pages/temperature_interface_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:intl/intl.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../../../core/ui/bluetooth_dialogs.dart';
import '../../../../di/service_locator.dart';
import '../../../../theme/app_color.dart';
import '../../domain/entities/temperature_entity.dart';
import '../bloc/temperature_bloc.dart';
import '../bloc/temperature_state.dart';

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
            );
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text('Temperatura'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final bluetoothState = context.read<BluetoothBloc>().state;
                if (bluetoothState is BluetoothConnected) {
                  // Llama al método estático
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
                              'Selecciona tu sensor ESP32 para conectar y aprender sobre temperatura y humedad.',
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
              child: BlocBuilder<TemperatureBloc, TemperatureState>(
                builder: (context, state) {
                  if (state is TempLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (context.select(
                    (BluetoothBloc b) => b.state is BluetoothConnecting,
                  )) {
                    return const ConnectingView();
                  }
                  if (state is TempConnected) {
                    return _ConnectedView(
                      latest: state.latest,
                      history: state.history,
                    );
                  }
                  if (state is TempError) {
                    return ErrorView(
                      message: state.message,
                      onRetry:
                          () => BluetoothDialogs.showDeviceSelectionModal(
                            context,
                            instructionalText:
                                'Selecciona tu sensor ESP32 para conectar y aprender sobre temperatura y humedad.',
                          ),
                    );
                  }
                  if (state is TempDisconnected) {
                    return const DisconnectedView();
                  }
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
