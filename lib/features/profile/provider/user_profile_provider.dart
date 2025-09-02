import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ make sure this path matches the file that defines UserApiService
import '../../../utils/constants/token_storage.dart';
import '../api/user_api.dart' as profile_api;

// ✅ alias the model import
import '../model/user_info_model.dart' as profile_model;

final userProfileNotifierProvider =
StateNotifierProvider<
    UserProfileNotifier,
    AsyncValue<profile_model.GetUserInfoModel>
>((ref) => UserProfileNotifier(ref));

class UserProfileNotifier
    extends StateNotifier<AsyncValue<profile_model.GetUserInfoModel>> {
  final Ref ref;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchUserProfile();
  }

  // In lib/features/profile/provider/user_profile_provider.dart
  Future<void> fetchUserProfile() async {
    print('🔄 Starting to fetch user profile...');

    // Check if token exists before making API call - USE YOUR TokenStorage
    final hasToken = await TokenStorage.isTokenValid();
    if (!hasToken) {
      print('❌ No valid token found, skipping profile fetch');
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
      print('❌ Stack trace: $stackTrace');

      // If it's an authentication error, clear the state
      if (error.toString().contains('401') ||
          error.toString().contains('token') ||
          error.toString().contains('auth')) {
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

  // Add a method to reset the state completely
  void resetProfile() {
    print('🔄 Resetting user profile state');
    state = const AsyncValue.loading();
  }
}