// lib/features/onboarding/notifier/onboarding_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';
import '../../../core/storage/storage_service.dart';
import 'onboarding_state.dart'; // Add this import

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this.ref) : super(OnboardingState());
  final Ref ref; // Add Ref to access providers

  final pageController = PageController();

  void updatePageIndicator(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void dotNavigationClick(int index) {
    state = state.copyWith(currentIndex: index);
    pageController.jumpToPage(index);
  }

  Future<void> nextPage(BuildContext context) async {
    if (state.currentIndex == 2) {
      // Use storageServiceProvider instead of direct SharedPreferences
      final storageService = ref.read(storageServiceProvider);
      await storageService.setOnboardingSeen(true);

      // Navigate to sign-in screen
      context.go(Routes.signIn);
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      pageController.jumpToPage(state.currentIndex);
    }
  }

  void skipPage() {
    state = state.copyWith(currentIndex: 2);
    pageController.jumpToPage(state.currentIndex);
  }
}

// Update provider to pass ref
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(ref); // Pass ref to the notifier
    });
