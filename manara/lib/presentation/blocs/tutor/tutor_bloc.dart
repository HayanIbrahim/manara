import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/tutor_repository.dart';
import 'tutor_event.dart';
import 'tutor_state.dart';

class TutorBloc extends Bloc<TutorEvent, TutorState> {
  final TutorRepository _tutorRepository;

  TutorBloc(this._tutorRepository) : super(TutorInitial()) {
    on<TutorLoadCoursesRequested>(_onLoadCourses);
    on<TutorCreateCourseSubmitted>(_onCreateCourse);
    on<TutorCreateLectureSubmitted>(_onCreateLecture);
    on<TutorPutQuizSubmitted>(_onPutQuiz);
    on<TutorPublishLectureSubmitted>(_onPublishLecture);
    on<TutorDeleteLectureSubmitted>(_onDeleteLecture);
    on<TutorPublishCourseSubmitted>(_onPublishCourse);
    on<TutorCreateExamSubmitted>(_onCreateExam);
    on<TutorLoadSubmissionsRequested>(_onLoadSubmissions);
    on<TutorGradeSubmissionSubmitted>(_onGradeSubmission);
  }

  Future<void> _onLoadCourses(TutorLoadCoursesRequested event, Emitter<TutorState> emit) async {
    emit(TutorLoading());
    try {
      final courses = await _tutorRepository.getTutorCourses();
      emit(TutorCoursesLoaded(courses: courses));
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onCreateCourse(TutorCreateCourseSubmitted event, Emitter<TutorState> emit) async {
    emit(TutorLoading());
    try {
      await _tutorRepository.createCourse(
        name: event.name,
        description: event.description,
        imageUrl: event.imageUrl,
        price: event.price,
        subjectId: event.subjectId,
      );
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onCreateLecture(TutorCreateLectureSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.createLecture(
        courseId: event.courseId,
        title: event.title,
        description: event.description,
        position: event.position,
        videoUrl: event.videoUrl,
        pdfUrls: event.pdfUrls,
      );
      emit(const TutorActionSuccess('Lecture created successfully!'));
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onPutQuiz(TutorPutQuizSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.putLectureQuiz(
        lectureId: event.lectureId,
        questions: event.questions,
      );
      emit(const TutorActionSuccess('Quiz saved successfully!'));
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onPublishLecture(TutorPublishLectureSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.updateLecture(
        lectureId: event.lectureId,
        published: event.published,
      );
      emit(TutorActionSuccess(event.published ? 'Lecture published successfully!' : 'Lecture unpublished!'));
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onDeleteLecture(TutorDeleteLectureSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.deleteLecture(event.lectureId);
      emit(const TutorActionSuccess('Lecture deleted successfully!'));
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onPublishCourse(TutorPublishCourseSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.updateCourse(
        courseId: event.courseId,
        published: event.published,
      );
      emit(TutorActionSuccess(event.published ? 'Course published successfully!' : 'Course unpublished!'));
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onCreateExam(TutorCreateExamSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.createExam(
        courseId: event.courseId,
        title: event.title,
        instructions: event.instructions,
        points: event.points,
        questions: event.questions,
      );
      emit(const TutorActionSuccess('Exam created successfully!'));
      add(TutorLoadCoursesRequested());
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onLoadSubmissions(TutorLoadSubmissionsRequested event, Emitter<TutorState> emit) async {
    try {
      final subs = await _tutorRepository.getExamSubmissions(event.examId);
      final currentState = state;
      if (currentState is TutorCoursesLoaded) {
        emit(TutorCoursesLoaded(courses: currentState.courses, submissions: subs));
      } else {
        emit(TutorCoursesLoaded(courses: const [], submissions: subs));
      }
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }

  Future<void> _onGradeSubmission(TutorGradeSubmissionSubmitted event, Emitter<TutorState> emit) async {
    try {
      await _tutorRepository.gradeExamSubmission(
        submissionId: event.submissionId,
        score: event.score,
        feedback: event.feedback,
        publish: event.publish,
      );
      emit(const TutorActionSuccess('Submission graded successfully!'));
    } catch (e) {
      emit(TutorError(e.toString()));
    }
  }
}
