import '../../../../core/domain/entities/main_menu_item.dart';

abstract class HomeLocalDatasource {
  Future<List<MainMenuItem>> getMainMenu();
}
