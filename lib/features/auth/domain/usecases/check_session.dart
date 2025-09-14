import '../repositories/auth_repository.dart';

class CheckSession {
  final AuthRepository repository;

  CheckSession({required this.repository});

  Future<bool> call() async {
    return await repository.hasTokenStored();
  }
}
