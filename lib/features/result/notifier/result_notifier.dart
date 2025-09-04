// lib/features/result/notifier/result_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/result_api.dart';
import '../model/survey_result_model.dart';

final resultNotifierProvider =
    StateNotifierProvider<ResultNotifier, AsyncValue<SurveyResultModel>>((ref) {
      return ResultNotifier(ref);
    });

class ResultNotifier extends StateNotifier<AsyncValue<SurveyResultModel>> {
  final Ref ref;

  ResultNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchSurveyResult(int responseId) async {
    if (responseId == 0) {
      state = AsyncValue.error(
        'Invalid response ID: $responseId',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(resultApiServiceProvider);
      final result = await apiService.getSurveyResult(responseId);

      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      print('Error in fetchSurveyResult: $error');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearResult() {
    state = const AsyncValue.loading();
  }
}
