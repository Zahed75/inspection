// // lib/features/survey/model/survey_list_model.dart
// class SurveyListModel {
//   String? message;
//   int? surveyCount;
//   int? accessibleSiteCount;
//   dynamic filteredBySiteCode;
//   List<SurveyData>? data; // Changed from Data to SurveyData
//
//   SurveyListModel({
//     this.message,
//     this.surveyCount,
//     this.accessibleSiteCount,
//     this.filteredBySiteCode,
//     this.data,
//   });
//
//   SurveyListModel.fromJson(Map<String, dynamic> json) {
//     message = json['message'];
//     surveyCount = json['survey_count'];
//     accessibleSiteCount = json['accessible_site_count'];
//     filteredBySiteCode = json['filtered_by_site_code'];
//     if (json['data'] != null) {
//       data = <SurveyData>[]; // Changed to SurveyData
//       json['data'].forEach((v) {
//         data!.add(SurveyData.fromJson(v)); // Changed to SurveyData
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['message'] = message;
//     data['survey_count'] = surveyCount;
//     data['accessible_site_count'] = accessibleSiteCount;
//     data['filtered_by_site_code'] = filteredBySiteCode;
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// // Renamed from Data to SurveyData
// class SurveyData {
//   int? id;
//   List<Questions>? questions;
//   List<dynamic>? targets;
//   String? title;
//   String? description;
//   String? siteCode;
//   bool? isLocationBased;
//   bool? isImageRequired;
//   bool? isActive;
//   String? createdAt;
//   String? updatedAt;
//   int? createdByUserId;
//   int? department;
//   int? surveyType;
//
//   SurveyData({
//     this.id,
//     this.questions,
//     this.targets,
//     this.title,
//     this.description,
//     this.siteCode,
//     this.isLocationBased,
//     this.isImageRequired,
//     this.isActive,
//     this.createdAt,
//     this.updatedAt,
//     this.createdByUserId,
//     this.department,
//     this.surveyType,
//   });
//
//   SurveyData.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     if (json['questions'] != null) {
//       questions = <Questions>[];
//       json['questions'].forEach((v) {
//         questions!.add(Questions.fromJson(v));
//       });
//     }
//     targets = json['targets'];
//     title = json['title'];
//     description = json['description'];
//     siteCode = json['site_code'];
//     isLocationBased = json['is_location_based'];
//     isImageRequired = json['is_image_required'];
//     isActive = json['is_active'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     createdByUserId = json['created_by_user_id'];
//     department = json['department'];
//     surveyType = json['survey_type'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     if (questions != null) {
//       data['questions'] = questions!.map((v) => v.toJson()).toList();
//     }
//     data['targets'] = targets;
//     data['title'] = title;
//     data['description'] = description;
//     data['site_code'] = siteCode;
//     data['is_location_based'] = isLocationBased;
//     data['is_image_required'] = isImageRequired;
//     data['is_active'] = isActive;
//     data['created_at'] = createdAt;
//     data['updated_at'] = updatedAt;
//     data['created_by_user_id'] = createdByUserId;
//     data['department'] = department;
//     data['survey_type'] = surveyType;
//     return data;
//   }
// }
//
// class Questions {
//   int? id;
//   String? text;
//   String? type;
//   bool? hasMarks;
//   int? marks;
//   int? minValue;
//   int? maxValue;
//   bool? isRequired;
//   List<Choices>? choices;
//
//   Questions({
//     this.id,
//     this.text,
//     this.type,
//     this.hasMarks,
//     this.marks,
//     this.minValue,
//     this.maxValue,
//     this.isRequired,
//     this.choices,
//   });
//
//   Questions.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     text = json['text'];
//     type = json['type'];
//     hasMarks = json['has_marks'];
//     marks = json['marks'];
//     minValue = json['min_value'];
//     maxValue = json['max_value'];
//     isRequired = json['is_required'];
//     if (json['choices'] != null) {
//       choices = <Choices>[];
//       json['choices'].forEach((v) {
//         choices!.add(Choices.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['text'] = text;
//     data['type'] = type;
//     data['has_marks'] = hasMarks;
//     data['marks'] = marks;
//     data['min_value'] = minValue;
//     data['max_value'] = maxValue;
//     data['is_required'] = isRequired;
//     if (choices != null) {
//       data['choices'] = choices!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Choices {
//   int? id;
//   String? text;
//   bool? isCorrect;
//   int? marks;
//
//   Choices({this.id, this.text, this.isCorrect, this.marks});
//
//   Choices.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     text = json['text'];
//     isCorrect = json['is_correct'];
//     marks = json['marks'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['text'] = text;
//     data['is_correct'] = isCorrect;
//     data['marks'] = marks;
//     return data;
//   }
// }




// lib/features/home/model/survey_list_model.dart

class SurveyListModel {
  String? message;
  int? surveyCount;
  int? accessibleSiteCount;
  dynamic filteredBySiteCode; // was Null?, make it flexible
  List<Data>? data;

  SurveyListModel({
    this.message,
    this.surveyCount,
    this.accessibleSiteCount,
    this.filteredBySiteCode,
    this.data,
  });

  SurveyListModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    surveyCount = json['survey_count'];
    accessibleSiteCount = json['accessible_site_count'];
    filteredBySiteCode = json['filtered_by_site_code'];
    if (json['data'] != null) {
      data = <Data>[];
      for (final v in (json['data'] as List)) {
        data!.add(Data.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = {};
    out['message'] = message;
    out['survey_count'] = surveyCount;
    out['accessible_site_count'] = accessibleSiteCount;
    out['filtered_by_site_code'] = filteredBySiteCode;
    if (data != null) {
      out['data'] = data!.map((v) => v.toJson()).toList();
    }
    return out;
  }
}

class Data {
  int? id;
  List<Questions>? questions;
  List<dynamic>? targets; // <<< FIX: do NOT use List<Null>
  String? title;
  String? description;
  String? siteCode;
  bool? isLocationBased;
  bool? isImageRequired;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? createdByUserId;
  int? department;
  int? surveyType;

  Data({
    this.id,
    this.questions,
    this.targets,
    this.title,
    this.description,
    this.siteCode,
    this.isLocationBased,
    this.isImageRequired,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdByUserId,
    this.department,
    this.surveyType,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['questions'] != null) {
      questions = <Questions>[];
      for (final v in (json['questions'] as List)) {
        questions!.add(Questions.fromJson(v));
      }
    }
    // <<< FIX: simple pass-through for targets
    if (json['targets'] != null) {
      targets = List<dynamic>.from(json['targets'] as List);
    }
    title = json['title'];
    description = json['description'];
    siteCode = json['site_code'];
    isLocationBased = json['is_location_based'];
    isImageRequired = json['is_image_required'];
    isActive = json['is_active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdByUserId = json['created_by_user_id'];
    department = json['department'];
    surveyType = json['survey_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = {};
    out['id'] = id;
    if (questions != null) {
      out['questions'] = questions!.map((v) => v.toJson()).toList();
    }
    // <<< FIX: don't call toJson() on dynamic
    if (targets != null) {
      out['targets'] = List<dynamic>.from(targets!);
    }
    out['title'] = title;
    out['description'] = description;
    out['site_code'] = siteCode;
    out['is_location_based'] = isLocationBased;
    out['is_image_required'] = isImageRequired;
    out['is_active'] = isActive;
    out['created_at'] = createdAt;
    out['updated_at'] = updatedAt;
    out['created_by_user_id'] = createdByUserId;
    out['department'] = department;
    out['survey_type'] = surveyType;
    return out;
  }
}

class Questions {
  int? id;
  String? text;
  String? type;
  bool? hasMarks;
  int? marks;
  int? minValue;
  int? maxValue;
  bool? isRequired;
  List<Choices>? choices;
  String? categoryName; // new

  Questions({
    this.id,
    this.text,
    this.type,
    this.hasMarks,
    this.marks,
    this.minValue,
    this.maxValue,
    this.isRequired,
    this.choices,
    this.categoryName,
  });

  Questions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    text = json['text'];
    type = json['type'];
    hasMarks = json['has_marks'];
    marks = json['marks'];
    minValue = json['min_value'];
    maxValue = json['max_value'];
    isRequired = json['is_required'];
    if (json['choices'] != null) {
      choices = <Choices>[];
      for (final v in (json['choices'] as List)) {
        choices!.add(Choices.fromJson(v));
      }
    }
    categoryName = json['category_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = {};
    out['id'] = id;
    out['text'] = text;
    out['type'] = type;
    out['has_marks'] = hasMarks;
    out['marks'] = marks;
    out['min_value'] = minValue;
    out['max_value'] = maxValue;
    out['is_required'] = isRequired;
    if (choices != null) {
      out['choices'] = choices!.map((v) => v.toJson()).toList();
    }
    out['category_name'] = categoryName;
    return out;
  }
}

class Choices {
  int? id;
  String? text;
  bool? isCorrect;
  int? marks;

  Choices({this.id, this.text, this.isCorrect, this.marks});

  Choices.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    text = json['text'];
    isCorrect = json['is_correct'];
    marks = json['marks'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = {};
    out['id'] = id;
    out['text'] = text;
    out['is_correct'] = isCorrect;
    out['marks'] = marks;
    return out;
  }
}
