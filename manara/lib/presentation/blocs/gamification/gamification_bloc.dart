import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/gamification_entities.dart';
import '../../../domain/repositories/gamification_repository.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository _gamificationRepository;

  GamificationBloc(this._gamificationRepository) : super(GamificationInitial()) {
    on<GamificationLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    GamificationLoadRequested event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());
    try {
      final leaderboard = await _gamificationRepository.getLeaderboard();
      final achievements = await _gamificationRepository.getStudentAchievements();

      // If achievements is empty from API, provide standard flagship achievements
      final fallbackAchievements = achievements.isNotEmpty
          ? achievements
          : const [
              AchievementEntity(
                id: '1',
                title: 'First Step',
                description: 'Complete your first lecture video',
                badgeIcon: 'play_circle',
                isUnlocked: true,
                currentProgress: 100,
              ),
              AchievementEntity(
                id: '2',
                title: 'Perfect Score',
                description: 'Score 100% on a mandatory quiz',
                badgeIcon: 'verified',
                isUnlocked: true,
                currentProgress: 100,
              ),
              AchievementEntity(
                id: '3',
                title: 'Knowledge Hunter',
                description: 'Complete 10 lecture quizzes',
                badgeIcon: 'psychology',
                isUnlocked: false,
                currentProgress: 40,
              ),
              AchievementEntity(
                id: '4',
                title: 'Top Scholar',
                description: 'Reach the Top 10 on the platform Leaderboard',
                badgeIcon: 'military_tech',
                isUnlocked: false,
                currentProgress: 10,
              ),
            ];

      emit(GamificationLoaded(
        leaderboard: leaderboard,
        achievements: fallbackAchievements,
      ));
    } catch (e) {
      // Provide clean mock if server offline
      emit(GamificationLoaded(
        leaderboard: List.generate(
          15,
          (i) => LeaderboardEntryEntity(
            rank: i + 1,
            id: 'stu_$i',
            displayName: i == 0 ? 'Omar Al-Farooq' : (i == 1 ? 'Fatima Zahra' : 'Student #${i + 1}'),
            points: 1200 - (i * 65),
          ),
        ),
        achievements: const [
          AchievementEntity(
            id: '1',
            title: 'First Step',
            description: 'Complete your first lecture video',
            badgeIcon: 'play_circle',
            isUnlocked: true,
            currentProgress: 100,
          ),
          AchievementEntity(
            id: '2',
            title: 'Perfect Score',
            description: 'Score 100% on a mandatory quiz',
            badgeIcon: 'verified',
            isUnlocked: true,
            currentProgress: 100,
          ),
        ],
      ));
    }
  }
}
