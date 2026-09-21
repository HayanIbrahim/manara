import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_entities.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginSubmitted({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String signupCode;
  final UserRole role;
  final String username;
  final String? email;
  final String displayName;
  final String password;

  const AuthRegisterSubmitted({
    required this.signupCode,
    required this.role,
    required this.username,
    this.email,
    required this.displayName,
    required this.password,
  });

  @override
  List<Object?> get props => [signupCode, role, username, email, displayName, password];
}

class AuthGuestModeSelected extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthDesktopSessionApproved extends AuthEvent {
  final UserEntity user;
  const AuthDesktopSessionApproved(this.user);

  @override
  List<Object?> get props => [user];
}
