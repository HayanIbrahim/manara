import '../../domain/entities/gamification_entities.dart';

class LeaderboardEntryModel extends LeaderboardEntryEntity {
  const LeaderboardEntryModel({
    required super.rank,
    required super.id,
    required super.displayName,
    required super.points,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Student',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    super.audience = 'ALL',
    super.courseIds = const [],
    super.studentIds = const [],
    super.expiresAt,
    super.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      audience: json['audience']?.toString() ?? 'ALL',
      courseIds: (json['courseIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      studentIds: (json['studentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class RatingModel extends RatingEntity {
  const RatingModel({
    super.id,
    required super.value,
    super.comment,
    super.courseId,
    super.tutorId,
    super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id']?.toString(),
      value: (json['value'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString(),
      courseId: json['courseId']?.toString(),
      tutorId: json['tutorId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      if (comment != null) 'comment': comment,
    };
  }
}

class AchievementModel extends AchievementEntity {
  const AchievementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.badgeIcon,
    super.isUnlocked = false,
    super.currentProgress = 0,
    super.maxProgress = 100,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final inner = (json['achievement'] is Map<String, dynamic>)
        ? json['achievement'] as Map<String, dynamic>
        : json;
    return AchievementModel(
      id: inner['id']?.toString() ?? json['id']?.toString() ?? '',
      title: inner['name']?.toString() ?? inner['title']?.toString() ?? json['title']?.toString() ?? 'Achievement',
      description: inner['description']?.toString() ?? json['description']?.toString() ?? '',
      badgeIcon: inner['badgeUrl']?.toString() ?? inner['icon']?.toString() ?? json['icon']?.toString() ?? 'award',
      isUnlocked: json['awardedAt'] != null || json['unlocked'] == true,
      currentProgress: (inner['pointsThreshold'] as num?)?.toInt() ?? (json['progress'] as num?)?.toInt() ?? 100,
      maxProgress: (inner['pointsThreshold'] as num?)?.toInt() ?? (json['maxProgress'] as num?)?.toInt() ?? 100,
    );
  }
}
