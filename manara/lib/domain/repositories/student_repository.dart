import '../entities/course_entities.dart';
import '../entities/exam_entities.dart';
import '../entities/gamification_entities.dart';
import '../entities/quiz_entities.dart';

abstract class StudentRepository {
  Future<List<CourseEntity>> getEnrolledCourses();

  Future<Map<String, dynamic>> getCourseLearningState(String courseId);

  Future<QuizAttemptResultEntity> submitQuizAttempt({
    required String lectureId,
    required List<int> answers,
  });

  Future<ExamSubmissionEntity> submitExam({
    required String examId,
    required List<ExamAnswerEntity> answers,
    List<String> attachmentUrls = const [],
  });

  Future<List<ExamSubmissionEntity>> getExamResults();

  Future<RatingEntity> rateCourse({
    required String courseId,
    required int value,
    String? comment,
  });

  Future<RatingEntity> rateTutor({
    required String tutorId,
    required int value,
    String? comment,
  });
}
