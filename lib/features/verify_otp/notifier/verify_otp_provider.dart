// lib/features/verify_otp/notifier/verify_otp_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../app/router/routes.dart';
import '../../../common_ui/widgets/alerts/u_alert.dart';
import '../api/verify_otp_api.dart';
import '../model/verify_otp_model.dart';

class VerifyOtpState {
  final bool isLoading;
  final String? error;
  final VerifyOtpModel? response;

  const VerifyOtpState({ this.isLoading = false, this.error, this.response });

  VerifyOtpState copyWith({ bool? isLoading, String? error, VerifyOtpModel? response }) {
    return VerifyOtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

class VerifyOtpNotifier extends StateNotifier<VerifyOtpState> {
  VerifyOtpNotifier(this._repo) : super(const VerifyOtpState());
  final VerifyOtpRepository _repo;

  Future<void> verifyOtp(
      BuildContext context, {
        required String phoneNumber,
        required String otp,
      }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _repo.verify(phoneNumber: phoneNumber, otp: otp);
      state = state.copyWith(isLoading: false, response: res);

      // ✅ Show success, then go to Home
      await UAlert.show(
        context: context,
        title: 'Success',
        message: res.message ?? 'OTP verified successfully.',
        icon: Icons.verified_outlined,
        iconColor: Colors.green,
      );

      if (context.mounted) {
        context.go(Routes.signIn);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      await UAlert.show(
        context: context,
        title: 'Verification failed',
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    }
  }
}

final verifyOtpRepositoryProvider = Provider<VerifyOtpRepository>((ref) {
  return VerifyOtpRepository();
});

final verifyOtpProvider =
StateNotifierProvider<VerifyOtpNotifier, VerifyOtpState>((ref) {
  final repo = ref.read(verifyOtpRepositoryProvider);
  return VerifyOtpNotifier(repo);
});
