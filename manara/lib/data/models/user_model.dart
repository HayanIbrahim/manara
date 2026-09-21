import '../../domain/entities/auth_entities.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    required super.displayName,
    required super.role,
    super.status = 'ACTIVE',
    super.points = 0,
    super.deviceBound = false,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString().toUpperCase() ?? 'STUDENT';
    UserRole role;
    switch (roleStr) {
      case 'ADMIN':
        role = UserRole.admin;
        break;
      case 'TUTOR':
        role = UserRole.tutor;
        break;
      default:
        role = UserRole.student;
    }

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      role: role,
      status: json['status']?.toString() ?? 'ACTIVE',
      points: (json['points'] as num?)?.toInt() ?? 0,
      deviceBound: json['deviceBound'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'role': role == UserRole.tutor ? 'TUTOR' : (role == UserRole.admin ? 'ADMIN' : 'STUDENT'),
      'status': status,
      'points': points,
      'deviceBound': deviceBound,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
