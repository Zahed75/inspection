import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ make sure this path matches the file that defines UserApiService
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

  Future<void> fetchUserProfile() async {
    print('🔄 Starting to fetch user profile...');
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
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearProfile() {
    state = const AsyncValue.loading();
  }
}
