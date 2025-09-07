// lib/features/signup/notifier/signup_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/router/root_nav_key.dart'; // ← use root navigator context
import '../../../common_ui/widgets/alerts/u_alert.dart';
// Keep your existing repo import name/path (works with your current project)
import '../api/signup_api.dart';
import '../model/register_user_model.dart';

/// ------------- STATE -------------
class SignUpState {
  final String name;
  final String email;
  final String phoneNumber;
  final String staffId;
  final String designation;
  final String password;

  final bool isLoading;
  final String? error;
  final RegisterUserModel? response;

  const SignUpState({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.staffId = '',
    this.designation = '',
    this.password = '',
    this.isLoading = false,
    this.error,
    this.response,
  });

  SignUpState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? staffId,
    String? designation,
    String? password,
    bool? isLoading,
    String? error,
    RegisterUserModel? response,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      staffId: staffId ?? this.staffId,
      designation: designation ?? this.designation,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

/// ------------- NOTIFIER -------------
class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier(this._repo) : super(const SignUpState());

  final SignupRepository _repo;

  // field updaters
  void updateName(String v) => state = state.copyWith(name: v);
  void updateEmail(String v) => state = state.copyWith(email: v);
  void updatePhoneNumber(String v) => state = state.copyWith(phoneNumber: v);
  void updateStaffId(String v) => state = state.copyWith(staffId: v);
  void updateDesignation(String v) => state = state.copyWith(designation: v);
  void updatePassword(String v) => state = state.copyWith(password: v);

  Future<void> registerUser(BuildContext context) async {
    // Minimal guard (UI already validates)
    if (state.name.isEmpty ||
        state.email.isEmpty ||
        state.phoneNumber.length != 11 ||
        state.staffId.isEmpty ||
        state.designation.isEmpty ||
        state.password.isEmpty) {
      await UAlert.show(
        context: context,
        title: 'Incomplete form',
        message: 'Please fill all fields correctly.',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _repo.register(
        name: state.name.trim(),
        phoneNumber: state.phoneNumber.trim(),
        password: state.password,
        email: state.email.trim(),
        staffId: state.staffId.trim(),
        designation: state.designation.trim(),
      );

      state = state.copyWith(isLoading: false, response: res);

      final otpStr = res.data?.profile?.otp?.toString() ?? '';

      // Success dialog (unchanged UX)
      await UAlert.show(
        context: context,
        title: 'Registration successful',
        message: otpStr.isNotEmpty
            ? 'Your OTP is: $otpStr\n\nPlease enter it on the next screen.'
            : 'Please enter the OTP on the next screen.',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );

      // Navigate after dialog closes using ROOT navigator context.
      // This avoids trying to route from a dialog's local context.
      if (!mounted) return; // StateNotifier mounted check
      final phone = state.phoneNumber;

      // Prefer the root navigator's context; fall back to provided context
      final navCtx = rootNavigatorKey.currentContext ?? context;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          GoRouter.of(navCtx).goNamed(
            Routes.otpVerify,
            queryParams: {
              'phoneNumber': phone,
              if (otpStr.isNotEmpty) 'otp': otpStr,
            },
          );
        } catch (_) {
          // Fallback to path-based go if named route lookup fails
          final query =
              '${Routes.otpVerify}'
              '?phoneNumber=${Uri.encodeQueryComponent(phone)}'
              '${otpStr.isNotEmpty ? '&otp=${Uri.encodeQueryComponent(otpStr)}' : ''}';
          GoRouter.of(navCtx).go(query);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      await UAlert.show(
        context: context,
        title: 'Signup failed',
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    }
  }
}

/// ------------- PROVIDERS -------------
final signupRepositoryProvider = Provider<SignupRepository>((ref) {
  return SignupRepository();
});

final signUpProvider =
StateNotifierProvider<SignUpNotifier, SignUpState>((ref) {
  final repo = ref.read(signupRepositoryProvider);
  return SignUpNotifier(repo);
});
