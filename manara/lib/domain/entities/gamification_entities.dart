import 'package:equatable/equatable.dart';

class LeaderboardEntryEntity extends Equatable {
  final int rank;
  final String id;
  final String displayName;
  final int points;

  const LeaderboardEntryEntity({
    required this.rank,
    required this.id,
    required this.displayName,
    required this.points,
  });

  bool get isTopThree => rank <= 3;

  @override
  List<Object?> get props => [rank, id, displayName, points];
}

class AnnouncementEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String audience;
  final List<String> courseIds;
  final List<String> studentIds;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.body,
    this.audience = 'ALL',
    this.courseIds = const [],
    this.studentIds = const [],
    this.expiresAt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, body, audience, expiresAt, createdAt];
}

class RatingEntity extends Equatable {
  final String? id;
  final int value; // 1 to 5
  final String? comment;
  final String? courseId;
  final String? tutorId;
  final DateTime? createdAt;

  const RatingEntity({
    this.id,
    required this.value,
    this.comment,
    this.courseId,
    this.tutorId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, value, comment, courseId, tutorId, createdAt];
}

class AchievementEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String badgeIcon;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;

  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeIcon,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.maxProgress = 100,
  });

  double get progressFraction =>
      maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        badgeIcon,
        isUnlocked,
        currentProgress,
        maxProgress,
      ];
}
