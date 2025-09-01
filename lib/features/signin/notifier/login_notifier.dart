// lib/features/signin/notifier/login_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_service.dart';
import '../../../utils/constants/token_storage.dart';
import '../api/login_api.dart';
import '../model/user_login_model.dart';
import '../provider/login_provider.dart'; // Import flutter_riverpod

class LoginState {
  final bool isLoading;
  final UserLoginModel? user;
  final bool hidePassword;
  final bool rememberMe;
  final String? errorMessage;

  LoginState({
    this.isLoading = false,
    this.user,
    this.hidePassword = true,
    this.rememberMe = false,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    UserLoginModel? user,
    bool? hidePassword,
    bool? rememberMe,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      hidePassword: hidePassword ?? this.hidePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginApi _loginApi;
  final Ref _ref; // Add Ref as a class field
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Accept Ref in constructor
  LoginNotifier(this._loginApi, this._ref) : super(LoginState());

  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> login() async {
    if (state.isLoading) return;

    final phoneNumber = phoneController.text.trim();
    final password = passwordController.text.trim();

    // Clear previous errors
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _loginApi.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      state = state.copyWith(isLoading: false, user: user);

      _handleSuccessfulLogin(user);
    } catch (e) {
      final errorMessage = _getUserFriendlyError(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      rethrow;
    }
  }

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Invalid credentials') ||
        errorString.contains('401')) {
      return 'Invalid phone number or password. Please check your credentials.';
    } else if (errorString.contains('Network is unreachable') ||
        errorString.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('Connection timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return 'Login failed. Please try again.';
    }
  }

  void _handleSuccessfulLogin(UserLoginModel user) {
    if (user.user != null && user.user!.isNotEmpty) {
      final userData = user.user!.first;
      _saveTokens(
        userData.accessToken,
        userData.refreshToken,
        state.rememberMe,
      );
      _saveUserData(userData);

      // Debug: Verify token was saved
      _verifyTokenSaved();
    }
  }

  // lib/features/signin/notifier/login_notifier.dart - UPDATE THESE METHODS

  Future<void> _saveTokens(String? accessToken, String? refreshToken, bool rememberMe) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await TokenStorage.saveToken(accessToken);   // ✅ await
        print('Token saved successfully to persistent storage');
      } catch (e) {
        print('Error saving token: $e');
      }
    }

    final storageService = _ref.read(storageServiceProvider);
    await storageService.setRememberMe(rememberMe);   // if this is async

    if (!rememberMe) {
      // clear refresh etc. if needed
    }
  }


  // Add this method to check remember me status on app start
  Future<bool> shouldAutoLogin() async {
    final storageService = _ref.read(storageServiceProvider);
    final rememberMeEnabled = storageService.rememberMe;
    final hasToken = await TokenStorage.getToken() != null;

    print(
      'Auto-login check - Remember me: $rememberMeEnabled, Has token: $hasToken',
    );
    return rememberMeEnabled && hasToken;
  }

  void _verifyTokenSaved() async {
    // Verify the token was actually saved
    final savedToken = await TokenStorage.getToken();
    if (savedToken != null) {
      print('Token verification: SUCCESS (${savedToken.substring(0, 20)}...)');
    } else {
      print('Token verification: FAILED - no token found in storage');
    }
  }

  void _saveUserData(User userData) {
    print('User logged in: ${userData.name}');
    print('User email: ${userData.email}');
    print('User role: ${userData.role?.name}');

    // TODO: Save other user data to shared preferences if needed
  }

  // Method to check if user is already logged in (for auto-login)
  Future<bool> checkExistingLogin() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout method
  Future<void> logout() async {
    await TokenStorage.clearToken();
    clearForm();
    print('User logged out successfully');
  }

  void clearForm() {
    phoneController.clear();
    passwordController.clear();
    state = LoginState(); // Reset to initial state
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// Update the provider to pass ref
final loginControllerProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) {
      final loginApi = ref.watch(loginApiProvider);
      return LoginNotifier(loginApi, ref); // Pass ref to the notifier
    });
