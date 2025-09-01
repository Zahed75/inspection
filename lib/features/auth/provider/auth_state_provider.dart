// lib/features/auth/provider/auth_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants/token_storage.dart';


// lib/features/auth/provider/auth_state_provider.dart
final authStateProvider = FutureProvider<bool>((ref) async {
  final token = await TokenStorage.getToken();
  return token != null && token.isNotEmpty;
});
