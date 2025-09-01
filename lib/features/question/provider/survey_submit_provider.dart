// lib/features/survey/provider/survey_submit_api_provider.dart

import 'package:riverpod/riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../api/survey_submit_api.dart';

final surveySubmitApiProvider = Provider<SurveySubmitApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SurveySubmitApi(dio);
});
