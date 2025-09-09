// // lib/features/result/model/survey_result_model.dart
// class SurveyResultModel {
//   String? message;
//   int? responseId;
//   double? obtainedScore; // Changed to double
//   int? totalScore;
//   double? percentage;
//   String? submittedBy;
//   String? submittedUserPhone;
//   String? submittedAt;
//   String? siteCode;
//   String? outletCode;
//   List<SubmittedQuestions>? submittedQuestions;
//   int? userId;
//   String? surveyTitle;
//
//   SurveyResultModel({
//     this.message,
//     this.responseId,
//     this.obtainedScore, // Changed to double
//     this.totalScore,
//     this.percentage,
//     this.submittedBy,
//     this.submittedUserPhone,
//     this.submittedAt,
//     this.siteCode,
//     this.outletCode,
//     this.submittedQuestions,
//     this.userId,
//     this.surveyTitle,
//   });
//
//   factory SurveyResultModel.fromJson(Map<String, dynamic> json) {
//     return SurveyResultModel(
//       message: json['message'],
//       responseId: json['response_id'],
//       obtainedScore: json['obtained_score']
//           ?.toDouble(), // Handle both int and double
//       totalScore: json['total_score'],
//       percentage: json['percentage']?.toDouble(),
//       submittedBy: json['submitted_by'],
//       submittedUserPhone: json['submitted_user_phone'],
//       submittedAt: json['submitted_at'],
//       siteCode: json['site_code'],
//       outletCode: json['outlet_code'],
//       submittedQuestions: json['submitted_questions'] != null
//           ? (json['submitted_questions'] as List)
//                 .map((v) => SubmittedQuestions.fromJson(v))
//                 .toList()
//           : null,
//       userId: json['user_id'],
//       surveyTitle: json['survey_title'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['message'] = message;
//     data['response_id'] = responseId;
//     data['obtained_score'] = obtainedScore;
//     data['total_score'] = totalScore;
//     data['percentage'] = percentage;
//     data['submitted_by'] = submittedBy;
//     data['submitted_user_phone'] = submittedUserPhone;
//     data['submitted_at'] = submittedAt;
//     data['site_code'] = siteCode;
//     data['outlet_code'] = outletCode;
//     if (submittedQuestions != null) {
//       data['submitted_questions'] = submittedQuestions!
//           .map((v) => v.toJson())
//           .toList();
//     }
//     data['user_id'] = userId;
//     data['survey_title'] = surveyTitle;
//     return data;
//   }
// }
//
// // lib/features/result/model/survey_result_model.dart
// class SubmittedQuestions {
//   int? questionId;
//   String? questionText;
//   String? type;
//   int? maxMarks;
//   double? obtainedMarks;
//   dynamic answer; // Changed from String? to dynamic
//
//   SubmittedQuestions({
//     this.questionId,
//     this.questionText,
//     this.type,
//     this.maxMarks,
//     this.obtainedMarks,
//     this.answer, // Changed to dynamic
//   });
//
//   factory SubmittedQuestions.fromJson(Map<String, dynamic> json) {
//     return SubmittedQuestions(
//       questionId: json['question_id'],
//       questionText: json['question_text'],
//       type: json['type'],
//       maxMarks: json['max_marks'],
//       obtainedMarks: json['obtained_marks']?.toDouble(),
//       answer: json['answer']?.toString(), // Convert any type to string
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['question_id'] = questionId;
//     data['question_text'] = questionText;
//     data['type'] = type;
//     data['max_marks'] = maxMarks;
//     data['obtained_marks'] = obtainedMarks;
//     data['answer'] = answer?.toString(); // Ensure it's string when serializing
//     return data;
//   }
// }









// lib/features/result/model/survey_result_model.dart

import 'package:flutter/foundation.dart';

class SurveyResultModel {
  String? message;
  int? responseId;
  double? obtainedScore;
  int? totalScore;
  double? percentage;

  // ✅ make sure these 3 are mapped in fromJson
  String? submittedBy;
  String? submittedUserPhone;
  String? submittedAt;

  // ✅ these already exist but ensure they are mapped in fromJson
  String? siteCode;
  String? outletCode;

  // Useful for header/subtitle (you already use this)
  String? surveyTitle;

  List<SubmittedQuestions>? submittedQuestions;
  int? userId;

  SurveyResultModel({
    this.message,
    this.responseId,
    this.obtainedScore,
    this.totalScore,
    this.percentage,
    this.submittedBy,
    this.submittedUserPhone,
    this.submittedAt,
    this.siteCode,
    this.outletCode,
    this.surveyTitle,
    this.submittedQuestions,
    this.userId,
  });

  factory SurveyResultModel.fromJson(Map<String, dynamic> json) {
    return SurveyResultModel(
      message: json['message'],
      responseId: json['response_id'] ?? json['id'],
      obtainedScore: (json['obtained_score'] as num?)?.toDouble(),
      totalScore: json['total_score'] as int?,
      percentage: (json['percentage'] as num?)?.toDouble(),

      // ✅ map submitter fields
      submittedBy: json['submitted_by'] ?? json['submitted_user_name'],
      submittedUserPhone: json['submitted_user_phone'] ?? json['phone'],

      // ✅ map timestamp
      submittedAt: json['submitted_at'] ?? json['created_at'],

      // ✅ map site codes
      siteCode: json['site_code'],
      outletCode: json['outlet_code'] ?? json['outletCode'],

      // Header/subtitle
      surveyTitle: json['survey_title'] ?? json['title'],

      // Questions
      submittedQuestions: (json['submitted_questions'] ?? json['questions'])
          ?.map<SubmittedQuestions>((q) => SubmittedQuestions.fromJson(q))
          .toList(),
      userId: json['user_id'] as int?,
    );
  }
}

class SubmittedQuestions {
  int? questionId;
  String? questionText;
  String? type;
  int? maxMarks;
  double? obtainedMarks;
  dynamic answer;

  // ✅ new
  String? categoryName;

  SubmittedQuestions({
    this.questionId,
    this.questionText,
    this.type,
    this.maxMarks,
    this.obtainedMarks,
    this.answer,
    this.categoryName, // ✅
  });

  factory SubmittedQuestions.fromJson(Map<String, dynamic> json) {
    return SubmittedQuestions(
      questionId: json['question_id'] ?? json['id'],
      questionText: json['question_text'] ?? json['text'],
      type: json['type'],
      maxMarks: json['max_marks'] ?? json['marks'],
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      answer: json['answer'] ?? json['value'],

      // ✅ keep the category from payload (your JSON has "category_name")
      categoryName: json['category_name'] ?? json['category'],
    );
  }






  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['question_id'] = questionId;
    data['question_text'] = questionText;
    data['type'] = type;
    data['max_marks'] = maxMarks;
    data['obtained_marks'] = obtainedMarks;
    data['answer'] = answer?.toString();
    data['category_name'] = categoryName; // ✅
    return data;
  }
}
