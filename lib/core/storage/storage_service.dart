// lib/core/storage/storage_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Provide SharedPreferences in main()');
});

class StorageService {
  StorageService(this.prefs);
  final SharedPreferences prefs;

  // Token for auth
  String? get token => prefs.getString('token');
  Future<void> setToken(String value) => prefs.setString('token', value);

  // Onboarding seen
  bool get onboardingSeen => prefs.getBool('onboardingSeen') ?? false;
  Future<void> setOnboardingSeen(bool v) => prefs.setBool('onboardingSeen', v);
  // Remember me
  bool get rememberMe => prefs.getBool('rememberMe') ?? false;
  Future<void> setRememberMe(bool value) => prefs.setBool('rememberMe', value);
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(sharedPrefsProvider));
});
