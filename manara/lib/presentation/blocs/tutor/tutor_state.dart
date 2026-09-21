import 'package:equatable/equatable.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/exam_entities.dart';

abstract class TutorState extends Equatable {
  const TutorState();
  @override
  List<Object?> get props => [];
}

class TutorInitial extends TutorState {}

class TutorLoading extends TutorState {}

class TutorCoursesLoaded extends TutorState {
  final List<CourseEntity> courses;
  final List<ExamSubmissionEntity> submissions;

  const TutorCoursesLoaded({
    required this.courses,
    this.submissions = const [],
  });

  @override
  List<Object?> get props => [courses, submissions];
}

class TutorActionSuccess extends TutorState {
  final String message;
  const TutorActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TutorError extends TutorState {
  final String message;
  const TutorError(this.message);

  @override
  List<Object?> get props => [message];
}
