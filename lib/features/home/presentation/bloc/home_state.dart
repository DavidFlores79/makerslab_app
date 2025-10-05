import '../../data/models/main_menu_item_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<MainMenuItemModel>? mainMenuItems;
  final String? error;

  HomeState({this.status = HomeStatus.initial, this.mainMenuItems, this.error});

  HomeState copyWith({
    HomeStatus? status,
    List<MainMenuItemModel>? mainMenuItems,
    String? error,
  }) => HomeState(
    status: status ?? this.status,
    mainMenuItems: mainMenuItems ?? this.mainMenuItems,
    error: error ?? this.error,
  );
}
