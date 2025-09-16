import 'package:flutter/foundation.dart';

class SubmittedQuestions {
  final int? questionId;
  final String? questionText;
  final String? type;
  final int? maxMarks;
  final double? obtainedMarks;
  final dynamic answer;
  final String? categoryName;

  SubmittedQuestions({
    this.questionId,
    this.questionText,
    this.type,
    this.maxMarks,
    this.obtainedMarks,
    this.answer,
    this.categoryName,
  });

  // toJson method to serialize SubmittedQuestions
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'type': type,
      'max_marks': maxMarks,
      'obtained_marks': obtainedMarks,
      'answer': answer,
      'category_name': categoryName,
    };
  }

  factory SubmittedQuestions.fromJson(Map<String, dynamic> json) {
    return SubmittedQuestions(
      questionId: json['question_id'],
      questionText: json['question_text']?.toString(),
      type: json['type']?.toString(),
      maxMarks: (json['max_marks'] is num)
          ? (json['max_marks'] as num).toInt()
          : null,
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      answer: json['answer'],
      categoryName: json['category_name']?.toString(),
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

  // toJson method to serialize CategoryBlock
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

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
        .whereType<Map>()
        .map(
          (e) =>
              SubmittedQuestions.fromJson(Map<String, dynamic>.from(e as Map)),
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
  String toString() => 'CategoryBlock{name: $name, questions: $questions}';
}

// In your SurveyResultModel class
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
  String? siteName;
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
    this.siteName,
    this.outletCode,
    this.surveyTitle,
    this.submittedQuestions,
    this.userId,
    this.categories,
  });

  // Add this toJson method
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['response_id'] = responseId;
    data['obtained_score'] = obtainedScore;
    data['total_score'] = totalScore;
    data['percentage'] = percentage;
    data['submitted_by'] = submittedBy;
    data['submitted_user_phone'] = submittedUserPhone;
    data['submitted_at'] = submittedAt;
    data['site_code'] = siteCode;
    data['site_name'] = siteName;
    data['outlet_code'] = outletCode;
    data['survey_title'] = surveyTitle;
    data['user_id'] = userId;

    if (submittedQuestions != null) {
      data['submitted_questions'] = submittedQuestions!.map((v) => v.toJson()).toList();
    }

    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }

    return data;
  }

  factory SurveyResultModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawQs = (json['submitted_questions'] ?? json['questions']) as List<dynamic>?;
    final List<dynamic>? rawCats = (json['categories'] ?? json['by_category'] ?? json['category_wise'] ?? json['categoryWise']) as List<dynamic>?;

    final List<SubmittedQuestions>? submittedQs = rawQs?.whereType<Map>()?.map((q) => SubmittedQuestions.fromJson(Map<String, dynamic>.from(q as Map))).toList();
    final List<CategoryBlock>? cats = rawCats?.whereType<Map>()?.map((c) => CategoryBlock.fromJson(Map<String, dynamic>.from(c as Map))).toList();

    return SurveyResultModel(
      message: json['message']?.toString(),
      responseId: (json['response_id'] ?? json['id']) as int?,
      obtainedScore: (json['obtained_score'] as num?)?.toDouble(),
      totalScore: (json['total_score'] is num) ? (json['total_score'] as num).toInt() : null,
      percentage: (json['percentage'] as num?)?.toDouble(),
      submittedBy: (json['submitted_user_name'] ?? json['submitted_by'])?.toString(),
      submittedUserPhone: (json['submitted_user_phone'] ?? json['phone'])?.toString(),
      submittedAt: (json['submitted_at'] ?? json['created_at'])?.toString(),
      siteCode: json['site_code']?.toString(),
      siteName: json['site_name']?.toString(),
      outletCode: (json['outlet_code'] ?? json['outletCode'])?.toString(),
      surveyTitle: (json['survey_title'] ?? json['title'])?.toString(),
      submittedQuestions: submittedQs,
      userId: (json['user_id'] is num) ? (json['user_id'] as num).toInt() : null,
      categories: cats,
    );
  }
}
