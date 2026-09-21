import 'package:equatable/equatable.dart';

enum ExamQuestionType { multipleChoice, written }

enum ExamSubmissionStatus { submitted, graded, published }

class ExamQuestionEntity extends Equatable {
  final String id;
  final ExamQuestionType type;
  final String prompt;
  final List<String> choices;
  final int? correctChoice;
  final List<String> imageUrls;

  const ExamQuestionEntity({
    required this.id,
    required this.type,
    required this.prompt,
    this.choices = const [],
    this.correctChoice,
    this.imageUrls = const [],
  });

  bool get isMultipleChoice => type == ExamQuestionType.multipleChoice;
  bool get isWritten => type == ExamQuestionType.written;

  @override
  List<Object?> get props => [id, type, prompt, choices, correctChoice, imageUrls];
}

class ExamEntity extends Equatable {
  final String id;
  final String courseId;
  final String? tutorId;
  final String title;
  final String? instructions;
  final int points;
  final bool published;
  final List<ExamQuestionEntity> questions;

  const ExamEntity({
    required this.id,
    required this.courseId,
    this.tutorId,
    required this.title,
    this.instructions,
    this.points = 50,
    this.published = false,
    required this.questions,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        tutorId,
        title,
        instructions,
        points,
        published,
        questions,
      ];
}

class ExamAnswerEntity extends Equatable {
  final String questionId;
  final int? choice;
  final String? text;

  const ExamAnswerEntity({
    required this.questionId,
    this.choice,
    this.text,
  });

  @override
  List<Object?> get props => [questionId, choice, text];
}

class ExamSubmissionEntity extends Equatable {
  final String id;
  final String examId;
  final String studentId;
  final ExamSubmissionStatus status;
  final double? score;
  final String? feedback;
  final List<ExamAnswerEntity> answers;
  final List<String> attachmentUrls;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime? publishedAt;
  final String? examTitle;

  const ExamSubmissionEntity({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.status,
    this.score,
    this.feedback,
    required this.answers,
    this.attachmentUrls = const [],
    this.submittedAt,
    this.gradedAt,
    this.publishedAt,
    this.examTitle,
  });

  bool get isGraded => status == ExamSubmissionStatus.graded || status == ExamSubmissionStatus.published;
  bool get isPublished => status == ExamSubmissionStatus.published;

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        status,
        score,
        feedback,
        answers,
        attachmentUrls,
        submittedAt,
      ];
}
