import '../entities/course_entities.dart';
import '../entities/exam_entities.dart';
import '../entities/quiz_entities.dart';

abstract class TutorRepository {
  Future<List<CourseEntity>> getTutorCourses();

  Future<CourseEntity> createCourse({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    required String subjectId,
  });

  Future<CourseEntity> updateCourse({
    required String courseId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    bool? published,
  });

  Future<LectureEntity> createLecture({
    required String courseId,
    required String title,
    String? description,
    required int position,
    required String videoUrl,
    List<String> pdfUrls = const [],
    int points = 10,
  });

  Future<LectureEntity> updateLecture({
    required String lectureId,
    String? title,
    String? description,
    int? position,
    String? videoUrl,
    List<String> pdfUrls = const [],
    int? points,
    bool? published,
  });

  Future<void> deleteLecture(String lectureId);

  Future<QuizEntity> putLectureQuiz({
    required String lectureId,
    required List<QuizQuestionEntity> questions,
  });

  Future<ExamEntity> createExam({
    required String courseId,
    required String title,
    String? instructions,
    int points = 50,
    required List<ExamQuestionEntity> questions,
  });

  Future<List<ExamSubmissionEntity>> getExamSubmissions(String examId);

  Future<ExamSubmissionEntity> gradeExamSubmission({
    required String submissionId,
    required double score,
    String? feedback,
    bool publish = false,
  });
}
