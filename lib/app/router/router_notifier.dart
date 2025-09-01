// lib/app/router/router_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/provider/auth_state_provider.dart';
import '../../core/storage/storage_service.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    // Listen to auth state changes - use the correct provider type
    ref.listen<AsyncValue<bool>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );

    // Listen to onboarding changes using select
    ref.listen<bool>(
      storageServiceProvider.select((service) => service.onboardingSeen),
      (_, __) => notifyListenifiers(),
    );
  }

  final Ref ref;

  void notifyListenifiers() {
    notifyListeners();
  }
}
