import 'package:equatable/equatable.dart';
import '../../../domain/entities/exam_entities.dart';

abstract class ExamEvent extends Equatable {
  const ExamEvent();
  @override
  List<Object?> get props => [];
}

class ExamLoadRequested extends ExamEvent {
  final ExamEntity exam;
  const ExamLoadRequested(this.exam);

  @override
  List<Object?> get props => [exam];
}

class ExamAnswerUpdated extends ExamEvent {
  final String questionId;
  final int? choice;
  final String? text;

  const ExamAnswerUpdated({
    required this.questionId,
    this.choice,
    this.text,
  });

  @override
  List<Object?> get props => [questionId, choice, text];
}

class ExamAddAttachmentUrlRequested extends ExamEvent {
  final String url;
  const ExamAddAttachmentUrlRequested(this.url);

  @override
  List<Object?> get props => [url];
}

class ExamSubmitRequested extends ExamEvent {}

class ExamLoadResultsRequested extends ExamEvent {}
