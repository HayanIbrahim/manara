import '../../domain/entities/course_entities.dart';
import '../../domain/entities/exam_entities.dart';
import '../../domain/entities/gamification_entities.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/remote/api_data_source.dart';

class StudentRepositoryImpl implements StudentRepository {
  final ApiDataSource _apiDataSource;

  StudentRepositoryImpl(this._apiDataSource);

  @override
  Future<List<CourseEntity>> getEnrolledCourses() async {
    return await _apiDataSource.getStudentCourses();
  }

  @override
  Future<Map<String, dynamic>> getCourseLearningState(String courseId) async {
    return await _apiDataSource.getCourseLearningState(courseId);
  }

  @override
  Future<QuizAttemptResultEntity> submitQuizAttempt({
    required String lectureId,
    required List<int> answers,
  }) async {
    return await _apiDataSource.submitQuizAttempt(
      lectureId: lectureId,
      answers: answers,
    );
  }

  @override
  Future<ExamSubmissionEntity> submitExam({
    required String examId,
    required List<ExamAnswerEntity> answers,
    List<String> attachmentUrls = const [],
  }) async {
    final rawAnswers = answers.map((a) => {
      'questionId': a.questionId,
      if (a.choice != null) 'choice': a.choice,
      if (a.text != null) 'text': a.text,
    }).toList();

    return await _apiDataSource.submitExam(
      examId: examId,
      answers: rawAnswers,
      attachmentUrls: attachmentUrls,
    );
  }

  @override
  Future<List<ExamSubmissionEntity>> getExamResults() async {
    return await _apiDataSource.getExamResults();
  }

  @override
  Future<RatingEntity> rateCourse({
    required String courseId,
    required int value,
    String? comment,
  }) async {
    return await _apiDataSource.rateCourse(
      courseId: courseId,
      value: value,
      comment: comment,
    );
  }

  @override
  Future<RatingEntity> rateTutor({
    required String tutorId,
    required int value,
    String? comment,
  }) async {
    return await _apiDataSource.rateTutor(
      tutorId: tutorId,
      value: value,
      comment: comment,
    );
  }
}
