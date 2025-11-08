import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/domain/usecases/check_session.dart';
import '../../data/models/main_menu_item_model.dart';
import '../repositories/home_repository.dart';

/// Use case that combines local and remote menu items
/// Only fetches remote items if user is authenticated
class GetCombinedMenu {
  final HomeRepository homeRepository;
  final CheckSession checkSession;

  GetCombinedMenu({required this.homeRepository, required this.checkSession});

  Future<Either<Failure, List<MainMenuItemModel>>> call() async {
    // 1. Always get local menu first
    final localMenuResult = await homeRepository.getMainMenu();

    return await localMenuResult.fold((failure) => Left(failure), (
      localMenu,
    ) async {
      // 2. Check if user is authenticated
      final isAuthenticated = await checkSession();

      // 3. If not authenticated, return only local menu
      if (!isAuthenticated) {
        return Right(localMenu);
      }

      // 4. If authenticated, fetch and combine with remote menu
      final remoteMenuResult = await homeRepository.getRemoteMenuItems();

      return remoteMenuResult.fold(
        // If remote fails, still return local menu (graceful degradation)
        (failure) => Right(localMenu),
        (remoteMenu) => Right([...localMenu, ...remoteMenu]),
      );
    });
  }
}
