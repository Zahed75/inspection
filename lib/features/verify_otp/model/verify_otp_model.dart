class VerifyOtpModel {
  String? message;
  User? user;

  VerifyOtpModel({this.message, this.user});

  VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
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

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    role = json['role'] != null ? Role.fromJson(json['role']) : null;
    staffId = json['staff_id'];
    designation = json['designation'];
    name = json['name'];
    phoneNumber = json['phone_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    if (role != null) {
      data['role'] = role!.toJson();
    }
    data['staff_id'] = staffId;
    data['designation'] = designation;
    data['name'] = name;
    data['phone_number'] = phoneNumber;
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
  Null description;

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
