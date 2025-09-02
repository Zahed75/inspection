// lib/utils/constants/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';

  // Save token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('✅ Token saved successfully');
    } catch (e) {
      print('❌ Error saving token: $e');
      throw Exception('Failed to save token: $e');
    }
  }

  // Retrieve token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('🔐 Token retrieved: ${token != null ? "Exists" : "Null"}');
      return token;
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  // Check if token exists and is valid
  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      final isValid = token != null && token.isNotEmpty;
      print('🔐 Token validation result: $isValid');
      return isValid;
    } catch (e) {
      print('❌ Error validating token: $e');
      return false;
    }
  }

  // Clear token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);

      // Verify token was actually cleared
      final tokenAfterClear = await getToken();
      if (tokenAfterClear == null) {
        print('✅ Token cleared successfully');
      } else {
        print('❌ Token clearance failed - token still exists');
        throw Exception('Failed to clear token');
      }
    } catch (e) {
      print('❌ Error clearing token: $e');
      throw Exception('Failed to clear token: $e');
    }
  }

  // Verify token clearance
  static Future<bool> isTokenCleared() async {
    final token = await getToken();
    return token == null;
  }
}