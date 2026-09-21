import '../../domain/entities/exam_entities.dart';

class ExamQuestionModel extends ExamQuestionEntity {
  const ExamQuestionModel({
    required super.id,
    required super.type,
    required super.prompt,
    super.choices = const [],
    super.correctChoice,
    super.imageUrls = const [],
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toUpperCase() ?? 'MULTIPLE_CHOICE';
    final type = typeStr == 'WRITTEN' ? ExamQuestionType.written : ExamQuestionType.multipleChoice;

    return ExamQuestionModel(
      id: json['id']?.toString() ?? '',
      type: type,
      prompt: json['prompt']?.toString() ?? '',
      choices: (json['choices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      correctChoice: (json['correctChoice'] as num?)?.toInt(),
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == ExamQuestionType.written ? 'WRITTEN' : 'MULTIPLE_CHOICE',
      'prompt': prompt,
      'choices': choices,
      if (correctChoice != null) 'correctChoice': correctChoice,
      'imageUrls': imageUrls,
    };
  }
}

class ExamModel extends ExamEntity {
  const ExamModel({
    required super.id,
    required super.courseId,
    super.tutorId,
    required super.title,
    super.instructions,
    super.points = 50,
    super.published = false,
    required super.questions,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      tutorId: json['tutorId']?.toString(),
      title: json['title']?.toString() ?? '',
      instructions: json['instructions']?.toString(),
      points: (json['points'] as num?)?.toInt() ?? 50,
      published: json['published'] == true,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => ExamQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'instructions': instructions,
      'points': points,
      'published': published,
      'questions': questions.map((q) {
        if (q is ExamQuestionModel) return q.toJson();
        return {
          'id': q.id,
          'type': q.type == ExamQuestionType.written ? 'WRITTEN' : 'MULTIPLE_CHOICE',
          'prompt': q.prompt,
          'choices': q.choices,
          if (q.correctChoice != null) 'correctChoice': q.correctChoice,
          'imageUrls': q.imageUrls,
        };
      }).toList(),
    };
  }
}

class ExamAnswerModel extends ExamAnswerEntity {
  const ExamAnswerModel({
    required super.questionId,
    super.choice,
    super.text,
  });

  factory ExamAnswerModel.fromJson(Map<String, dynamic> json) {
    return ExamAnswerModel(
      questionId: json['questionId']?.toString() ?? '',
      choice: (json['choice'] as num?)?.toInt(),
      text: json['text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      if (choice != null) 'choice': choice,
      if (text != null) 'text': text,
    };
  }
}

class ExamSubmissionModel extends ExamSubmissionEntity {
  const ExamSubmissionModel({
    required super.id,
    required super.examId,
    required super.studentId,
    required super.status,
    super.score,
    super.feedback,
    required super.answers,
    super.attachmentUrls = const [],
    super.submittedAt,
    super.gradedAt,
    super.publishedAt,
    super.examTitle,
  });

  factory ExamSubmissionModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase() ?? 'SUBMITTED';
    ExamSubmissionStatus status;
    switch (statusStr) {
      case 'GRADED':
        status = ExamSubmissionStatus.graded;
        break;
      case 'PUBLISHED':
        status = ExamSubmissionStatus.published;
        break;
      default:
        status = ExamSubmissionStatus.submitted;
    }

    return ExamSubmissionModel(
      id: json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      status: status,
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback']?.toString(),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => ExamAnswerModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      gradedAt: json['gradedAt'] != null ? DateTime.tryParse(json['gradedAt'].toString()) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'].toString()) : null,
      examTitle: json['exam'] is Map<String, dynamic> ? json['exam']['title']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a is ExamAnswerModel ? a.toJson() : {'questionId': a.questionId, 'choice': a.choice, 'text': a.text}).toList(),
      'attachmentUrls': attachmentUrls,
    };
  }
}
