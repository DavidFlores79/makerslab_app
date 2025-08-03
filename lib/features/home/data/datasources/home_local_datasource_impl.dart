import 'package:community_material_icon/community_material_icon.dart';
import 'package:logger/logger.dart';
import 'package:makerslab_app/core/entities/main_menu_item.dart';

import '../../../../core/entities/balance.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../theme/app_color.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../gamepad/presentation/pages/gamepad_page.dart';
import '../../../light_control/presentation/pages/light_control_page.dart';
import '../../../servo/presentation/pages/servo_page.dart';
import '../../../temperature/presentation/pages/temperature_page.dart';
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

  final List<MainMenuItem> mainMenu = [
    MainMenuItem(
      CommunityMaterialIcons.controller_classic_outline,
      'Gamepad',
      GamepadPage.routeName,
      AppColors.lightGreen,
    ),
    MainMenuItem(
      CommunityMaterialIcons.thermometer_low,
      'Sensor DHT',
      TemperaturePage.routeName,
      AppColors.blue,
    ),
    MainMenuItem(
      CommunityMaterialIcons.robot_industrial,
      'Servos',
      ServoPage.routeName,
      AppColors.red,
    ),
    MainMenuItem(
      CommunityMaterialIcons.light_switch,
      'Control de Luces',
      LightControlPage.routeName,
      AppColors.orange,
    ),
    MainMenuItem(
      CommunityMaterialIcons.chat_processing_outline,
      'Chat',
      ChatPage.routeName,
      AppColors.purple,
    ),
  ];
}
