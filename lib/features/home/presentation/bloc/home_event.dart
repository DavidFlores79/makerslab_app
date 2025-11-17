abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

class LoadRemoteMenuItems extends HomeEvent {}

class LoadModuleDetail extends HomeEvent {
  final String moduleId;

  LoadModuleDetail({required this.moduleId});
}

class LoadAllModuleDetails extends HomeEvent {}

class ClearModuleDetailCache extends HomeEvent {}
