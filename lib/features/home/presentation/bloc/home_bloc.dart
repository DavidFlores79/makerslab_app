import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_combined_menu.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCombinedMenu getCombinedMenu;

  HomeBloc({required this.getCombinedMenu}) : super(HomeState()) {
    on<LoadHomeData>(_onLoad);
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
}
