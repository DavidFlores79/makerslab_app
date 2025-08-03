import '../../../../core/entities/balance.dart';
import '../../../../core/entities/main_menu_item.dart';

abstract class HomeLocalDatasource {
  // Future<List<Remittance>> getRemittances();
  Future<Balance> getBalance();
  Future<List<MainMenuItem>> getMainMenu();
}
