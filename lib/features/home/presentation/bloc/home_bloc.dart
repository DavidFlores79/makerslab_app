import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_home_menu.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeMenu getHomeMenuItems;

  HomeBloc({required this.getHomeMenuItems}) : super(HomeState()) {
    on<LoadHomeData>(_onLoad);
  }

  Future<void> _onLoad(LoadHomeData event, Emitter<HomeState> emit) async {
    print('Cargando datos...');
    emit(state.copyWith(status: HomeStatus.loading));
    final homeMenuRes = await getHomeMenuItems();

    print('Items: $homeMenuRes');

    homeMenuRes.fold(
      (f) => emit(state.copyWith(status: HomeStatus.failure, error: f.message)),
      (r) => emit(state.copyWith(status: HomeStatus.success, mainMenuItems: r)),
    );
  }
}
