// lib/features/survey/provider/survey_api_provider.dart

import 'package:riverpod/riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../api/survey_api.dart';

final surveyApiProvider = Provider<SurveyApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SurveyApi(dio);
});

final surveyRefreshTriggerProvider = StateProvider<int>((ref) => 0);