// lib/features/authentication/screens/login/widgets/remember_me.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_service.dart';
import '../notifier/login_notifier.dart';

class URememberMeCheckbox extends ConsumerStatefulWidget {
  const URememberMeCheckbox({super.key});

  @override
  ConsumerState<URememberMeCheckbox> createState() =>
      _URememberMeCheckboxState();
}

class _URememberMeCheckboxState extends ConsumerState<URememberMeCheckbox> {
  @override
  void initState() {
    super.initState();
    // Load remember me preference when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberMePreference();
    });
  }

  void _loadRememberMePreference() async {
    final storageService = ref.read(storageServiceProvider);
    final rememberMeEnabled = storageService.rememberMe;

    if (rememberMeEnabled) {
      final controller = ref.read(loginControllerProvider.notifier);
      controller.toggleRememberMe(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVE WidgetRef ref parameter
    final rememberMe = ref
        .watch(loginControllerProvider)
        .rememberMe; // Use class ref
    final controller = ref.read(
      loginControllerProvider.notifier,
    ); // Use class ref

    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          onChanged: (value) {
            controller.toggleRememberMe(value ?? false);
          },
        ),
        const Text("Remember Me"),
      ],
    );
  }
}
