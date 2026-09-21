import 'package:equatable/equatable.dart';

abstract class DesktopPairingEvent extends Equatable {
  const DesktopPairingEvent();
  @override
  List<Object?> get props => [];
}

class DesktopPairingCreateChallengeRequested extends DesktopPairingEvent {}

class DesktopPairingPollTick extends DesktopPairingEvent {}

class DesktopPairingAuthorizeRequested extends DesktopPairingEvent {
  final String challenge;
  const DesktopPairingAuthorizeRequested(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

class DesktopPairingResetRequested extends DesktopPairingEvent {}
