import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/module_detail.dart';
import '../../domain/usecases/get_all_module_details.dart';
import '../../domain/usecases/get_combined_menu.dart';
import '../../domain/usecases/get_module_detail.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCombinedMenu getCombinedMenu;
  final GetModuleDetail getModuleDetail;
  final GetAllModuleDetails getAllModuleDetails;

  HomeBloc({
    required this.getCombinedMenu,
    required this.getModuleDetail,
    required this.getAllModuleDetails,
  }) : super(HomeState()) {
    on<LoadHomeData>(_onLoad);
    on<LoadModuleDetail>(_onLoadModuleDetail);
    on<LoadAllModuleDetails>(_onLoadAllModuleDetails);
    on<ClearModuleDetailCache>(_onClearModuleDetailCache);
  }

  Future<void> _onLoad(LoadHomeData event, Emitter<HomeState> emit) async {
    debugPrint('Loading home data...');
    emit(state.copyWith(status: HomeStatus.loading));

    final result = await getCombinedMenu();

    result.fold(
      (failure) => emit(
        state.copyWith(status: HomeStatus.failure, error: failure.message),
      ),
      (menuItems) => emit(
        state.copyWith(status: HomeStatus.success, mainMenuItems: menuItems),
      ),
    );
  }

  Future<void> _onLoadModuleDetail(
    LoadModuleDetail event,
    Emitter<HomeState> emit,
  ) async {
    // Check if already loaded (caching)
    if (state.moduleDetails.containsKey(event.moduleId)) {
      return; // Already cached, no need to reload
    }

    emit(state.copyWith(isLoadingModuleDetails: true));

    final result = await getModuleDetail(event.moduleId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingModuleDetails: false,
          moduleDetailError: failure.message,
        ),
      ),
      (detail) {
        final updatedDetails = Map<String, ModuleDetail>.from(
          state.moduleDetails,
        );
        updatedDetails[event.moduleId] = detail;

        emit(
          state.copyWith(
            isLoadingModuleDetails: false,
            moduleDetails: updatedDetails,
            moduleDetailError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadAllModuleDetails(
    LoadAllModuleDetails event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoadingModuleDetails: true));

    final result = await getAllModuleDetails();

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingModuleDetails: false,
          moduleDetailError: failure.message,
        ),
      ),
      (details) {
        final detailsMap = <String, ModuleDetail>{};
        for (final detail in details) {
          detailsMap[detail.id] = detail;
        }

        emit(
          state.copyWith(
            isLoadingModuleDetails: false,
            moduleDetails: detailsMap,
            moduleDetailError: null,
          ),
        );
      },
    );
  }

  Future<void> _onClearModuleDetailCache(
    ClearModuleDetailCache event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(moduleDetails: const {}));
  }
}
