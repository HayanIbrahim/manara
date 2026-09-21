import 'package:equatable/equatable.dart';

enum UserRole { admin, tutor, student, guest }

enum SessionType { admin, mobile, desktop, guest }

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String displayName;
  final UserRole role;
  final String status;
  final int points;
  final bool deviceBound;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    required this.role,
    this.status = 'ACTIVE',
    this.points = 0,
    this.deviceBound = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isTutor => role == UserRole.tutor;
  bool get isStudent => role == UserRole.student;
  bool get isAdmin => role == UserRole.admin;
  bool get isGuest => role == UserRole.guest;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        displayName,
        role,
        status,
        points,
        deviceBound,
      ];
}
