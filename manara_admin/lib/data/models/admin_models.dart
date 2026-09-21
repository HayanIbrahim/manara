import '../../domain/entities/admin_entities.dart';

class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.id,
    required super.username,
    required super.displayName,
    super.email,
    super.role = UserRole.admin,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      role: _parseRole(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'role': 'ADMIN',
    };
  }

  static UserRole _parseRole(dynamic val) {
    final str = val?.toString().toUpperCase();
    if (str == 'TUTOR') return UserRole.tutor;
    if (str == 'STUDENT') return UserRole.student;
    return UserRole.admin;
  }
}

class SubjectModel extends SubjectEntity {
  const SubjectModel({
    required super.id,
    required super.name,
    required super.code,
    super.description,
    super.iconUrl,
    super.coursesCount = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: json['imageUrl']?.toString() ?? json['iconUrl']?.toString(),
      coursesCount: json['coursesCount'] is int ? json['coursesCount'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      if (iconUrl != null) 'iconUrl': iconUrl,
    };
  }
}

class SignupCodeModel extends SignupCodeEntity {
  const SignupCodeModel({
    required super.id,
    required super.code,
    required super.role,
    required super.expiresAt,
    super.isUsed = false,
    super.usedBy,
    super.usedAt,
    required super.createdAt,
  });

  factory SignupCodeModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString().toUpperCase();
    final role = roleStr == 'TUTOR' ? UserRole.tutor : UserRole.student;

    DateTime exp;
    try {
      exp = DateTime.parse(json['expiresAt']?.toString() ?? '');
    } catch (_) {
      exp = DateTime.now().add(const Duration(days: 7));
    }

    DateTime? usedAt;
    if (json['usedAt'] != null) {
      try {
        usedAt = DateTime.parse(json['usedAt'].toString());
      } catch (_) {}
    }

    DateTime created;
    try {
      created = DateTime.parse(json['createdAt']?.toString() ?? '');
    } catch (_) {
      created = DateTime.now();
    }

    final code = json['code']?.toString() ??
        json['signupCode']?.toString() ??
        json['plainCode']?.toString() ??
        json['token']?.toString() ??
        json['value']?.toString() ??
        '';

    final hasUsedAt = usedAt != null;
    final hasUsedById = (json['usedById'] != null && json['usedById'].toString().isNotEmpty && json['usedById'].toString() != 'null');
    final isUsed = json['isUsed'] == true || json['used'] == true || hasUsedAt || hasUsedById;

    final usedBy = json['usedBy']?.toString() ??
        (json['usedById'] != null && json['usedById'].toString() != 'null' ? json['usedById'].toString() : null) ??
        json['usedByUser']?['displayName']?.toString() ??
        json['user']?['username']?.toString();

    return SignupCodeModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: code,
      role: role,
      expiresAt: exp,
      isUsed: isUsed,
      usedBy: usedBy,
      usedAt: usedAt,
      createdAt: created,
    );
  }
}

class AccountUserModel extends AccountUserEntity {
  const AccountUserModel({
    required super.id,
    required super.username,
    required super.displayName,
    super.email,
    required super.role,
    required super.status,
    super.deviceBound = false,
    super.deviceId,
    super.lastLoginAt,
    required super.createdAt,
  });

  factory AccountUserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString().toUpperCase();
    UserRole role = UserRole.student;
    if (roleStr == 'ADMIN') role = UserRole.admin;
    if (roleStr == 'TUTOR') role = UserRole.tutor;

    final statusStr = json['status']?.toString().toUpperCase();
    final status = statusStr == 'DEACTIVATED' ? AccountStatus.deactivated : AccountStatus.active;

    final deviceBound = json['deviceBound'] == true;

    DateTime? lastLogin;
    if (json['lastLoginAt'] != null) {
      try {
        lastLogin = DateTime.parse(json['lastLoginAt'].toString());
      } catch (_) {}
    }

    DateTime created;
    try {
      created = DateTime.parse(json['createdAt']?.toString() ?? '');
    } catch (_) {
      created = DateTime.now();
    }

    return AccountUserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      role: role,
      status: status,
      deviceBound: deviceBound,
      deviceId: json['deviceId']?.toString(),
      lastLoginAt: lastLogin,
      createdAt: created,
    );
  }
}

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    super.targetRole = 'ALL',
    super.courseId,
    required super.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = DateTime.parse(json['createdAt']?.toString() ?? '');
    } catch (_) {
      created = DateTime.now();
    }

    return AnnouncementModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      targetRole: json['targetRole']?.toString() ?? 'ALL',
      courseId: json['courseId']?.toString(),
      createdAt: created,
    );
  }
}
