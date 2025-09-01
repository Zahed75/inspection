// lib/features/signup/model/register_user_model.dart
class RegisterUserModel {
  String? message;
  Data? data;

  RegisterUserModel({this.message, this.data});

  factory RegisterUserModel.fromJson(Map<String, dynamic> json) =>
      RegisterUserModel(
        message: json['message'],
        data: json['data'] != null ? Data.fromJson(json['data']) : null,
      );

  Map<String, dynamic> toJson() => {
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class Data {
  User? user;
  Profile? profile;
  List<dynamic>? accessInfo;

  Data({this.user, this.profile, this.accessInfo});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    user: json['user'] != null ? User.fromJson(json['user']) : null,
    profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    accessInfo: json['access_info'] != null
        ? List<dynamic>.from(json['access_info'])
        : <dynamic>[],
  );

  Null get title => null;

  Null get questions => null;

  Map<String, dynamic> toJson() => {
    if (user != null) 'user': user!.toJson(),
    if (profile != null) 'profile': profile!.toJson(),
    if (accessInfo != null) 'access_info': accessInfo,
  };
}

class User {
  int? id;
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  Role? role;
  String? staffId;
  String? designation;
  String? name;
  String? phoneNumber;

  User({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.role,
    this.staffId,
    this.designation,
    this.name,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    firstName: json['first_name'],
    lastName: json['last_name'],
    email: json['email'],
    role: json['role'] != null ? Role.fromJson(json['role']) : null,
    staffId: json['staff_id']?.toString(),
    designation: json['designation'],
    name: json['name'],
    phoneNumber: json['phone_number'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    if (role != null) 'role': role!.toJson(),
    'staff_id': staffId,
    'designation': designation,
    'name': name,
    'phone_number': phoneNumber,
  };
}

class Role {
  int? id;
  String? name;
  Platform? platform;

  Role({this.id, this.name, this.platform});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id'],
    name: json['name'],
    platform: json['platform'] != null
        ? Platform.fromJson(json['platform'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (platform != null) 'platform': platform!.toJson(),
  };
}

class Platform {
  int? id;
  String? name;
  dynamic description;

  Platform({this.id, this.name, this.description});

  factory Platform.fromJson(Map<String, dynamic> json) => Platform(
    id: json['id'],
    name: json['name'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

class Profile {
  String? phoneNumber;
  int? otp;
  bool? isVerified;

  Profile({this.phoneNumber, this.otp, this.isVerified});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    phoneNumber: json['phone_number'],
    otp: json['otp'],
    isVerified: json['is_verified'],
  );

  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'otp': otp,
    'is_verified': isVerified,
  };
}
