// flutter_bluetooth_page_v3.dart
// Updated single-file example. Fixes flutter_bluetooth_classic_serial API usage
// (use BluetoothData.data and track connection state) and keeps previous BLE fixes.

/*
  Pubspec (add these deps with the shown versions):

  dependencies:
    flutter:
      sdk: flutter
    flutter_bloc: ^9.1.1
    bloc: ^9.0.0
    flutter_reactive_ble: ^5.4.0      # for BLE (ESP32 BLE)
    flutter_bluetooth_classic_serial: ^1.0.3  # for Bluetooth Classic (HC-05)

    # pinned to be compatible with Flutter 3.29.3
    syncfusion_flutter_core: ^29.1.33
    syncfusion_flutter_gauges: ^29.1.33

    permission_handler: ^12.0.1  # for runtime permissions (optional but recommended)

  NOTE: Syncfusion packages require a license (commercial or community). See Syncfusion docs.

  Platform setup (high level):
   - Android: add BLUETOOTH_SCAN / BLUETOOTH_CONNECT etc. per the BLE / Classic package docs.
   - iOS: add NSBluetoothAlwaysUsageDescription / NSBluetoothPeripheralUsageDescription to Info.plist.

  This single file intentionally keeps implementations compact and educational.
  In production split into domain/data/presentation layers, add tests and error handling.
*/

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

// BLE
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// Classic
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

// ---------------------------
// Models (no equatable)
// ---------------------------
class SimpleBtDevice {
  final String id; // BLE: id, Classic: address
  final String name;
  final bool isBle;

  const SimpleBtDevice({
    required this.id,
    required this.name,
    required this.isBle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimpleBtDevice && other.id == id && other.isBle == isBle);

  @override
  int get hashCode => Object.hash(id, isBle);
}

// ---------------------------
// Repository abstraction (domain)
// ---------------------------
abstract class IBluetoothRepository {
  /// Stream of discovered devices (distinct by id)
  Stream<List<SimpleBtDevice>> scan({
    Duration timeout = const Duration(seconds: 5),
  });

  Future<void> connect(SimpleBtDevice device);
  Future<void> disconnect();

  /// Stream of raw incoming bytes from the connected device
  Stream<Uint8List> incoming();

  Future<void> write(Uint8List bytes);

  Future<bool> isConnected();
}

// ---------------------------
// BLE implementation (flutter_reactive_ble)
// NOTE: for BLE you need to know the Service UUID & Characteristic UUIDs used by your ESP32
// ---------------------------
class BleRepository implements IBluetoothRepository {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Uuid serviceUuid;
  final Uuid characteristicUuid;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<List<SimpleBtDevice>> _scanController =
      StreamController.broadcast();
  final StreamController<Uint8List> _incomingController =
      StreamController.broadcast();

  String? _connectedId;

  BleRepository({required this.serviceUuid, required this.characteristicUuid});

  @override
  Stream<List<SimpleBtDevice>> scan({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final Map<String, SimpleBtDevice> found = {};

    _scanSub?.cancel();
    _scanSub = _ble
        .scanForDevices(withServices: [])
        .listen(
          (device) {
            // you can filter by device.name or by advertised services
            found[device.id] = SimpleBtDevice(
              id: device.id,
              name: device.name.isNotEmpty ? device.name : device.id,
              isBle: true,
            );
            _scanController.add(found.values.toList());
          },
          onError: (e) {
            // push empty or ignore
          },
        );

    // stop scanning after timeout
    Future.delayed(timeout, () => _scanSub?.cancel());

    return _scanController.stream;
  }

  @override
  Future<void> connect(SimpleBtDevice device) async {
    await disconnect();

    // connectToDevice returns a stream of ConnectionStateUpdate
    _connSub = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (event) async {
            if (event.connectionState == DeviceConnectionState.connected) {
              _connectedId = device.id;
              // subscribe to notifications on the chosen characteristic
              final qChar = QualifiedCharacteristic(
                serviceId: serviceUuid,
                characteristicId: characteristicUuid,
                deviceId: device.id,
              );
              _notifySub = _ble
                  .subscribeToCharacteristic(qChar)
                  .listen(
                    (data) {
                      _incomingController.add(Uint8List.fromList(data));
                    },
                    onError: (e) {
                      // Notification error
                    },
                  );
            }
          },
          onError: (e) {
            // connection error
          },
        );
  }

  @override
  Future<void> disconnect() async {
    // Cancel notification subscription
    await _notifySub?.cancel();
    _notifySub = null;

    // Cancel the connection subscription which will close the connection stream.
    // In flutter_reactive_ble the recommended way to stop is to cancel the subscription returned by connectToDevice.
    await _connSub?.cancel();
    _connSub = null;

    _connectedId = null;
  }

  @override
  Stream<Uint8List> incoming() => _incomingController.stream;

  @override
  Future<void> write(Uint8List bytes) async {
    if (_connectedId == null) throw Exception('Not connected');
    final qChar = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: _connectedId!,
    );
    await _ble.writeCharacteristicWithResponse(qChar, value: bytes.toList());
  }

  @override
  Future<bool> isConnected() async => _connectedId != null;
}

// ---------------------------
// Classic implementation (flutter_bluetooth_classic_serial)
// Works with HC-05 and other classic SPP devices
// ---------------------------
class ClassicRepository implements IBluetoothRepository {
  final FlutterBluetoothClassic _classic = FlutterBluetoothClassic();
  StreamSubscription<BluetoothData>? _dataSub;
  String? _connectedAddress; // track connected device address

  final StreamController<List<SimpleBtDevice>> _scanController =
      StreamController.broadcast();
  final StreamController<Uint8List> _incomingController =
      StreamController.broadcast();

  @override
  Stream<List<SimpleBtDevice>> scan({
    Duration timeout = const Duration(seconds: 5),
  }) {
    // this package exposes getPairedDevices & startDiscovery; we'll fetch paired + discovered devices
    Future.microtask(() async {
      try {
        final paired = await _classic.getPairedDevices();
        final list = <SimpleBtDevice>[];
        for (var d in paired) {
          list.add(
            SimpleBtDevice(
              id: d.address,
              name: d.name ?? d.address,
              isBle: false,
            ),
          );
        }
        _scanController.add(list);
        // start discovery (non-blocking)
        await _classic.startDiscovery();
        // the package has an internal discovery mechanism; for simplicity we re-query paired after a moment
        await Future.delayed(const Duration(seconds: 3));
        final paired2 = await _classic.getPairedDevices();
        final dedup = {
          for (var d in paired2)
            d.address: SimpleBtDevice(
              id: d.address,
              name: d.name ?? d.address,
              isBle: false,
            ),
        };
        _scanController.add(dedup.values.toList());
      } catch (e) {
        _scanController.add([]);
      }
    });

    return _scanController.stream;
  }

  @override
  Future<void> connect(SimpleBtDevice device) async {
    await disconnect();
    try {
      final ok = await _classic.connect(device.id);
      if (!ok) throw Exception('Connect failed');
      // mark connected address
      _connectedAddress = device.id;
      // listen for incoming
      _dataSub = _classic.onDataReceived.listen((BluetoothData d) {
        // BluetoothData has fields: data (List<int>) and asString()
        final bytes = Uint8List.fromList(d.data);
        _incomingController.add(bytes);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _dataSub?.cancel();
    _dataSub = null;
    try {
      await _classic.disconnect();
    } catch (_) {}
    _connectedAddress = null;
  }

  @override
  Stream<Uint8List> incoming() => _incomingController.stream;

  @override
  Future<void> write(Uint8List bytes) async {
    await _classic.sendData(bytes.toList());
  }

  @override
  Future<bool> isConnected() async => _connectedAddress != null;
}

// ---------------------------
// Bloc (presentation) - without equatable
// ---------------------------

enum BluetoothStatus { idle, scanning, connecting, connected, error }

abstract class BluetoothEvent {}

class StartScanEvent extends BluetoothEvent {
  final Duration timeout;
  StartScanEvent({this.timeout = const Duration(seconds: 5)});
}

class ConnectDeviceEvent extends BluetoothEvent {
  final SimpleBtDevice device;
  ConnectDeviceEvent(this.device);
}

class DisconnectEvent extends BluetoothEvent {}

class SendDataEvent extends BluetoothEvent {
  final Uint8List bytes;
  SendDataEvent(this.bytes);
}

class _IncomingBytesEvent extends BluetoothEvent {
  final Uint8List bytes;
  _IncomingBytesEvent(this.bytes);
}

class BluetoothState {
  final BluetoothStatus status;
  final List<SimpleBtDevice> devices;
  final SimpleBtDevice? connectedDevice;
  final double? temperature; // parsed temperature if available
  final List<String> logs;
  final String? errorMessage;

  const BluetoothState({
    this.status = BluetoothStatus.idle,
    this.devices = const [],
    this.connectedDevice,
    this.temperature,
    this.logs = const [],
    this.errorMessage,
  });

  BluetoothState copyWith({
    BluetoothStatus? status,
    List<SimpleBtDevice>? devices,
    SimpleBtDevice? connectedDevice,
    double? temperature,
    List<String>? logs,
    String? errorMessage,
  }) {
    return BluetoothState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      temperature: temperature ?? this.temperature,
      logs: logs ?? this.logs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final IBluetoothRepository repository;

  StreamSubscription<List<SimpleBtDevice>>? _scanSub;
  StreamSubscription<Uint8List>? _incomingSub;

  BluetoothBloc({required this.repository}) : super(const BluetoothState()) {
    on<StartScanEvent>(_onStartScan);
    on<ConnectDeviceEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<SendDataEvent>(_onSend);
    on<_IncomingBytesEvent>(_onIncomingBytes);

    // passive incoming listener (when connected)
    _incomingSub = repository.incoming().listen((bytes) {
      add(_IncomingBytesEvent(bytes));
    });
  }

  Future<void> _onStartScan(
    StartScanEvent ev,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(status: BluetoothStatus.scanning, devices: []));
    try {
      _scanSub?.cancel();
      _scanSub = repository.scan(timeout: ev.timeout).listen((list) {
        emit(state.copyWith(devices: list));
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: BluetoothStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConnect(
    ConnectDeviceEvent ev,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(status: BluetoothStatus.connecting));
    try {
      await repository.connect(ev.device);
      emit(
        state.copyWith(
          status: BluetoothStatus.connected,
          connectedDevice: ev.device,
          logs: List.from(state.logs)..add('Connected to ${ev.device.name}'),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BluetoothStatus.error,
          errorMessage: e.toString(),
          logs: List.from(state.logs)..add('Connect error: $e'),
        ),
      );
    }
  }

  Future<void> _onDisconnect(
    DisconnectEvent ev,
    Emitter<BluetoothState> emit,
  ) async {
    await repository.disconnect();
    emit(
      state.copyWith(
        status: BluetoothStatus.idle,
        connectedDevice: null,
        logs: List.from(state.logs)..add('Disconnected'),
      ),
    );
  }

  Future<void> _onSend(SendDataEvent ev, Emitter<BluetoothState> emit) async {
    try {
      await repository.write(ev.bytes);
      emit(
        state.copyWith(
          logs: List.from(state.logs)..add('Sent ${ev.bytes.length} bytes'),
        ),
      );
    } catch (e) {
      emit(state.copyWith(logs: List.from(state.logs)..add('Send error: $e')));
    }
  }

  Future<void> _onIncomingBytes(
    _IncomingBytesEvent ev,
    Emitter<BluetoothState> emit,
  ) async {
    final text = _tryDecodeAscii(ev.bytes);
    final parsed = _tryParseTemperature(text);
    final logs = List<String>.from(state.logs)..add('RX: $text');
    emit(state.copyWith(temperature: parsed ?? state.temperature, logs: logs));
  }

  @override
  Future<void> close() async {
    await _scanSub?.cancel();
    await _incomingSub?.cancel();
    await repository.disconnect();
    return super.close();
  }

  String _tryDecodeAscii(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (e) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return bytes.map((b) => b.toString()).join(',');
      }
    }
  }

  double? _tryParseTemperature(String s) {
    // try to find a float-like pattern in the incoming text: e.g. "T:25.4" or just "25.4"
    final reg = RegExp(r"([-+]?[0-9]*\.?[0-9]+)");
    final m = reg.firstMatch(s);
    if (m != null) {
      return double.tryParse(m.group(0)!);
    }
    return null;
  }
}

// ---------------------------
// UI: BluetoothPage + reusable widgets
// ---------------------------

class TemperatureInterfacePage extends StatelessWidget {
  static const String routeName = '/temperature-interface';
  final IBluetoothRepository repository;

  const TemperatureInterfacePage({Key? key, required this.repository})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (context) => BluetoothBloc(repository: repository),
        child: const _BluetoothView(),
      ),
    );
  }
}

class _BluetoothView extends StatefulWidget {
  const _BluetoothView({Key? key}) : super(key: key);

  @override
  State<_BluetoothView> createState() => _BluetoothViewState();
}

class _BluetoothViewState extends State<_BluetoothView> {
  final TextEditingController _sendController = TextEditingController();

  @override
  void dispose() {
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BluetoothBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth (BLE / Classic) — Temperature'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bloc.add(StartScanEvent()),
            tooltip: 'Scan devices',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Central gauge widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: BlocBuilder<BluetoothBloc, BluetoothState>(
                buildWhen:
                    (p, c) =>
                        p.temperature != c.temperature || p.status != c.status,
                builder: (context, state) {
                  return TemperatureGaugeWidget(
                    temperature: state.temperature ?? 0.0,
                    connected: state.status == BluetoothStatus.connected,
                    label: state.connectedDevice?.name ?? 'No device',
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Devices list & connect buttons
            Expanded(
              child: BlocBuilder<BluetoothBloc, BluetoothState>(
                buildWhen:
                    (p, c) =>
                        p.devices != c.devices ||
                        p.status != c.status ||
                        p.connectedDevice != c.connectedDevice,
                builder: (context, state) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Text('Status: ${state.status.name}'),
                            const Spacer(),
                            if (state.connectedDevice != null)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.link_off),
                                label: const Text('Disconnect'),
                                onPressed:
                                    () => context.read<BluetoothBloc>().add(
                                      DisconnectEvent(),
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.devices.length,
                          itemBuilder: (context, i) {
                            final d = state.devices[i];
                            final connected = state.connectedDevice?.id == d.id;
                            return ListTile(
                              title: Text(d.name),
                              subtitle: Text(d.id),
                              trailing:
                                  connected
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                      : ElevatedButton(
                                        child: const Text('Connect'),
                                        onPressed:
                                            () => context
                                                .read<BluetoothBloc>()
                                                .add(ConnectDeviceEvent(d)),
                                      ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Send input + logs
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sendController,
                          decoration: const InputDecoration(
                            hintText:
                                'Send text to device (e.g. "T?" or "ping")',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final txt = _sendController.text;
                          if (txt.isNotEmpty) {
                            context.read<BluetoothBloc>().add(
                              SendDataEvent(
                                Uint8List.fromList(utf8.encode(txt + '\n')),
                              ),
                            );
                            _sendController.clear();
                          }
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: BlocBuilder<BluetoothBloc, BluetoothState>(
                      builder: (context, state) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            children:
                                state.logs.reversed
                                    .take(8)
                                    .map(
                                      (l) => Text(
                                        l,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                    .toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<BluetoothBloc>().add(StartScanEvent()),
        icon: const Icon(Icons.search),
        label: const Text('Scan'),
      ),
    );
  }
}

class TemperatureGaugeWidget extends StatelessWidget {
  final double temperature;
  final bool connected;
  final String label;
  const TemperatureGaugeWidget({
    Key? key,
    required this.temperature,
    required this.connected,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // range is 0 - 100 by default; adjust as required
    final value = temperature.clamp(-50.0, 150.0);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: connected ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: -20,
                    maximum: 120,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: -20,
                        endValue: 20,
                        startWidth: 10,
                        endWidth: 10,
                      ),
                      GaugeRange(
                        startValue: 20,
                        endValue: 60,
                        startWidth: 10,
                        endWidth: 10,
                      ),
                      GaugeRange(
                        startValue: 60,
                        endValue: 120,
                        startWidth: 10,
                        endWidth: 10,
                      ),
                    ],
                    pointers: <GaugePointer>[NeedlePointer(value: value)],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          '${temperature.toStringAsFixed(1)} °C',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
