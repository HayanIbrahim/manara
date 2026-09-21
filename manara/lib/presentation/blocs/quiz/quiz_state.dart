import 'package:equatable/equatable.dart';
import '../../../domain/entities/quiz_entities.dart';

abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizActive extends QuizState {
  final String lectureId;
  final QuizEntity quiz;
  final Map<int, int> selectedChoices; // questionIndex -> choiceIndex
  final bool isSubmitting;
  final QuizAttemptResultEntity? result;

  const QuizActive({
    required this.lectureId,
    required this.quiz,
    this.selectedChoices = const {},
    this.isSubmitting = false,
    this.result,
  });

  bool get isAllAnswered => selectedChoices.length == quiz.questions.length && quiz.questions.isNotEmpty;

  QuizActive copyWith({
    String? lectureId,
    QuizEntity? quiz,
    Map<int, int>? selectedChoices,
    bool? isSubmitting,
    QuizAttemptResultEntity? result,
  }) {
    return QuizActive(
      lectureId: lectureId ?? this.lectureId,
      quiz: quiz ?? this.quiz,
      selectedChoices: selectedChoices ?? this.selectedChoices,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
        lectureId,
        quiz,
        selectedChoices,
        isSubmitting,
        result,
      ];
}

class QuizPassedSuccess extends QuizState {
  final QuizAttemptResultEntity result;
  const QuizPassedSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class QuizFailedRetry extends QuizState {
  final QuizAttemptResultEntity result;
  const QuizFailedRetry(this.result);

  @override
  List<Object?> get props => [result];
}

class QuizError extends QuizState {
  final String message;
  const QuizError(this.message);

  @override
  List<Object?> get props => [message];
}
