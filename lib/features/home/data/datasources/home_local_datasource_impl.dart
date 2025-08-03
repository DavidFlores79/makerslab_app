import 'package:community_material_icon/community_material_icon.dart';
import 'package:logger/logger.dart';
import 'package:makerslab_app/core/entities/main_menu_item.dart';

import '../../../../core/entities/balance.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../theme/app_color.dart';
import '../../../gamepad/presentation/pages/gamepad_page.dart';
import 'home_local_datasource.dart';

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final Logger logger;

  HomeLocalDatasourceImpl({required this.logger});

  @override
  Future<Balance> getBalance() async {
    try {
      // Mock data
      await Future.delayed(const Duration(milliseconds: 200));
      logger.i("Obteniendo balance localmente...");
      return Balance(amount: 26500.00, currency: 'MXN');
    } catch (e, stackTrace) {
      logger.e('Error getting local balance', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener balance local', stackTrace);
    }
  }

  @override
  Future<List<MainMenuItem>> getMainMenu() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      logger.i("Obteniendo menu localmente...");
      return mainMenu;
    } catch (e, stackTrace) {
      logger.e('Error getting local balance', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener balance local', stackTrace);
    }
  }

  // @override
  // Future<List<Remittance>> getRemittances() async {
  //   try {
  //     // Mock data - puedes reemplazar esto con datos reales de SharedPreferences si lo necesitas
  //     await Future.delayed(
  //       const Duration(milliseconds: 300),
  //     ); // Simular delay de base de datos

  //     final mockRemittances = [
  //       Remittance(
  //         id: '1',
  //         senderName: 'Carlos Hernández',
  //         amount: 500.00,
  //         date: DateTime.now().subtract(const Duration(hours: 2)),
  //         status: 'Completada',
  //       ),
  //       Remittance(
  //         id: '2',
  //         senderName: 'Ana Martínez',
  //         amount: 750.00,
  //         date: DateTime.now().subtract(const Duration(days: 1)),
  //         status: 'Completada',
  //       ),
  //       Remittance(
  //         id: '3',
  //         senderName: 'Luis Rodríguez',
  //         amount: 1200.00,
  //         date: DateTime.now().subtract(const Duration(days: 3)),
  //         status: 'Completada',
  //       ),
  //       Remittance(
  //         id: '4',
  //         senderName: 'Carlos Hernández',
  //         amount: 1600.00,
  //         date: DateTime.now().subtract(const Duration(days: 2)),
  //         status: 'Completada',
  //       ),
  //       Remittance(
  //         id: '5',
  //         senderName: 'Luis Rodríguez',
  //         amount: 8500.00,
  //         date: DateTime.now().subtract(const Duration(days: 6, hours: 10)),
  //         status: 'Completada',
  //       ),
  //       Remittance(
  //         id: '6',
  //         senderName: 'Carlos Hernández',
  //         amount: 5000.00,
  //         date: DateTime.now().subtract(const Duration(days: 12)),
  //         status: 'Completada',
  //       ),
  //     ];
  //     logger.i("Obteniendo remesas locales...");
  //     return mockRemittances;
  //   } catch (e, stackTrace) {
  //     logger.e(
  //       'Error getting local remittances',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //     throw CacheException('Error al obtener remesas locales', stackTrace);
  //   }
  // }

  final List<MainMenuItem> mainMenu = [
    MainMenuItem(
      CommunityMaterialIcons.controller_classic_outline,
      'Gamepad',
      GamepadPage.routeName,
      AppColors.lightGreen,
    ),
    // MainMenuItem(
    //   CommunityMaterialIcons.thermometer_low,
    //   'Sensor DHT',
    //   TemperaturePage.routeName,
    //   AppColors.blue,
    // ),
    // MainMenuItem(
    //   CommunityMaterialIcons.robot_industrial,
    //   'Servos',
    //   ServoPage.routeName,
    //   AppColors.red,
    // ),
    // MainMenuItem(
    //   CommunityMaterialIcons.light_switch,
    //   'Control de Luces',
    //   LightControlPage.routeName,
    //   AppColors.orange,
    // ),
    // MainMenuItem(
    //   CommunityMaterialIcons.chat_processing_outline,
    //   'Chat',
    //   ChatPage.routeName,
    //   AppColors.purple,
    // ),
  ];
}
