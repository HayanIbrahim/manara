import 'package:equatable/equatable.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../../domain/entities/quiz_entities.dart';

abstract class TutorEvent extends Equatable {
  const TutorEvent();
  @override
  List<Object?> get props => [];
}

class TutorLoadCoursesRequested extends TutorEvent {}

class TutorCreateCourseSubmitted extends TutorEvent {
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String subjectId;

  const TutorCreateCourseSubmitted({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.subjectId,
  });

  @override
  List<Object?> get props => [name, description, imageUrl, price, subjectId];
}

class TutorCreateLectureSubmitted extends TutorEvent {
  final String courseId;
  final String title;
  final String? description;
  final int position;
  final String videoUrl;
  final List<String> pdfUrls;

  const TutorCreateLectureSubmitted({
    required this.courseId,
    required this.title,
    this.description,
    required this.position,
    required this.videoUrl,
    this.pdfUrls = const [],
  });

  @override
  List<Object?> get props => [courseId, title, description, position, videoUrl, pdfUrls];
}

class TutorPutQuizSubmitted extends TutorEvent {
  final String lectureId;
  final List<QuizQuestionEntity> questions;

  const TutorPutQuizSubmitted({required this.lectureId, required this.questions});

  @override
  List<Object?> get props => [lectureId, questions];
}

class TutorLoadSubmissionsRequested extends TutorEvent {
  final String examId;
  const TutorLoadSubmissionsRequested(this.examId);

  @override
  List<Object?> get props => [examId];
}

class TutorGradeSubmissionSubmitted extends TutorEvent {
  final String submissionId;
  final double score;
  final String? feedback;
  final bool publish;

  const TutorGradeSubmissionSubmitted({
    required this.submissionId,
    required this.score,
    this.feedback,
    this.publish = false,
  });

  @override
  List<Object?> get props => [submissionId, score, feedback, publish];
}

class TutorPublishLectureSubmitted extends TutorEvent {
  final String lectureId;
  final bool published;

  const TutorPublishLectureSubmitted({required this.lectureId, this.published = true});

  @override
  List<Object?> get props => [lectureId, published];
}

class TutorDeleteLectureSubmitted extends TutorEvent {
  final String lectureId;

  const TutorDeleteLectureSubmitted(this.lectureId);

  @override
  List<Object?> get props => [lectureId];
}

class TutorPublishCourseSubmitted extends TutorEvent {
  final String courseId;
  final bool published;

  const TutorPublishCourseSubmitted({required this.courseId, this.published = true});

  @override
  List<Object?> get props => [courseId, published];
}

class TutorCreateExamSubmitted extends TutorEvent {
  final String courseId;
  final String title;
  final String? instructions;
  final int points;
  final List<ExamQuestionEntity> questions;

  const TutorCreateExamSubmitted({
    required this.courseId,
    required this.title,
    this.instructions,
    this.points = 50,
    required this.questions,
  });

  @override
  List<Object?> get props => [courseId, title, instructions, points, questions];
}
