// lib/features/verify_otp/otp_verify.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../app/router/routes.dart';
import '../../common_ui/styles/padding.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/images.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/texts.dart';
import '../../utils/helpers/device_helpers.dart';
import '../../utils/helpers/helper_function.dart';
import 'notifier/verify_otp_provider.dart';



class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? otp; // optional: used for showing hint, not autofill

  const OtpVerifyScreen({super.key, required this.phoneNumber, this.otp});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    // ⛔️ Don't prefill or auto-verify; user will type it
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = UHelperFunctions.isDarkMode(context);
    final vm = ref.watch(verifyOtpProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.go(Routes.signIn),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: UPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                UImages.mailSentImage,
                height: UDeviceHelper.getScreenWidth(context) * 0.6,
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              Text(
                UTexts.verifyYourOtp,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              Text(
                '+88${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              Text(
                'Enter the 5-digit code sent to your number',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),

              // 👇 Helpful hint so users know the demo OTP
              if ((widget.otp ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Hint: Your OTP is ${widget.otp}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: USizes.spaceBtwSections),

              Center(
                child: Pinput(
                  length: 5,
                  controller: _otpController,
                  defaultPinTheme: PinTheme(
                    height: 56,
                    width: 56,
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    decoration: BoxDecoration(
                      color: dark ? UColors.darkGrey : UColors.light,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UColors.primary),
                    ),
                  ),
                  onCompleted: (otp) {
                    ref.read(verifyOtpProvider.notifier).verifyOtp(
                      context,
                      phoneNumber: widget.phoneNumber,
                      otp: otp,
                    );
                  },
                ),
              ),

              const SizedBox(height: USizes.spaceBtwItems),

              TextButton(
                onPressed: vm.isLoading ? null : () {
                  // TODO: implement resend OTP if needed
                },
                child: Text(UTexts.resendOTP),
              ),

              const SizedBox(height: USizes.spaceBtwItems),
              if (vm.isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
