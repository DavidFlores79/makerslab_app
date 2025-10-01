import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../error/failure.dart';
import '../../ui/snackbar_service.dart';
import 'logger_service.dart';

class PermissionService {
  final ILogger logger;

  PermissionService({required this.logger});

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isIOS) {
      // iOS maneja Bluetooth via Info.plist; no runtime request needed
      logger.info('Permisos de Bluetooth no requeridos en runtime para iOS.');
      return true;
    }

    // Para Android: Solo SCAN y CONNECT (asumiendo SDK 31+ con neverForLocation)
    final permissions = [Permission.bluetoothScan, Permission.bluetoothConnect];

    final statuses = await Future.wait(permissions.map((p) => p.status));

    if (statuses.every((status) => status.isGranted)) {
      logger.info('Todos los permisos de Bluetooth ya concedidos.');
      return true;
    }

    if (statuses.any((status) => status.isPermanentlyDenied)) {
      logger.warning(
        'Permisos denegados permanentemente. Redirigiendo a settings.',
      );
      SnackbarService().show(
        message:
            'Permisos denegados. Habilita Bluetooth en settings de la app.',
      );
      await openAppSettings();
      return false;
    }

    logger.info('Pidiendo permisos de Bluetooth...');
    final requestResults = await permissions.request();

    // Log statuses detallados para depuración
    requestResults.forEach((permission, status) {
      logger.info('Permiso $permission: $status');
    });

    if (requestResults.values.every((status) => status.isGranted)) {
      logger.info('Permisos concedidos exitosamente.');
      return true;
    } else {
      logger.error('Permisos denegados por el usuario.');
      throw PermissionFailure(
        'Permisos de Bluetooth denegados. Por favor, habilítalos para escanear dispositivos.',
      );
    }
  }

  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isIOS) return true;

    final granted = await Future.wait([
      Permission.bluetoothScan.isGranted,
      Permission.bluetoothConnect.isGranted,
    ]);
    return granted.every((g) => g);
  }
}
