// lib/features/authentication/notifiers/onboarding/onboarding_state.dart
class OnboardingState {
  final int currentIndex;

  OnboardingState({this.currentIndex = 0});

  bool get isLastPage => currentIndex == 2;

  OnboardingState copyWith({int? currentIndex}) {
    return OnboardingState(currentIndex: currentIndex ?? this.currentIndex);
  }
}
