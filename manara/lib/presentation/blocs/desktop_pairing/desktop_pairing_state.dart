import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_entities.dart';
import '../../../domain/entities/desktop_entities.dart';

abstract class DesktopPairingState extends Equatable {
  const DesktopPairingState();
  @override
  List<Object?> get props => [];
}

class DesktopPairingInitial extends DesktopPairingState {}

class DesktopPairingLoading extends DesktopPairingState {}

class DesktopPairingWaitingForMobile extends DesktopPairingState {
  final String challenge;
  final DateTime expiresAt;
  final DesktopChallengeStatus status;

  const DesktopPairingWaitingForMobile({
    required this.challenge,
    required this.expiresAt,
    this.status = DesktopChallengeStatus.pending,
  });

  @override
  List<Object?> get props => [challenge, expiresAt, status];
}

class DesktopPairingApprovedSuccess extends DesktopPairingState {
  final UserEntity user;
  const DesktopPairingApprovedSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class DesktopPairingMobileAuthorizedSuccess extends DesktopPairingState {
  final String challenge;
  const DesktopPairingMobileAuthorizedSuccess(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

class DesktopPairingError extends DesktopPairingState {
  final String message;
  final bool isExpired;

  const DesktopPairingError({
    required this.message,
    this.isExpired = false,
  });

  @override
  List<Object?> get props => [message, isExpired];
}
