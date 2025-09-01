
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/helpers/device_helpers.dart';
import '../notifier/onboarding_notifier.dart';

class OnBoardingSkipButton extends ConsumerWidget {
  const OnBoardingSkipButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return onboardingState.isLastPage
        ? const SizedBox()
        : Positioned(
            top: UDeviceHelper.getAppBarHeight(),
            right: 0,
            child: TextButton(
              onPressed: () {
                ref.read(onboardingNotifierProvider.notifier).skipPage();
              },
              child: const Text("Skip"),
            ),
          );
  }
}
