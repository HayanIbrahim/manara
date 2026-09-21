import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_entities.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  final SessionType sessionType;

  const Authenticated({
    required this.user,
    this.sessionType = SessionType.mobile,
  });

  @override
  List<Object?> get props => [user, sessionType];
}

class Unauthenticated extends AuthState {
  final bool isDeviceMismatch;
  final String? errorMessage;

  const Unauthenticated({
    this.isDeviceMismatch = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [isDeviceMismatch, errorMessage];
}

class AuthGuest extends AuthState {}
