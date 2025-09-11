// // lib/features/result/notifier/result_notifier.dart
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../api/result_api.dart';
// import '../model/survey_result_model.dart';
//
// final resultNotifierProvider =
//     StateNotifierProvider<ResultNotifier, AsyncValue<SurveyResultModel>>((ref) {
//       return ResultNotifier(ref);
//     });
//
// class ResultNotifier extends StateNotifier<AsyncValue<SurveyResultModel>> {
//   final Ref ref;
//
//   ResultNotifier(this.ref) : super(const AsyncValue.loading());
//
//   Future<void> fetchSurveyResult(int responseId) async {
//     if (responseId == 0) {
//       state = AsyncValue.error(
//         'Invalid response ID: $responseId',
//         StackTrace.current,
//       );
//       return;
//     }
//
//     state = const AsyncValue.loading();
//
//     try {
//       final apiService = ref.read(resultApiServiceProvider);
//       final result = await apiService.getSurveyResult(responseId);
//
//       state = AsyncValue.data(result);
//     } catch (error, stackTrace) {
//       print('Error in fetchSurveyResult: $error');
//       print('Stack trace: $stackTrace');
//       state = AsyncValue.error(error, stackTrace);
//     }
//   }
//
//   void clearResult() {
//     state = const AsyncValue.loading();
//   }
// }








// lib/features/result/notifier/result_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspection/features/result/model/survey_result_model.dart';
import 'package:inspection/services/survey_storage_service.dart';
import '../api/result_api.dart';

final resultNotifierProvider = StateNotifierProvider<ResultNotifier, AsyncValue<SurveyResultModel>>((ref) {
  return ResultNotifier(ref);
});

// lib/features/result/notifier/result_notifier.dart
class ResultNotifier extends StateNotifier<AsyncValue<SurveyResultModel>> {
  final Ref ref;

  ResultNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Try to load saved result immediately when notifier is created
    _loadSavedResult();
  }

  Future<void> _loadSavedResult() async {
    try {
      final savedResult = await SurveyStorageService.getSurveyResult();
      if (savedResult != null && savedResult.responseId != null) {
        state = AsyncValue.data(savedResult);
      }
    } catch (e) {
      print('Error loading saved result in notifier: $e');
    }
  }

  Future<void> fetchSurveyResult(int responseId) async {
    if (responseId == 0) {
      state = AsyncValue.error('Invalid response ID: $responseId', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(resultApiServiceProvider);
      final result = await apiService.getSurveyResult(responseId);

      // Save the result locally
      await SurveyStorageService.saveSurveyResult(result);

      state = AsyncValue.data(result);
    } catch (error) {
      // On error, try to load any previously saved result
      final savedResult = await SurveyStorageService.getSurveyResult();
      if (savedResult != null && savedResult.responseId == responseId) {
        state = AsyncValue.data(savedResult);
      } else {
        state = AsyncValue.error(error, StackTrace.current);
      }
    }
  }

  void clearResult() {
    state = const AsyncValue.loading();
    SurveyStorageService.clearSurveyResult();
  }
}
