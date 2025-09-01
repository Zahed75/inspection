// lib/features/sigin/model/user_login_model.dart
class UserLoginModel {
  String? message;
  List<User>? user;

  UserLoginModel({this.message, this.user});

  UserLoginModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['user'] != null) {
      user = <User>[];
      json['user'].forEach((v) {
        user!.add(User.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (user != null) {
      data['user'] = user!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class User {
  int? id;
  String? accessToken;
  String? refreshToken;
  String? tokenType;
  int? expiry;
  String? username;
  String? email;
  String? name;
  String? phoneNumber;
  String? designation;
  String? staffId;
  Role? role;

  User({
    this.id,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiry,
    this.username,
    this.email,
    this.name,
    this.phoneNumber,
    this.designation,
    this.staffId,
    this.role,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accessToken = json['access_token'];
    refreshToken = json['refresh_token'];
    tokenType = json['token_type'];
    expiry = json['expiry'];
    username = json['username'];
    email = json['email'];
    name = json['name'];
    phoneNumber = json['phone_number'];
    designation = json['designation'];
    staffId = json['staff_id'];
    role = json['role'] != null ? Role.fromJson(json['role']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['access_token'] = accessToken;
    data['refresh_token'] = refreshToken;
    data['token_type'] = tokenType;
    data['expiry'] = expiry;
    data['username'] = username;
    data['email'] = email;
    data['name'] = name;
    data['phone_number'] = phoneNumber;
    data['designation'] = designation;
    data['staff_id'] = staffId;
    if (role != null) {
      data['role'] = role!.toJson();
    }
    return data;
  }
}

class Role {
  int? id;
  String? name;
  Platform? platform;

  Role({this.id, this.name, this.platform});

  Role.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    platform = json['platform'] != null
        ? Platform.fromJson(json['platform'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (platform != null) {
      data['platform'] = platform!.toJson();
    }
    return data;
  }
}

class Platform {
  int? id;
  String? name;
  String? description;

  Platform({this.id, this.name, this.description});

  Platform.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}
