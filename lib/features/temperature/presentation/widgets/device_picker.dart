// lib/presentation/widgets/device_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as btcs;
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import '../../../../core/services/bluetooth_service.dart';

class DevicePicker {
  /// Muestra un bottom modal y devuelve el BluetoothDevice seleccionado (o null)
  static Future<btcs.BluetoothDevice?> show(
    BuildContext context,
    BluetoothService btService,
  ) {
    return showModalBottomSheet<btcs.BluetoothDevice?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DevicePickerSheet(btService: btService),
    );
  }
}

class _DevicePickerSheet extends StatefulWidget {
  final BluetoothService btService;
  const _DevicePickerSheet({Key? key, required this.btService})
    : super(key: key);

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet> {
  bool _loading = false;
  List<btcs.BluetoothDevice> _paired = [];

  @override
  void initState() {
    super.initState();
    _loadPaired();
  }

  Future<void> _loadPaired() async {
    setState(() => _loading = true);
    try {
      final p = await widget.btService.getPairedDevices();
      setState(() => _paired = p);
    } catch (e) {
      setState(() => _paired = []);
      // opcional: mostrar snackbar de error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onBuscarPressed() async {
    setState(() => _loading = true);
    try {
      // Inicia discovery (no devuelve lista; sirve para que OS descubra y permita pairing)
      final started = await widget.btService.startDiscovery();
      if (!started) {
        // discovery failed; informar al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar búsqueda')),
        );
      } else {
        // Espera X segundos para que el usuario empareje o el sistema detecte el device.
        await Future.delayed(const Duration(seconds: 6));
        // Después de discovery: refresca la lista de emparejados (si el usuario hizo pairing desde el sistema)
        await _loadPaired();
      }
    } catch (e) {
      // simplemente refrescamos la lista y mostramos el error si quieres
      await _loadPaired();
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _tileFromDevice(btcs.BluetoothDevice d) {
    final name = (d.name != null && d.name!.isNotEmpty) ? d.name! : d.address;
    return ListTile(
      leading: const Icon(Icons.bluetooth),
      title: Text(name),
      subtitle: Text(d.address),
      trailing: MainAppButton(
        label: 'Conectar',
        onPressed: () => context.pop(d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  const Expanded(
                    child: Text(
                      'Dispositivos Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refrescar emparejados',
                    onPressed: _loadPaired,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                    onPressed: _onBuscarPressed,
                  ),
                ],
              ),
            ),
            const Divider(),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child:
                  _paired.isEmpty && !_loading
                      ? const Center(
                        child: Text(
                          'No hay dispositivos emparejados. Usa Buscar o empareja desde Ajustes.',
                        ),
                      )
                      : ListView.separated(
                        itemCount: _paired.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder:
                            (context, i) => _tileFromDevice(_paired[i]),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
