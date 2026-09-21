import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/student_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final StudentRepository _studentRepository;

  QuizBloc(this._studentRepository) : super(QuizInitial()) {
    on<QuizInitializeRequested>(_onInitialize);
    on<QuizSelectChoiceRequested>(_onSelectChoice);
    on<QuizSubmitAttemptRequested>(_onSubmitAttempt);
    on<QuizResetRequested>(_onReset);
  }

  void _onInitialize(
    QuizInitializeRequested event,
    Emitter<QuizState> emit,
  ) {
    emit(QuizActive(
      lectureId: event.lectureId,
      quiz: event.quiz,
      selectedChoices: const {},
    ));
  }

  void _onSelectChoice(
    QuizSelectChoiceRequested event,
    Emitter<QuizState> emit,
  ) {
    final currentState = state;
    if (currentState is QuizActive) {
      final updatedChoices = Map<int, int>.from(currentState.selectedChoices);
      updatedChoices[event.questionIndex] = event.choiceIndex;
      emit(currentState.copyWith(selectedChoices: updatedChoices));
    }
  }

  Future<void> _onSubmitAttempt(
    QuizSubmitAttemptRequested event,
    Emitter<QuizState> emit,
  ) async {
    final currentState = state;
    if (currentState is! QuizActive) return;

    final choices = currentState.selectedChoices;
    final questions = currentState.quiz.questions;

    // Convert map to list ordered by index
    final answersList = <int>[];
    for (int i = 0; i < questions.length; i++) {
      answersList.add(choices[i] ?? 0);
    }

    emit(currentState.copyWith(isSubmitting: true));

    try {
      final result = await _studentRepository.submitQuizAttempt(
        lectureId: currentState.lectureId,
        answers: answersList,
      );

      if (result.passed) {
        emit(QuizPassedSuccess(result));
      } else {
        emit(QuizFailedRetry(result));
      }
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onReset(
    QuizResetRequested event,
    Emitter<QuizState> emit,
  ) {
    final currentState = state;
    if (currentState is QuizFailedRetry) {
      // Return to active with empty choices
      emit(QuizInitial());
    } else if (currentState is QuizActive) {
      emit(currentState.copyWith(selectedChoices: const {}));
    }
  }
}
