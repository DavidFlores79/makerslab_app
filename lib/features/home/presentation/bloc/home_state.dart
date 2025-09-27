import '../../../../core/entities/main_menu_item.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<MainMenuItem>? mainMenuItems;
  final String? error;

  HomeState({this.status = HomeStatus.initial, this.mainMenuItems, this.error});

  HomeState copyWith({
    HomeStatus? status,
    List<MainMenuItem>? mainMenuItems,
    String? error,
  }) => HomeState(
    status: status ?? this.status,
    mainMenuItems: mainMenuItems ?? this.mainMenuItems,
    error: error ?? this.error,
  );
}
