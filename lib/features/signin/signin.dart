// lib/features/authentication/screens/login/login.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/features/signin/widgets/login_form.dart';
import 'package:inspection/features/signin/widgets/login_header.dart';
import 'package:inspection/features/signin/widgets/remember_me.dart';

import '../../app/router/routes.dart';
import '../../common_ui/styles/padding.dart';
import '../../common_ui/widgets/alerts/u_alert.dart';
import '../../common_ui/widgets/button/elevated_button.dart';
import '../../core/storage/storage_service.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/texts.dart';
import '../forget_password/forget_password.dart';
import '../signup/signup.dart';
import 'notifier/login_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String appVersion = '';
  String buildNumber = '';

  // In your LoginScreen, add this to initState or build method
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if remember me was enabled and pre-fill the checkbox
      final storageService = ref.read(storageServiceProvider);
      final rememberMeEnabled = storageService.rememberMe;

      if (rememberMeEnabled) {
        ref.read(loginControllerProvider.notifier).toggleRememberMe(true);
      }
    });
  }

  Future<void> _handleLogin() async {
    final phoneNumber = ref
        .read(loginControllerProvider.notifier)
        .phoneController
        .text
        .trim();
    final password = ref
        .read(loginControllerProvider.notifier)
        .passwordController
        .text
        .trim();

    // Validation
    if (phoneNumber.isEmpty) {
      await UAlert.show(
        title: 'Validation Error',
        message: 'Phone number is required',
        context: context,
      );
      return;
    }

    if (!RegExp(r'^01[3-9][0-9]{8}$').hasMatch(phoneNumber)) {
      await UAlert.show(
        title: 'Validation Error',
        message:
            'Enter a valid 11-digit Bangladeshi phone number starting with 01',
        context: context,
      );
      return;
    }

    if (password.isEmpty) {
      await UAlert.show(
        title: 'Validation Error',
        message: 'Password is required',
        context: context,
      );
      return;
    }

    // If validation passes, call the API
    try {
      await ref.read(loginControllerProvider.notifier).login();
    } catch (e) {
      // Extract meaningful error message from Dio exception
      String errorMessage = 'Login failed. Please try again.';

      if (e.toString().contains('Invalid credentials')) {
        errorMessage =
            'Invalid phone number or password. Please check your credentials.';
      } else if (e.toString().contains('Network is unreachable')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.toString().contains('401')) {
        errorMessage =
            'Invalid credentials. Please check your phone number and password.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      }

      await UAlert.show(
        title: 'Login Failed',
        message: errorMessage,
        context: context,
      );
    }
  }

  void _doNothing() {}

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    // Handle navigation on successful login
    if (loginState.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.home);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: UPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: USizes.spaceBtwSections * 2),
                const Center(
                  child: Image(
                    image: AssetImage('assets/icons/circleIcon.png'),
                    height: 80,
                    width: 80,
                  ),
                ),
                SizedBox(height: USizes.spaceBtwSections * 2.4),
                const ULoginHeader(),
                const SizedBox(height: USizes.spaceBtwSections),
                const ULoginForm(),
                const SizedBox(height: USizes.spaceBtwInputFields / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const URememberMeCheckbox(),
                    TextButton(
                      onPressed: loginState.isLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgetPasswordScreen(),
                              ),
                            ),
                      child: const Text(UTexts.forgetPassword),
                    ),
                  ],
                ),
                const SizedBox(height: USizes.spaceBtwSections),
                UElevatedButton(
                  onPressed: loginState.isLoading ? _doNothing : _handleLogin,
                  child: loginState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(UTexts.signIn),
                ),
                const SizedBox(height: USizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: loginState.isLoading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                    child: const Text(UTexts.createAccount),
                  ),
                ),
                const SizedBox(height: USizes.spaceBtwSections),
                if (appVersion.isNotEmpty)
                  Center(
                    child: Text(
                      'v$appVersion • Build $buildNumber',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
