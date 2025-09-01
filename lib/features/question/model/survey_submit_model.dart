// lib/features/survey/model/survey_submitted_response_model.dart
class SurveySubmitResponseModel {
  String? message;
  int? responseId;
  double? totalScore;
  String? siteCode;
  String? outletCode;
  List<SubmittedQuestions>? submittedQuestions;
  int? userId;
  String? surveyTitle;

  SurveySubmitResponseModel({
    this.message,
    this.responseId,
    this.totalScore,
    this.siteCode,
    this.outletCode,
    this.submittedQuestions,
    this.userId,
    this.surveyTitle,
  });

  factory SurveySubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return SurveySubmitResponseModel(
      message: json['message'],
      responseId: json['response_id'],
      totalScore: json['total_score']?.toDouble(),
      siteCode: json['site_code'],
      outletCode: json['outlet_code'],
      submittedQuestions: json['submitted_questions'] != null
          ? (json['submitted_questions'] as List)
                .map((v) => SubmittedQuestions.fromJson(v))
                .toList()
          : null,
      userId: json['user_id'],
      surveyTitle: json['survey_title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['response_id'] = responseId;
    data['total_score'] = totalScore;
    data['site_code'] = siteCode;
    data['outlet_code'] = outletCode;
    if (submittedQuestions != null) {
      data['submitted_questions'] = submittedQuestions!
          .map((v) => v.toJson())
          .toList();
    }
    data['user_id'] = userId;
    data['survey_title'] = surveyTitle;
    return data;
  }

  // Add this method for debugging
  void printDebugInfo() {
    print('📦 Survey Submission Response:');
    print('   Message: $message');
    print('   Response ID: $responseId');
    print('   Total Score: $totalScore');
    print('   Site Code: $siteCode');
    print('   User ID: $userId');
    print('   Survey Title: $surveyTitle');
    if (submittedQuestions != null) {
      print('   Submitted Questions: ${submittedQuestions!.length}');
    }
  }
}

class SubmittedQuestions {
  int? questionId;
  String? questionText;
  String? type;
  int? maxMarks;
  double? obtainedMarks;
  String? answer;

  SubmittedQuestions({
    this.questionId,
    this.questionText,
    this.type,
    this.maxMarks,
    this.obtainedMarks,
    this.answer,
  });

  factory SubmittedQuestions.fromJson(Map<String, dynamic> json) {
    return SubmittedQuestions(
      questionId: json['question_id'],
      questionText: json['question_text'],
      type: json['type'],
      maxMarks: json['max_marks'],
      obtainedMarks: json['obtained_marks']?.toDouble(),
      answer: json['answer'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['question_id'] = questionId;
    data['question_text'] = questionText;
    data['type'] = type;
    data['max_marks'] = maxMarks;
    data['obtained_marks'] = obtainedMarks;
    data['answer'] = answer;
    return data;
  }
}
