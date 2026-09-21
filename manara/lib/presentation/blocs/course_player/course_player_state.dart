import 'package:equatable/equatable.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/exam_entities.dart';

abstract class CoursePlayerState extends Equatable {
  const CoursePlayerState();
  @override
  List<Object?> get props => [];
}

class CoursePlayerInitial extends CoursePlayerState {}

class CoursePlayerLoading extends CoursePlayerState {}

class CoursePlayerLoaded extends CoursePlayerState {
  final CourseEntity course;
  final List<LectureEntity> lectures;
  final List<ExamEntity> exams;
  final LectureEntity activeLecture;
  final int unlockedUpToPosition;

  const CoursePlayerLoaded({
    required this.course,
    required this.lectures,
    this.exams = const [],
    required this.activeLecture,
    this.unlockedUpToPosition = 1,
  });

  bool isLectureUnlocked(LectureEntity lecture) {
    return lecture.position <= unlockedUpToPosition;
  }

  CoursePlayerLoaded copyWith({
    CourseEntity? course,
    List<LectureEntity>? lectures,
    List<ExamEntity>? exams,
    LectureEntity? activeLecture,
    int? unlockedUpToPosition,
  }) {
    return CoursePlayerLoaded(
      course: course ?? this.course,
      lectures: lectures ?? this.lectures,
      exams: exams ?? this.exams,
      activeLecture: activeLecture ?? this.activeLecture,
      unlockedUpToPosition: unlockedUpToPosition ?? this.unlockedUpToPosition,
    );
  }

  @override
  List<Object?> get props => [
        course,
        lectures,
        exams,
        activeLecture,
        unlockedUpToPosition,
      ];
}

class CoursePlayerError extends CoursePlayerState {
  final String message;
  const CoursePlayerError(this.message);

  @override
  List<Object?> get props => [message];
}
