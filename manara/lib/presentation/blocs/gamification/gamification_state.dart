import 'package:equatable/equatable.dart';
import '../../../domain/entities/gamification_entities.dart';

abstract class GamificationState extends Equatable {
  const GamificationState();
  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {}

class GamificationLoading extends GamificationState {}

class GamificationLoaded extends GamificationState {
  final List<LeaderboardEntryEntity> leaderboard;
  final List<AchievementEntity> achievements;

  const GamificationLoaded({
    required this.leaderboard,
    required this.achievements,
  });

  @override
  List<Object?> get props => [leaderboard, achievements];
}

class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);

  @override
  List<Object?> get props => [message];
}
