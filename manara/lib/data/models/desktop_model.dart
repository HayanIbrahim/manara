import '../../domain/entities/desktop_entities.dart';

class DesktopChallengeModel extends DesktopChallengeEntity {
  const DesktopChallengeModel({
    required super.challenge,
    required super.expiresAt,
  });

  factory DesktopChallengeModel.fromJson(Map<String, dynamic> json) {
    return DesktopChallengeModel(
      challenge: json['challenge']?.toString() ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'].toString())
          : DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenge': challenge,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

class DesktopStatusModel extends DesktopStatusEntity {
  const DesktopStatusModel({
    required super.status,
    required super.expiresAt,
  });

  factory DesktopStatusModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase() ?? 'PENDING';
    DesktopChallengeStatus status;
    switch (statusStr) {
      case 'APPROVED':
        status = DesktopChallengeStatus.approved;
        break;
      case 'CONSUMED':
        status = DesktopChallengeStatus.consumed;
        break;
      case 'CLOSED':
        status = DesktopChallengeStatus.closed;
        break;
      case 'EXPIRED':
        status = DesktopChallengeStatus.expired;
        break;
      default:
        status = DesktopChallengeStatus.pending;
    }

    return DesktopStatusModel(
      status: status,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'].toString())
          : DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}
