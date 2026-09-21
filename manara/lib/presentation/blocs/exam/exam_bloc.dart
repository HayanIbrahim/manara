import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../../domain/repositories/student_repository.dart';
import 'exam_event.dart';
import 'exam_state.dart';

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final StudentRepository _studentRepository;

  ExamBloc(this._studentRepository) : super(ExamInitial()) {
    on<ExamLoadRequested>(_onLoadRequested);
    on<ExamAnswerUpdated>(_onAnswerUpdated);
    on<ExamAddAttachmentUrlRequested>(_onAddAttachment);
    on<ExamSubmitRequested>(_onSubmitRequested);
    on<ExamLoadResultsRequested>(_onLoadResultsRequested);
  }

  void _onLoadRequested(ExamLoadRequested event, Emitter<ExamState> emit) {
    emit(ExamActive(exam: event.exam));
  }

  void _onAnswerUpdated(ExamAnswerUpdated event, Emitter<ExamState> emit) {
    final currentState = state;
    if (currentState is ExamActive) {
      final updated = Map<String, ExamAnswerEntity>.from(currentState.answers);
      updated[event.questionId] = ExamAnswerEntity(
        questionId: event.questionId,
        choice: event.choice,
        text: event.text,
      );
      emit(currentState.copyWith(answers: updated));
    }
  }

  void _onAddAttachment(ExamAddAttachmentUrlRequested event, Emitter<ExamState> emit) {
    final currentState = state;
    if (currentState is ExamActive) {
      final updated = List<String>.from(currentState.attachmentUrls)..add(event.url);
      emit(currentState.copyWith(attachmentUrls: updated));
    }
  }

  Future<void> _onSubmitRequested(ExamSubmitRequested event, Emitter<ExamState> emit) async {
    final currentState = state;
    if (currentState is! ExamActive) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      final submission = await _studentRepository.submitExam(
        examId: currentState.exam.id,
        answers: currentState.answers.values.toList(),
        attachmentUrls: currentState.attachmentUrls,
      );
      emit(ExamSubmissionSuccess(submission));
    } catch (e) {
      emit(ExamError(e.toString()));
    }
  }

  Future<void> _onLoadResultsRequested(ExamLoadResultsRequested event, Emitter<ExamState> emit) async {
    emit(ExamLoading());
    try {
      final results = await _studentRepository.getExamResults();
      emit(ExamResultsLoaded(results));
    } catch (e) {
      emit(ExamError(e.toString()));
    }
  }
}
