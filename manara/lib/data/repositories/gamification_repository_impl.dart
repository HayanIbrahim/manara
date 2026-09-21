import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/remote/api_data_source.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final ApiDataSource _apiDataSource;

  GamificationRepositoryImpl(this._apiDataSource);

  @override
  Future<List<LeaderboardEntryEntity>> getLeaderboard() async {
    return await _apiDataSource.getLeaderboard();
  }

  @override
  Future<List<AchievementEntity>> getStudentAchievements() async {
    return await _apiDataSource.getStudentAchievements();
  }

  @override
  Future<List<AnnouncementEntity>> getStudentAnnouncements() async {
    return await _apiDataSource.getStudentAnnouncements();
  }
}
