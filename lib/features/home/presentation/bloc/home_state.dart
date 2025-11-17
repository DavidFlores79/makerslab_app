import '../../data/models/main_menu_item_model.dart';
import '../../domain/entities/module_detail.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<MainMenuItemModel>? mainMenuItems;
  final String? error;
  final Map<String, ModuleDetail> moduleDetails;
  final bool isLoadingModuleDetails;
  final String? moduleDetailError;

  HomeState({
    this.status = HomeStatus.initial,
    this.mainMenuItems,
    this.error,
    this.moduleDetails = const {},
    this.isLoadingModuleDetails = false,
    this.moduleDetailError,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<MainMenuItemModel>? mainMenuItems,
    String? error,
    Map<String, ModuleDetail>? moduleDetails,
    bool? isLoadingModuleDetails,
    String? moduleDetailError,
  }) => HomeState(
    status: status ?? this.status,
    mainMenuItems: mainMenuItems ?? this.mainMenuItems,
    error: error ?? this.error,
    moduleDetails: moduleDetails ?? this.moduleDetails,
    isLoadingModuleDetails:
        isLoadingModuleDetails ?? this.isLoadingModuleDetails,
    moduleDetailError: moduleDetailError ?? this.moduleDetailError,
  );

  ModuleDetail? getModuleDetail(String moduleId) {
    return moduleDetails[moduleId];
  }
}
