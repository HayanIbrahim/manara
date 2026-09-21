import 'package:equatable/equatable.dart';
import '../../../domain/entities/exam_entities.dart';

abstract class ExamState extends Equatable {
  const ExamState();
  @override
  List<Object?> get props => [];
}

class ExamInitial extends ExamState {}

class ExamLoading extends ExamState {}

class ExamActive extends ExamState {
  final ExamEntity exam;
  final Map<String, ExamAnswerEntity> answers; // questionId -> answer
  final List<String> attachmentUrls;
  final bool isSubmitting;

  const ExamActive({
    required this.exam,
    this.answers = const {},
    this.attachmentUrls = const [],
    this.isSubmitting = false,
  });

  ExamActive copyWith({
    ExamEntity? exam,
    Map<String, ExamAnswerEntity>? answers,
    List<String>? attachmentUrls,
    bool? isSubmitting,
  }) {
    return ExamActive(
      exam: exam ?? this.exam,
      answers: answers ?? this.answers,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [exam, answers, attachmentUrls, isSubmitting];
}

class ExamSubmissionSuccess extends ExamState {
  final ExamSubmissionEntity submission;
  const ExamSubmissionSuccess(this.submission);

  @override
  List<Object?> get props => [submission];
}

class ExamResultsLoaded extends ExamState {
  final List<ExamSubmissionEntity> results;
  const ExamResultsLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class ExamError extends ExamState {
  final String message;
  const ExamError(this.message);

  @override
  List<Object?> get props => [message];
}
