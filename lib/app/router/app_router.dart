// lib/app/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/app/router/root_nav_key.dart';
import 'package:inspection/app/router/routes.dart';
import 'package:inspection/app/router/go_router_refresh.dart';

import '../../features/onboarding/onBoarding.dart';
import '../../features/profile/profile.dart';
import '../../features/profile/provider/user_profile_provider.dart';
import '../../features/question/question.dart';
import '../../features/result/result.dart';
import '../../features/signin/signin.dart';
import '../../features/site/site_location.dart';
import '../../features/verify_otp/otp_verify.dart';
import '../../navigation_menu.dart';
import '../screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/splash',
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/signin',
        name: Routes.signIn,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: Routes.otpVerify,
        builder: (context, state) {
          final phoneNumber = state.queryParams['phoneNumber'] ?? '';
          final otp = state.queryParams['otp'];
          return OtpVerifyScreen(phoneNumber: phoneNumber, otp: otp);
        },
      ),

      // PROTECTED ROUTES - Only accessible when authenticated
      GoRoute(
        path: '/home',
        name: Routes.home,
        builder: (context, state) => const NavigationMenu(), // Changed from pageBuilder to builder
      ),
      GoRoute(
        path: Routes.siteLocation,
        name: Routes.siteLocation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final isSelectionMode = extra['isSelectionMode'] ?? false;
          return SiteLocation(isSelectionMode: isSelectionMode);
        },
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
      GoRoute(
        path: '/result',
        name: Routes.result,
        builder: (context, state) {
          final responseIdString = state.queryParams['responseId'];
          final responseId = responseIdString != null
              ? int.tryParse(responseIdString)
              : null;

          if (responseId == null || responseId == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.goNamed(Routes.home);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return ResultScreen(responseId: responseId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.location;
      final isSplash = location == '/splash';
      final isOnboarding = location == '/onboarding';
      final isLogin = location == '/signin';
      final isOtpVerify = location == '/otp-verify';
      final isSiteLocation = location == '/site-location';

      final isPublicRoute = isSplash || isOnboarding || isLogin || isOtpVerify || isSiteLocation;

      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        return '/signin';
      }

      // If authenticated and trying to access login/splash, redirect to home
      if (isAuthenticated && (isLogin || isSplash)) {
        return '/home';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref.read(isAuthenticatedProvider.notifier).stream),
  );
});