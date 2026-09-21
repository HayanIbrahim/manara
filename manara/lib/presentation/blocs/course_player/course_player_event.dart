import 'package:equatable/equatable.dart';
import '../../../domain/entities/course_entities.dart';

abstract class CoursePlayerEvent extends Equatable {
  const CoursePlayerEvent();
  @override
  List<Object?> get props => [];
}

class CoursePlayerLoadRequested extends CoursePlayerEvent {
  final String courseId;
  const CoursePlayerLoadRequested(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class CoursePlayerSelectLectureRequested extends CoursePlayerEvent {
  final LectureEntity lecture;
  const CoursePlayerSelectLectureRequested(this.lecture);

  @override
  List<Object?> get props => [lecture];
}

class CoursePlayerUnlockNextLectureTriggered extends CoursePlayerEvent {
  final String currentLectureId;
  const CoursePlayerUnlockNextLectureTriggered(this.currentLectureId);

  @override
  List<Object?> get props => [currentLectureId];
}
