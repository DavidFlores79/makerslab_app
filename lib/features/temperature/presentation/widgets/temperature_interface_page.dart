// lib/presentation/pages/temperature_interface_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../domain/entities/temperature_entity.dart';
import '../bloc/temperature_bloc.dart';
import '../bloc/temperature_event.dart';
import '../bloc/temperature_state.dart';

// Si usas get_it para instanciar el Bloc, reemplaza el BlocProvider.create por:
// create: (_) => getIt<TemperatureBloc>()

class TemperatureInterfacePage extends StatelessWidget {
  static const String routeName = '/temperature/interface';
  const TemperatureInterfacePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Asumo que el TemperatureBloc ya está provisto por un ancestor BlocProvider
    // o que quieres envolver esta página con uno. Si no, cambia a BlocProvider aquí.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interfaz — Temperatura'),
        actions: [
          BlocSelector<TemperatureBloc, TemperatureState, bool>(
            selector: (state) => state is TempConnected,
            builder: (context, isConnected) {
              return IconButton(
                tooltip: isConnected ? 'Desconectar' : 'Buscar dispositivo',
                icon: Icon(
                  Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  final bloc = context.read<TemperatureBloc>();
                  if (isConnected) {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('¿Desconectar?'),
                            content: const Text(
                              '¿Estás seguro de que quieres desconectarte del dispositivo?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.pop(); // cierra el diálogo
                                  bloc.add(StopTemperature());
                                },
                                child: const Text('Desconectar'),
                              ),
                            ],
                          ),
                    );
                  } else {
                    // Dispara el escaneo
                    bloc.add(StartScan());

                    // Muestra el modal
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (modalContext) {
                        return BlocProvider<TemperatureBloc>.value(
                          value: bloc,
                          child: BlocListener<
                            TemperatureBloc,
                            TemperatureState
                          >(
                            listener: (context, state) {
                              if (state is TempError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.message)),
                                );
                              }

                              if (state is TempConnected) {
                                // context.pop(context); // cierra el modal
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(modalContext).size.height *
                                    0.6,
                                child: BlocBuilder<
                                  TemperatureBloc,
                                  TemperatureState
                                >(
                                  builder: (context, state) {
                                    if (state is TempLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    if (state is DevicesLoaded) {
                                      final devices = state.devices;
                                      if (devices.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'No se encontraron dispositivos.',
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed:
                                                    () => context
                                                        .read<TemperatureBloc>()
                                                        .add(StartScan()),
                                                child: const Text(
                                                  'Reintentar búsqueda',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        itemCount: devices.length,
                                        separatorBuilder:
                                            (_, __) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final d = devices[index];
                                          final name =
                                              (d.name != null &&
                                                      d.name
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? d.name.toString()
                                                  : d.address.toString();
                                          final subtitle =
                                              d.address?.toString() ?? '';
                                          return ListTile(
                                            title: Text(name),
                                            subtitle: Text(subtitle),
                                            trailing: const Icon(
                                              Icons.bluetooth,
                                            ),
                                            onTap: () {
                                              final address =
                                                  d.address?.toString() ??
                                                  d.toString();
                                              context
                                                  .read<TemperatureBloc>()
                                                  .add(SelectDevice(address));
                                              Navigator.pop(
                                                context,
                                              ); // cierra el modal al seleccionar
                                            },
                                          );
                                        },
                                      );
                                    }

                                    if (state is TempError) {
                                      return Center(
                                        child: Text(
                                          'Error: ${state.message}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      );
                                    }

                                    return const Center(
                                      child: Text('Iniciando búsqueda...'),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
          padding: const EdgeInsets.all(12.0),
          child: BlocBuilder<TemperatureBloc, TemperatureState>(
            builder: (context, state) {
              if (state is TempLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TempConnecting) {
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
                  onRetry:
                      () => context.read<TemperatureBloc>().add(StartScan()),
                );
              }

              if (state is TempDisconnected) {
                return const _DisconnectedView();
              }

              // TempInitial, DevicesLoaded or fallback: show initial view
              return const _InitialView();
            },
          ),
        ),
      ),
      floatingActionButton: _FloatingReadNowButton(),
    );
  }
}

/* -------------------------
   UI Sub-widgets
   -------------------------*/

class _ConnectedView extends StatelessWidget {
  final Temperature? latest;
  final List<Temperature> history;

  const _ConnectedView({Key? key, required this.latest, required this.history})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return const Center(child: Text('Esperando primera lectura...'));
    }

    // Rango de ejemplo para la gauge, ajústalo según tu caso (DHT11: -10..60 / Hum: 0..100)
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Sensor conectado — Última lectura: ${_formatTimestamp(latest?.timestamp ?? DateTime.now())}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Gauge para temperatura (centrado)
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SfLinearGauge(
                    minimum: -10,
                    maximum: 60,
                    showTicks: true,
                    showLabels: true,
                    markerPointers: <LinearMarkerPointer>[
                      LinearWidgetPointer(
                        value: latest?.celsius ?? 0,
                        child: _buildMarker(
                          '${latest?.celsius.toStringAsFixed(1) ?? 0}°C',
                        ),
                      ),
                    ],
                    barPointers: <LinearBarPointer>[
                      LinearBarPointer(value: latest?.celsius ?? 0),
                    ],
                    ranges: <LinearGaugeRange>[
                      LinearGaugeRange(startValue: -10, endValue: 0),
                      LinearGaugeRange(startValue: 0, endValue: 25),
                      LinearGaugeRange(startValue: 25, endValue: 40),
                      LinearGaugeRange(startValue: 40, endValue: 60),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Gauge para humedad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SfLinearGauge(
                    minimum: 0,
                    maximum: 100,
                    showTicks: true,
                    showLabels: true,
                    markerPointers: <LinearMarkerPointer>[
                      LinearWidgetPointer(
                        value: latest?.humidity ?? 0,
                        child: _buildMarker(
                          '${latest?.humidity.toStringAsFixed(0) ?? 0}%',
                        ),
                      ),
                    ],
                    barPointers: <LinearBarPointer>[
                      LinearBarPointer(value: latest?.humidity ?? 0),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Mini-historial (últimos N)
        if (history.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              itemBuilder: (context, i) {
                final t = history[history.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${t.celsius.toStringAsFixed(1)}°C'),
                      Text('${t.humidity.toStringAsFixed(0)}%'),
                      Text(
                        _shortTime(t.timestamp),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMarker(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static String _formatTimestamp(DateTime ts) => ts.toLocal().toString();
  static String _shortTime(DateTime ts) {
    final d = ts.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          'Conectando al dispositivo...',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Gauge para temperatura deshabilitado
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SfLinearGauge(
                    minimum: -10,
                    maximum: 60,
                    showTicks: true,
                    showLabels: true,
                    markerPointers: <LinearMarkerPointer>[
                      LinearWidgetPointer(
                        value: 0,
                        child: _buildMarker('--°C'),
                      ),
                    ],
                    barPointers: <LinearBarPointer>[
                      LinearBarPointer(value: 0, color: Colors.grey),
                    ],
                    ranges: <LinearGaugeRange>[
                      LinearGaugeRange(startValue: -10, endValue: 0),
                      LinearGaugeRange(startValue: 0, endValue: 25),
                      LinearGaugeRange(startValue: 25, endValue: 40),
                      LinearGaugeRange(startValue: 40, endValue: 60),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Gauge para humedad deshabilitado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SfLinearGauge(
                    minimum: 0,
                    maximum: 100,
                    showTicks: true,
                    showLabels: true,
                    markerPointers: <LinearMarkerPointer>[
                      LinearWidgetPointer(value: 0, child: _buildMarker('--%')),
                    ],
                    barPointers: <LinearBarPointer>[
                      LinearBarPointer(value: 0, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({Key? key, required this.message, required this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $message', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Desconectado'),
          SizedBox(height: 12),
          Text('Presiona el ícono de Bluetooth para reconectar'),
        ],
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Presiona el ícono de Bluetooth para conectar con el ESP32'),
        ],
      ),
    );
  }
}

class _FloatingReadNowButton extends StatelessWidget {
  const _FloatingReadNowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // El botón estará habilitado solo si el BLoC está en estado TempConnected; de lo contrario no hace nada.
    return FloatingActionButton(
      tooltip: 'Leer ahora',
      child: const Icon(Icons.flash_on),
      onPressed: () {
        final state = context.read<TemperatureBloc>().state;
        if (state is TempConnected) {
          context.read<TemperatureBloc>().add(ReadNowEvent());
        } else {
          // muestra mensaje rápido
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No conectado — no se puede solicitar lectura'),
            ),
          );
        }
      },
    );
  }
}
