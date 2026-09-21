import '../../domain/entities/quiz_entities.dart';

class QuizQuestionModel extends QuizQuestionEntity {
  const QuizQuestionModel({
    required super.prompt,
    required super.choices,
    super.correctChoice,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      prompt: json['prompt']?.toString() ?? '',
      choices: (json['choices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      correctChoice: (json['correctChoice'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'prompt': prompt,
      'choices': choices,
    };
    if (correctChoice != null) {
      data['correctChoice'] = correctChoice;
    }
    return data;
  }
}

class QuizModel extends QuizEntity {
  const QuizModel({
    required super.id,
    required super.lectureId,
    super.passPercent = 100,
    required super.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id']?.toString() ?? '',
      lectureId: json['lectureId']?.toString() ?? '',
      passPercent: (json['passPercent'] as num?)?.toInt() ?? 100,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lectureId': lectureId,
      'passPercent': passPercent,
      'questions': questions.map((q) {
        if (q is QuizQuestionModel) return q.toJson();
        return {
          'prompt': q.prompt,
          'choices': q.choices,
          if (q.correctChoice != null) 'correctChoice': q.correctChoice,
        };
      }).toList(),
    };
  }
}

class QuizAttemptResultModel extends QuizAttemptResultEntity {
  const QuizAttemptResultModel({
    required super.score,
    required super.correct,
    required super.total,
    required super.passed,
    required super.nextLectureUnlocked,
    super.progress,
  });

  factory QuizAttemptResultModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResultModel(
      score: (json['score'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      passed: json['passed'] == true,
      nextLectureUnlocked: json['nextLectureUnlocked'] == true,
      progress: json['progress'] is Map<String, dynamic> ? json['progress'] as Map<String, dynamic> : null,
    );
  }
}
