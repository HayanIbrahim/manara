import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  tutor,
  student;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.tutor:
        return 'TUTOR';
      case UserRole.student:
        return 'STUDENT';
    }
  }
}

enum AccountStatus { active, deactivated }

class AdminUserEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final UserRole role;

  const AdminUserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.role = UserRole.admin,
  });

  @override
  List<Object?> get props => [id, username, displayName, email, role];
}

class SubjectEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String? iconUrl;
  final int coursesCount;

  const SubjectEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.iconUrl,
    this.coursesCount = 0,
  });

  @override
  List<Object?> get props => [id, name, code, description, iconUrl, coursesCount];
}

class SignupCodeEntity extends Equatable {
  final String id;
  final String code;
  final UserRole role;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;

  const SignupCodeEntity({
    required this.id,
    required this.code,
    required this.role,
    required this.expiresAt,
    this.isUsed = false,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, code, role, expiresAt, isUsed, usedBy, usedAt, createdAt];
}

class AccountUserEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final UserRole role;
  final AccountStatus status;
  final bool deviceBound;
  final String? deviceId;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const AccountUserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    required this.role,
    required this.status,
    this.deviceBound = false,
    this.deviceId,
    this.lastLoginAt,
    required this.createdAt,
  });

  bool get isDeviceBound => deviceBound || (deviceId != null && deviceId!.isNotEmpty);
  bool get isActive => status == AccountStatus.active;

  @override
  List<Object?> get props => [id, username, displayName, email, role, status, deviceBound, deviceId, lastLoginAt, createdAt];
}

class AnnouncementEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String targetRole;
  final String? courseId;
  final DateTime createdAt;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.body,
    this.targetRole = 'ALL',
    this.courseId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, body, targetRole, courseId, createdAt];
}
