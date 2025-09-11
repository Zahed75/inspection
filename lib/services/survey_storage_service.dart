// lib/services/survey_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/features/result/model/survey_result_model.dart';

// lib/services/survey_storage_service.dart
class SurveyStorageService {
  static const String _surveyResultKey = 'survey_result';

  // Save Survey Result in SharedPreferences
  static Future<void> saveSurveyResult(SurveyResultModel result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultJson = jsonEncode(result.toJson());
      await prefs.setString(_surveyResultKey, resultJson);
      print('Survey result saved successfully');
    } catch (e) {
      print('Error saving survey result: $e');
    }
  }

  // Retrieve Survey Result from SharedPreferences
  static Future<SurveyResultModel?> getSurveyResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultJson = prefs.getString(_surveyResultKey);
      if (resultJson != null && resultJson.isNotEmpty) {
        final result = SurveyResultModel.fromJson(jsonDecode(resultJson));
        // Validate that the result has at least a responseId
        if (result.responseId != null && result.responseId! > 0) {
          return result;
        }
      }
      return null;
    } catch (e) {
      print('Error retrieving survey result: $e');
      return null;
    }
  }

  // Clear Survey Result from SharedPreferences
  static Future<void> clearSurveyResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_surveyResultKey);
      print('Survey result cleared');
    } catch (e) {
      print('Error clearing survey result: $e');
    }
  }
}
