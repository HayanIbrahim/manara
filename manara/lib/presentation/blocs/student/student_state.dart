import 'package:equatable/equatable.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/gamification_entities.dart';

abstract class StudentState extends Equatable {
  const StudentState();
  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentDashboardLoaded extends StudentState {
  final List<CourseEntity> enrolledCourses;
  final List<AnnouncementEntity> announcements;
  final List<AchievementEntity> achievements;
  final double averageProgress;

  const StudentDashboardLoaded({
    this.enrolledCourses = const [],
    this.announcements = const [],
    this.achievements = const [],
    this.averageProgress = 0.0,
  });

  @override
  List<Object?> get props => [
        enrolledCourses,
        announcements,
        achievements,
        averageProgress,
      ];
}

class StudentError extends StudentState {
  final String message;
  const StudentError(this.message);

  @override
  List<Object?> get props => [message];
}
