abstract class OnboardingRepository {
  Future<void> markAsCompleted();
  Future<bool> isCompleted();
}
