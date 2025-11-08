import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final SharedPreferences sharedPreferences;
  final _key = 'onboarding_is_completed';

  OnboardingRepositoryImpl({required this.sharedPreferences});

  @override
  Future<void> markAsCompleted() async {
    await sharedPreferences.setBool(_key, true);
  }

  @override
  Future<bool> isCompleted() {
    final value = sharedPreferences.getBool(_key) ?? false;
    return Future.value(value);
  }
}
