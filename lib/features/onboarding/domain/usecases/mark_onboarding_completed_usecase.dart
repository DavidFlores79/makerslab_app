import '../repositories/onboarding_repository.dart';

class MarkOnboardingCompletedUseCase {
  final OnboardingRepository repository;

  MarkOnboardingCompletedUseCase(this.repository);

  Future<void> call() async {
    await repository.markAsCompleted();
  }
}
