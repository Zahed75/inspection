// lib/features/authentication/screens/signup/signup.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspection/features/signup/widgets/signup_form.dart';

import '../../common_ui/styles/padding.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/texts.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: UPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UTexts.signupTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: USizes.spaceBtwSections),

              const USignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}
