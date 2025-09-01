// lib/core/di/dio_provider.dart
import 'package:riverpod/riverpod.dart';
import 'package:dio/dio.dart';

import 'injection_container.dart';


final dioProvider = Provider<Dio>((ref) {
  return getDio();
});