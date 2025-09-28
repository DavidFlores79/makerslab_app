// lib/presentation/widgets/device_picker.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:go_router/go_router.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import '../../../../core/data/services/bluetooth_service.dart';

class DevicePicker {
  static Future<BluetoothDevice?> show(
    BuildContext context,
    BluetoothService btService,
  ) {
    return showModalBottomSheet<BluetoothDevice?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DevicePickerSheet(btService: btService),
    );
  }
}

class _DevicePickerSheet extends StatefulWidget {
  final BluetoothService btService;
  const _DevicePickerSheet({required this.btService});

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet> {
  bool _loading = false;
  List<BluetoothDevice> _paired = [];
  List<BluetoothDiscoveryResult> _discoveryResults = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadPaired();
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPaired() async {
    setState(() => _loading = true);
    try {
      final p = await widget.btService.getPairedDevices();
      setState(() => _paired = p);
    } catch (e) {
      setState(() => _paired = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar dispositivos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startDiscovery() {
    setState(() {
      _loading = true;
      _discoveryResults = [];
    });

    _discoveryStreamSubscription = widget.btService.startDiscovery().listen(
      (result) {
        setState(() {
          final existingIndex = _discoveryResults.indexWhere(
            (r) => r.device.address == result.device.address,
          );
          if (existingIndex >= 0) {
            _discoveryResults[existingIndex] = result;
          } else {
            _discoveryResults.add(result);
          }
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _loading = false);
        }
        debugPrint("Discovery finished");
      },
      onError: (error) {
        if (mounted) {
          setState(() => _loading = false);
        }
        debugPrint("Discovery error: $error");
      },
    );
  }

  List<BluetoothDevice> _getCombinedDevices() {
    final allDevices = <BluetoothDevice>[];
    final addresses = <String>{};

    for (final device in _paired) {
      if (addresses.add(device.address)) {
        allDevices.add(device);
      }
    }

    for (final result in _discoveryResults) {
      if (addresses.add(result.device.address)) {
        allDevices.add(result.device);
      }
    }

    return allDevices;
  }

  Widget _tileFromDevice(BluetoothDevice d) {
    final name = d.name ?? 'Dispositivo Desconocido';
    final address = d.address;
    final isPaired = _paired.any((device) => device.address == address);

    return ListTile(
      leading: Icon(isPaired ? Icons.bluetooth_connected : Icons.bluetooth),
      title: Text(name),
      subtitle: Text(address),
      trailing: MainAppButton(
        label: 'Conectar',
        onPressed: () {
          _discoveryStreamSubscription?.cancel();
          context.pop(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedDevices = _getCombinedDevices();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dispositivos Bluetooth',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // CAMBIO: Botones de acción simplificados
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refrescar emparejados',
                        onPressed: _loading ? null : _loadPaired,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                        onPressed: _loading ? null : _startDiscovery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child:
                  combinedDevices.isEmpty && !_loading
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No se encontraron dispositivos. Presiona "Buscar" para descubrir o "Refrescar" para ver los ya emparejados.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: combinedDevices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder:
                            (context, i) => _tileFromDevice(combinedDevices[i]),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
