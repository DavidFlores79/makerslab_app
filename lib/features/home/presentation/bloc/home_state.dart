import '../../../../core/entities/balance.dart';
import '../../../../core/entities/main_menu_item.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final Balance? balance;
  final List<MainMenuItem>? mainMenuItems;
  final String? error;

  HomeState({
    this.status = HomeStatus.initial,
    this.balance,
    this.mainMenuItems,
    this.error,
  });

  HomeState copyWith({
    HomeStatus? status,
    Balance? balance,
    List<MainMenuItem>? mainMenuItems,
    String? error,
  }) => HomeState(
    status: status ?? this.status,
    balance: balance ?? this.balance,
    mainMenuItems: mainMenuItems ?? this.mainMenuItems,
    error: error ?? this.error,
  );
}
