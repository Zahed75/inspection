// Add this to your providers file or create a new one
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/survey_storage_service.dart';

import '../model/survey_result_model.dart';



final latestResponseIdProvider = StateProvider<int?>((ref) => null);

// Add this to your providers file
final savedSurveyResultProvider = FutureProvider<SurveyResultModel?>((ref) async {

  return await SurveyStorageService.getSurveyResult();
});

