// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. The provider for theme mode ---
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Default is light theme
  return ThemeMode.light;
});

// --- 2. The provider to check if dark mode is enabled ---
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

// --- 3. Toggle theme between dark/light ---
void toggleTheme(WidgetRef ref, bool isDark) {
  final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  ref.read(themeModeProvider.notifier).state = themeMode;
}
