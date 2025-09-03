import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/user_api.dart' as profile_api;
import '../model/user_info_model.dart' as profile_model;

// Create a separate provider to track authentication state
final isAuthenticatedProvider = StateProvider<bool>((ref) => true);

final userProfileNotifierProvider = StateNotifierProvider<
    UserProfileNotifier,
    AsyncValue<profile_model.GetUserInfoModel>>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier
    extends StateNotifier<AsyncValue<profile_model.GetUserInfoModel>> {
  final Ref ref;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Don't auto-fetch on creation, wait for explicit call
  }

  Future<void> fetchUserProfile() async {
    print('🔄 Starting to fetch user profile...');

    // Check authentication state first
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      print('❌ Not authenticated, skipping profile fetch');
      state = const AsyncValue.loading();
      return;
    }

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(profile_api.userApiServiceProvider);
      print('🔍 Calling user API service...');
      final profile = await apiService.getUserProfile();
      print('✅ User profile fetched successfully');
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      print('❌ Error in fetchUserProfile: $error');

      if (error.toString().contains('401') ||
          error.toString().contains('token') ||
          error.toString().contains('auth')) {
        // If auth error, mark as not authenticated
        ref.read(isAuthenticatedProvider.notifier).state = false;
        state = const AsyncValue.loading();
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  void clearProfile() {
    print('🧹 Clearing user profile state');
    state = const AsyncValue.loading();
  }

  void resetProfile() {
    print('🔄 Resetting user profile state');
    state = const AsyncValue.loading();
  }
}