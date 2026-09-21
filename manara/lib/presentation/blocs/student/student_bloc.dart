import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/gamification_repository.dart';
import '../../../domain/repositories/student_repository.dart';
import 'student_event.dart';
import 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentRepository _studentRepository;
  final GamificationRepository _gamificationRepository;

  StudentBloc({
    required this._studentRepository,
    required this._gamificationRepository,
  })  : super(StudentInitial()) {
    on<StudentLoadDashboardRequested>(_onLoadDashboard);
    on<StudentRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoadDashboard(
    StudentLoadDashboardRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(StudentLoading());
    await _loadData(emit);
  }

  Future<void> _onRefresh(
    StudentRefreshRequested event,
    Emitter<StudentState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<StudentState> emit) async {
    try {
      final courses = await _studentRepository.getEnrolledCourses();
      final announcements = await _gamificationRepository.getStudentAnnouncements();
      final achievements = await _gamificationRepository.getStudentAchievements();

      emit(StudentDashboardLoaded(
        enrolledCourses: courses,
        announcements: announcements,
        achievements: achievements,
        averageProgress: courses.isEmpty ? 0.0 : 0.65, // Dynamic/simulated progress
      ));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }
}
