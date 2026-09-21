import '../entities/gamification_entities.dart';

abstract class GamificationRepository {
  Future<List<LeaderboardEntryEntity>> getLeaderboard();

  Future<List<AchievementEntity>> getStudentAchievements();

  Future<List<AnnouncementEntity>> getStudentAnnouncements();
}
