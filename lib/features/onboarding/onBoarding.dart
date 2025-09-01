// lib/features/authentication/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspection/features/onboarding/screens/OnBoardingNextButton.dart';
import 'package:inspection/features/onboarding/screens/onBoarding_skip_button.dart';
import 'package:inspection/features/onboarding/screens/onboarding_dot_navigation.dart';
import 'package:inspection/features/onboarding/screens/onboarding_page.dart';

import '../../utils/constants/images.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/texts.dart';
import '../../utils/helpers/device_helpers.dart';
import '../../utils/helpers/helper_function.dart';
import 'notifier/onboarding_notifier.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingNotifierProvider.notifier);
    final state = ref.watch(onboardingNotifierProvider);

    // Use shared helper to decide styles + system overlays
    final isDark = UHelperFunctions.isDarkMode(context);
    final overlay = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    // Apply status bar style via DeviceHelper (your utils)
    UDeviceHelper.setStatusBarColor(Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: GestureDetector(
        // Shared “any screen” behavior: tap anywhere to dismiss keyboard
        onTap: () => UDeviceHelper.hideKeyboard(context),
        child: Scaffold(
          // Prefer themed background; if you want strict util colors, uncomment:
          // backgroundColor: isDark ? UColors.dark : UColors.light,
          body: SafeArea(
            // Your utils.sizes doesn’t define `defaultSpace`, use md/lg consistently
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
              child: Stack(
                children: [
                  // PageView for Onboarding Screens
                  PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.updatePageIndicator,
                    children: const [
                      OnBoardingPage(
                        animation: UImages.onboarding1Animation,
                        title: UTexts.onBoardingTitle1,
                        subtitle: UTexts.onBoardingSubTitle1,
                      ),
                      OnBoardingPage(
                        animation: UImages.onboarding2Animation,
                        title: UTexts.onBoardingTitle2,
                        subtitle: UTexts.onBoardingSubTitle2,
                      ),
                      OnBoardingPage(
                        animation: UImages.onboarding3Animation,
                        title: UTexts.onBoardingTitle3,
                        subtitle: UTexts.onBoardingSubTitle3,
                      ),
                    ],
                  ),

                  // Indicator (Smooth Page Indicator)
                  const OnBoardingDotNavigation(),

                  // Next Button (Trigger the next page or finish the onboarding)
                  const OnBoardingNextButton(),

                  // Skip Button (Skip to the last page)
                  const OnBoardingSkipButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
