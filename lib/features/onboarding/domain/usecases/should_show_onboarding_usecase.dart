import '../repositories/onboarding_repository.dart';

class ShouldShowOnboardingUseCase {
  final OnboardingRepository repository;

  ShouldShowOnboardingUseCase(this.repository);

  Future<bool> call() async {
    return !(await repository.isCompleted());
  }
}
