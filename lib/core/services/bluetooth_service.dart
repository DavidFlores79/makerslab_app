// lib/core/services/bluetooth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as btcs;
import '../error/exceptions.dart';

class BluetoothService {
  final btcs.FlutterBluetoothClassic _bt = btcs.FlutterBluetoothClassic();

  Future<List<btcs.BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bt.getPairedDevices();
    } catch (e, st) {
      throw BluetoothException('getPairedDevices failed: $e', st);
    }
  }

  /// Intenta iniciar discovery (devuelve true si se inició correctamente).
  Future<bool> startDiscovery({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final ok = await _bt.startDiscovery();
      // startDiscovery() devuelve bool; el plugin no devuelve la lista por este método.
      // Si quieres ver dispositivos nuevos, normalmente se emparejan desde el sistema y luego
      // debes refrescar getPairedDevices().
      return ok;
    } catch (e, st) {
      throw BluetoothException('startDiscovery failed: $e', st);
    }
  }

  Future<bool> connect(String address) async {
    try {
      debugPrint('Connecting to device **** $address');
      return await _bt.connect(address);
    } catch (e, st) {
      throw BluetoothException('connect failed: $e', st);
    }
  }

  Future<bool> disconnect() async {
    try {
      return await _bt.disconnect();
    } catch (e, st) {
      throw BluetoothException('disconnect failed: $e', st);
    }
  }

  Future<bool> sendString(String msg) async {
    try {
      return await _bt.sendString(msg);
    } catch (e, st) {
      throw BluetoothException('sendString failed: $e', st);
    }
  }

  Stream<btcs.BluetoothData> get onDataReceived => _bt.onDataReceived;
}
