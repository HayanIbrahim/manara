import 'package:equatable/equatable.dart';

class QuizQuestionEntity extends Equatable {
  final String prompt;
  final List<String> choices;
  final int? correctChoice; // Only present when tutor is authoring, redacted for students

  const QuizQuestionEntity({
    required this.prompt,
    required this.choices,
    this.correctChoice,
  });

  @override
  List<Object?> get props => [prompt, choices, correctChoice];
}

class QuizEntity extends Equatable {
  final String id;
  final String lectureId;
  final int passPercent;
  final List<QuizQuestionEntity> questions;

  const QuizEntity({
    required this.id,
    required this.lectureId,
    this.passPercent = 100,
    required this.questions,
  });

  @override
  List<Object?> get props => [id, lectureId, passPercent, questions];
}

class QuizAttemptResultEntity extends Equatable {
  final int score;
  final int correct;
  final int total;
  final bool passed;
  final bool nextLectureUnlocked;
  final Map<String, dynamic>? progress;

  const QuizAttemptResultEntity({
    required this.score,
    required this.correct,
    required this.total,
    required this.passed,
    required this.nextLectureUnlocked,
    this.progress,
  });

  @override
  List<Object?> get props => [
        score,
        correct,
        total,
        passed,
        nextLectureUnlocked,
        progress,
      ];
}
