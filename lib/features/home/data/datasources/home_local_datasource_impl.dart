import 'package:community_material_icon/community_material_icon.dart';
import 'package:makerslab_app/core/domain/entities/main_menu_item.dart';

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../theme/app_color.dart';
import '../../../gamepad/presentation/pages/gamepad_page.dart';
import '../../../light_control/presentation/pages/light_control_page.dart';
import '../../../servo/presentation/pages/servo_page.dart';
import '../../../temperature/presentation/pages/temperature_page.dart';
import 'home_local_datasource.dart';

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final ILogger logger;

  HomeLocalDatasourceImpl({required this.logger});

  @override
  @override
  Future<List<MainMenuItem>> getMainMenu() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      logger.info("Obteniendo menu localmente...");
      return mainMenu;
    } catch (e, stackTrace) {
      logger.error('Error getting local balance', e, stackTrace);
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
  ];
}
