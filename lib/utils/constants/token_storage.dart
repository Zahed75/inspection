// lib/utils/constants/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token saved successfully');
  }

  // Retrieve token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Check if token exists and is valid
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    final isValid = token != null && token.isNotEmpty;
    print('🔐 Token validation result: $isValid');
    return isValid;
  }

  // Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🗑️ Token cleared');
  }
}
