// lib/app/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/app/router/root_nav_key.dart';
import 'package:inspection/app/router/routes.dart';

import '../../features/onboarding/onBoarding.dart';
import '../../features/profile/profile.dart';
import '../../features/question/question.dart';
import '../../features/result/result.dart';
import '../../features/signin/signin.dart';
import '../../features/site/site_location.dart';
import '../../features/verify_otp/otp_verify.dart';
import '../../navigation_menu.dart';
import '../screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash', // Must start with /
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/splash', // Must start with /
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding', // Must start with /
        name: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // In your app_router.dart, change the path to match Routes.signIn
      GoRoute(
        path: '/signin', // Add hyphen to match Routes.signIn
        name: Routes.signIn,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.siteLocation, // '/site-location'
        name: Routes.siteLocation,
        builder: (context, state) => const SiteLocation(isSelectionMode: true),
      ),
      GoRoute(
        path: '/otp-verify', // Must start with /
        name: Routes.otpVerify,
        builder: (context, state) {
          final phoneNumber = state.queryParams['phoneNumber'] ?? '';
          final otp = state.queryParams['otp'];
          return OtpVerifyScreen(phoneNumber: phoneNumber, otp: otp);
        },
      ),
      GoRoute(
        path: '/home', // Must start with /
        name: Routes.home,
        builder: (context, state) => const NavigationMenu(),
      ),
      GoRoute(
        path: Routes.question,
        name: Routes.question,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuestionScreen(
            surveyData: extra['survey_data'] ?? {},
            siteCode: extra['site_code'] ?? '',
          );
        },
      ),
      // In your app_router.dart, the result route should look like this:
      // lib/app/router/app_router.dart
      // In your result route builder
      GoRoute(
        path: '/result',
        name: Routes.result,
        builder: (context, state) {
          final responseIdString = state.queryParams['responseId'];
          final responseId = responseIdString != null
              ? int.tryParse(responseIdString)
              : null;

          print('🔄 Navigating to result screen with responseId: $responseId');

          if (responseId == null || responseId == 0) {
            // If invalid response ID, go back to home and show error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.goNamed(Routes.home);
              // You could show a snackbar or dialog here if needed
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return ResultScreen(responseId: responseId);
        },
      ),
      GoRoute(
        path: '/profile', // Must start with /
        name: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
