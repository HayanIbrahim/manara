import 'package:equatable/equatable.dart';
import '../../../domain/entities/quiz_entities.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object?> get props => [];
}

class QuizInitializeRequested extends QuizEvent {
  final String lectureId;
  final QuizEntity quiz;

  const QuizInitializeRequested({required this.lectureId, required this.quiz});

  @override
  List<Object?> get props => [lectureId, quiz];
}

class QuizSelectChoiceRequested extends QuizEvent {
  final int questionIndex;
  final int choiceIndex;

  const QuizSelectChoiceRequested({
    required this.questionIndex,
    required this.choiceIndex,
  });

  @override
  List<Object?> get props => [questionIndex, choiceIndex];
}

class QuizSubmitAttemptRequested extends QuizEvent {}

class QuizResetRequested extends QuizEvent {}
