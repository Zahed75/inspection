// lib/features/authentication/screens/login/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/texts.dart';
import '../notifier/login_notifier.dart';

class ULoginForm extends ConsumerWidget {
  const ULoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Number
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          enabled: !loginState.isLoading,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.direct_right),
            prefixText: '+88 ',
            labelText: UTexts.number,
            counterText: '', // Hide counter
          ),
        ),
        const SizedBox(height: USizes.spaceBtwInputFields),

        // Password
        TextFormField(
          controller: controller.passwordController,
          obscureText: loginState.hidePassword,
          enabled: !loginState.isLoading,
          decoration: InputDecoration(
            prefixIcon: const Icon(Iconsax.password_check),
            labelText: UTexts.password,
            suffixIcon: IconButton(
              icon: Icon(
                loginState.hidePassword ? Iconsax.eye : Iconsax.eye_slash,
              ),
              onPressed: loginState.isLoading
                  ? null
                  : controller.togglePasswordVisibility,
            ),
          ),
        ),
      ],
    );
  }
}
