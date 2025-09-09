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

class SubmittedQuestions {
  final int? questionId;
  final String? questionText;
  final String? type;
  final int? maxMarks;
  final double? obtainedMarks;
  final dynamic answer;
  final String? categoryName; // ADDED: Category name field

  SubmittedQuestions({
    this.questionId,
    this.questionText,
    this.type,
    this.maxMarks,
    this.obtainedMarks,
    this.answer,
    this.categoryName, // ADDED: Category name field
  });

  factory SubmittedQuestions.fromJson(Map<String, dynamic> json) {
    return SubmittedQuestions(
      questionId: json['question_id'],
      questionText: json['question_text'],
      type: json['type'],
      maxMarks: json['max_marks'],
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      answer: json['answer'],
      categoryName: json['category_name'], // ADDED: Extract category_name from JSON
    );
  }

  @override
  String toString() {
    return 'SubmittedQuestions{questionId: $questionId, questionText: $questionText, type: $type, maxMarks: $maxMarks, obtainedMarks: $obtainedMarks, answer: $answer, categoryName: $categoryName}';
  }
}

class CategoryBlock {
  final String? name;
  final List<SubmittedQuestions> questions;

  CategoryBlock({this.name, required this.questions});

  factory CategoryBlock.fromJson(Map<String, dynamic> json) {
    final rawName =
        json['name'] ??
            json['category_name'] ??
            json['categoryName'] ??
            json['categoryTitle'] ??
            json['category'];

    final rawList =
    (json['questions'] ?? json['items'] ?? json['submitted_questions'])
    as List<dynamic>?;

    final qs = (rawList ?? const [])
        .whereType<Map>() // tolerate dynamic maps
        .map(
          (e) => SubmittedQuestions.fromJson(Map<String, dynamic>.from(e as Map)),
    )
        .toList();

    return CategoryBlock(
      name: (rawName is String && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : null,
      questions: qs,
    );
  }

  @override
  String toString() {
    return 'CategoryBlock{name: $name, questions: $questions}';
  }
}

class SurveyResultModel {
  String? message;
  int? responseId;
  double? obtainedScore;
  int? totalScore;
  double? percentage;

  String? submittedBy;
  String? submittedUserPhone;
  String? submittedAt;

  String? siteCode;
  String? outletCode;

  String? surveyTitle;

  List<SubmittedQuestions>? submittedQuestions;
  int? userId;

  List<CategoryBlock>? categories;

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
    this.categories,
  });

  factory SurveyResultModel.fromJson(Map<String, dynamic> json) {
    // --- Strongly type the two lists from the API ---
    final List<dynamic>? rawQs =
    (json['submitted_questions'] ?? json['questions']) as List<dynamic>?;

    final List<dynamic>? rawCats =
    (json['categories'] ??
        json['by_category'] ??
        json['category_wise'] ??
        json['categoryWise'])
    as List<dynamic>?;

    // Map submitted_questions -> List<SubmittedQuestions>
    final List<SubmittedQuestions>? submittedQs = rawQs
        ?.whereType<Map>() // tolerate dynamic
        .map(
          (q) => SubmittedQuestions.fromJson(Map<String, dynamic>.from(q as Map)),
    )
        .toList();

    // Map categories -> List<CategoryBlock>
    final List<CategoryBlock>? cats = rawCats
        ?.whereType<Map>()
        .map((c) => CategoryBlock.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    return SurveyResultModel(
      message: json['message'],
      responseId: json['response_id'] ?? json['id'],
      obtainedScore: (json['obtained_score'] as num?)?.toDouble(),
      totalScore: json['total_score'] as int?,
      percentage: (json['percentage'] as num?)?.toDouble(),

      submittedBy: json['submitted_by'] ?? json['submitted_user_name'],
      submittedUserPhone: json['submitted_user_phone'] ?? json['phone'],
      submittedAt: json['submitted_at'] ?? json['created_at'],

      siteCode: json['site_code'],
      outletCode: json['outlet_code'] ?? json['outletCode'],

      surveyTitle: json['survey_title'] ?? json['title'],

      submittedQuestions: submittedQs,
      userId: json['user_id'] as int?,

      // Server-provided categories, if any
      categories: cats,
    );
  }

  @override
  String toString() {
    return 'SurveyResultModel{message: $message, responseId: $responseId, obtainedScore: $obtainedScore, totalScore: $totalScore, percentage: $percentage, submittedBy: $submittedBy, submittedUserPhone: $submittedUserPhone, submittedAt: $submittedAt, siteCode: $siteCode, outletCode: $outletCode, surveyTitle: $surveyTitle, submittedQuestions: $submittedQuestions, userId: $userId, categories: $categories}';
  }
}