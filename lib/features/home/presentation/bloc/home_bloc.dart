import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_home_menu.dart';

import '../../domain/usecases/get_balance.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetBalance getBalance;
  final GetHomeMenu getHomeMenuItems;

  HomeBloc({required this.getBalance, required this.getHomeMenuItems})
    : super(HomeState()) {
    on<LoadHomeData>(_onLoad);
  }

  Future<void> _onLoad(LoadHomeData event, Emitter<HomeState> emit) async {
    print('Cargando datos...');
    emit(state.copyWith(status: HomeStatus.loading));
    final balRes = await getBalance();
    final homeMenuRes = await getHomeMenuItems();

    print('Res balance: $balRes, Items: $homeMenuRes');

    balRes.fold(
      (f) => emit(state.copyWith(status: HomeStatus.failure, error: f.message)),
      (b) {
        homeMenuRes.fold(
          (f) => emit(
            state.copyWith(status: HomeStatus.failure, error: f.message),
          ),
          (r) => emit(
            state.copyWith(
              status: HomeStatus.success,
              balance: b,
              mainMenuItems: r,
            ),
          ),
        );
      },
    );
  }
}
