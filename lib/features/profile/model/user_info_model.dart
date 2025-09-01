class GetUserInfoModel {
  int? code;
  String? message;
  Data? data;

  GetUserInfoModel({this.code, this.message, this.data});

  factory GetUserInfoModel.fromJson(Map<String, dynamic> json) {
    return GetUserInfoModel(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  User? user;

  Data({this.user});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
  String? staffId;
  String? designation;
  String? name;
  String? phoneNumber;
  bool? isVerified;
  String? access;
  Site? site;
  String? grantedAt;

  User({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.staffId,
    this.designation,
    this.name,
    this.phoneNumber,
    this.isVerified,
    this.access,
    this.site,
    this.grantedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: _parseString(json['username']),
      firstName: _parseString(json['first_name']),
      lastName: _parseString(json['last_name']),
      email: _parseString(json['email']),
      staffId: _parseString(json['staff_id']),
      designation: _parseString(json['designation']),
      name: _parseString(json['name']),
      phoneNumber: _parseString(json['phone_number']),
      isVerified: json['is_verified'] as bool?,
      access: _parseString(json['access']),
      site: json['site'] != null ? Site.fromJson(json['site']) : null,
      grantedAt: _parseString(json['granted_at']),
    );
  }

  // Helper method to handle empty strings and convert to null if needed
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['staff_id'] = staffId;
    data['designation'] = designation;
    data['name'] = name;
    data['phone_number'] = phoneNumber;
    data['is_verified'] = isVerified;
    data['access'] = access;
    if (site != null) {
      data['site'] = site!.toJson();
    }
    data['granted_at'] = grantedAt;
    return data;
  }
}

class Site {
  int? id;
  String? siteCode;
  String? name;
  String? address;
  String? district;
  String? postCode;
  Platform? platform;
  String? source;

  Site({
    this.id,
    this.siteCode,
    this.name,
    this.address,
    this.district,
    this.postCode,
    this.platform,
    this.source,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as int?,
      siteCode: _parseString(json['site_code']),
      name: _parseString(json['name']),
      address: _parseString(json['address']),
      district: _parseString(json['district']),
      postCode: _parseString(json['post_code']),
      platform: json['platform'] != null ? Platform.fromJson(json['platform']) : null,
      source: _parseString(json['source']),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['site_code'] = siteCode;
    data['name'] = name;
    data['address'] = address;
    data['district'] = district;
    data['post_code'] = postCode;
    if (platform != null) {
      data['platform'] = platform!.toJson();
    }
    data['source'] = source;
    return data;
  }
}

class Platform {
  int? id;
  String? name;
  String? description;

  Platform({this.id, this.name, this.description});

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'] as int?,
      name: _parseString(json['name']),
      description: _parseString(json['description']),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}