// lib/app/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_service.dart';
import '../../utils/constants/token_storage.dart';
import '../../utils/helpers/update_checker.dart';
import '../router/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  // COMBINE BOTH INITIALIZATION AND AUTH CHECK
  Future<void> _checkAuthAndNavigate() async {
    final storageService = ref.read(storageServiceProvider);
    final updateChecker = ref.read(updateCheckerProvider);

    // Check for updates first
    await updateChecker.checkForUpdates();

    // Add a proper delay for splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Check token directly
      final token = await TokenStorage.getToken();
      final isLoggedIn = token != null && token.isNotEmpty;

      final seenOnboarding = storageService.onboardingSeen;
      final rememberMeEnabled = storageService.rememberMe;

      if (!context.mounted) return;

      print('Auth check - Token: ${token != null ? "EXISTS" : "MISSING"}');
      print('Auth check - Onboarding seen: $seenOnboarding');
      print('Auth check - Remember me: $rememberMeEnabled');

      if (!seenOnboarding) {
        print('Navigating to onboarding');
        context.go(Routes.onboarding);
      } else if (isLoggedIn) {
        print('Navigating to home (user is logged in)');
        context.go(Routes.home);
      } else if (rememberMeEnabled) {
        // Remember me is enabled but no token - this shouldn't happen
        print('Remember me enabled but no token found. Clearing preference.');
        await storageService.setRememberMe(false);
        context.go(Routes.signIn);
      } else {
        print('Navigating to signin (user is not logged in)');
        context.go(Routes.signIn);
      }
    } catch (error) {
      print('Error in splash navigation: $error');
      if (!context.mounted) return;
      print('Fallback: Navigating to signin due to error');
      context.go(Routes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your custom logo
            Image.asset(
              'assets/icons/circleIcon.png',
              width: 100, // Adjust size as needed
              height: 100, // Adjust size as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}