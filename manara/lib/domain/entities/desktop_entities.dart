import 'package:equatable/equatable.dart';

enum DesktopChallengeStatus {
  pending,
  approved,
  consumed,
  closed,
  expired,
}

class DesktopChallengeEntity extends Equatable {
  final String challenge;
  final DateTime expiresAt;

  const DesktopChallengeEntity({
    required this.challenge,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [challenge, expiresAt];
}

class DesktopStatusEntity extends Equatable {
  final DesktopChallengeStatus status;
  final DateTime expiresAt;

  const DesktopStatusEntity({
    required this.status,
    required this.expiresAt,
  });

  bool get isPending => status == DesktopChallengeStatus.pending;
  bool get isApproved => status == DesktopChallengeStatus.approved;
  bool get isConsumed => status == DesktopChallengeStatus.consumed;
  bool get isExpired => status == DesktopChallengeStatus.expired || DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [status, expiresAt];
}
