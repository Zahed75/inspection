// lib/features/sigin/provider/login_api_provider.dart
import 'package:riverpod/riverpod.dart';


import '../../../core/network/dio_provider.dart';
import '../api/login_api.dart';

final loginApiProvider = Provider<LoginApi>((ref) {
  final dio = ref.watch(dioProvider); // We'll create this provider next
  return LoginApi(dio);
});