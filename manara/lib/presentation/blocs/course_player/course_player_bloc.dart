import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../../domain/repositories/student_repository.dart';
import 'course_player_event.dart';
import 'course_player_state.dart';

class CoursePlayerBloc extends Bloc<CoursePlayerEvent, CoursePlayerState> {
  final StudentRepository _studentRepository;

  CoursePlayerBloc(this._studentRepository) : super(CoursePlayerInitial()) {
    on<CoursePlayerLoadRequested>(_onLoadRequested);
    on<CoursePlayerSelectLectureRequested>(_onSelectLecture);
    on<CoursePlayerUnlockNextLectureTriggered>(_onUnlockNextLecture);
  }

  Future<void> _onLoadRequested(
    CoursePlayerLoadRequested event,
    Emitter<CoursePlayerState> emit,
  ) async {
    emit(CoursePlayerLoading());
    try {
      final stateData = await _studentRepository.getCourseLearningState(event.courseId);
      final course = stateData['course'] as CourseEntity;
      final lectures = (stateData['lectures'] as List<dynamic>?)?.cast<LectureEntity>() ?? [];
      final exams = (stateData['exams'] as List<dynamic>?)?.cast<ExamEntity>() ?? [];

      lectures.sort((a, b) => a.position.compareTo(b.position));

      final active = lectures.isNotEmpty
          ? lectures.first
          : LectureEntity(
              id: 'placeholder',
              courseId: course.id,
              title: 'Introduction',
              position: 1,
              videoUrl: '',
            );

      final unlockedPositions = lectures.where((l) => !l.locked).map((l) => l.position);
      final initialUnlocked = unlockedPositions.isEmpty
          ? 1
          : unlockedPositions.reduce(math.max);

      emit(CoursePlayerLoaded(
        course: course,
        lectures: lectures,
        exams: exams,
        activeLecture: active,
        unlockedUpToPosition: initialUnlocked,
      ));
    } catch (e) {
      emit(CoursePlayerError(e.toString()));
    }
  }

  void _onSelectLecture(
    CoursePlayerSelectLectureRequested event,
    Emitter<CoursePlayerState> emit,
  ) {
    final currentState = state;
    if (currentState is CoursePlayerLoaded) {
      if (currentState.isLectureUnlocked(event.lecture)) {
        emit(currentState.copyWith(activeLecture: event.lecture));
      }
    }
  }

  Future<void> _onUnlockNextLecture(
    CoursePlayerUnlockNextLectureTriggered event,
    Emitter<CoursePlayerState> emit,
  ) async {
    final currentState = state;
    if (currentState is CoursePlayerLoaded) {
      final nextPosition = currentState.unlockedUpToPosition + 1;
      try {
        final stateData = await _studentRepository.getCourseLearningState(currentState.course.id);
        final course = stateData['course'] as CourseEntity;
        final lectures = (stateData['lectures'] as List<dynamic>?)?.cast<LectureEntity>() ?? [];
        final exams = (stateData['exams'] as List<dynamic>?)?.cast<ExamEntity>() ?? [];
        lectures.sort((a, b) => a.position.compareTo(b.position));

        final unlockedPositions = lectures.where((l) => !l.locked).map((l) => l.position);
        final maxUnlocked = unlockedPositions.isEmpty
            ? nextPosition
            : math.max(nextPosition, unlockedPositions.reduce(math.max));

        final nextLecture = lectures.firstWhere(
          (l) => l.position == nextPosition,
          orElse: () => currentState.activeLecture,
        );

        emit(currentState.copyWith(
          course: course,
          lectures: lectures,
          exams: exams,
          activeLecture: nextLecture,
          unlockedUpToPosition: maxUnlocked,
        ));
      } catch (_) {
        emit(currentState.copyWith(unlockedUpToPosition: nextPosition));
      }
    }
  }
}
