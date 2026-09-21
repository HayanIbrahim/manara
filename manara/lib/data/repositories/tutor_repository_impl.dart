import '../../domain/entities/course_entities.dart';
import '../../domain/entities/exam_entities.dart';
import '../../domain/entities/quiz_entities.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../datasources/remote/api_data_source.dart';

class TutorRepositoryImpl implements TutorRepository {
  final ApiDataSource _apiDataSource;

  TutorRepositoryImpl(this._apiDataSource);

  @override
  Future<List<CourseEntity>> getTutorCourses() async {
    return await _apiDataSource.getTutorCourses();
  }

  @override
  Future<CourseEntity> createCourse({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    required String subjectId,
  }) async {
    return await _apiDataSource.createCourse(
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      subjectId: subjectId,
    );
  }

  @override
  Future<CourseEntity> updateCourse({
    required String courseId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    bool? published,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (price != null) data['price'] = price;
    if (published != null) data['published'] = published;

    return await _apiDataSource.updateCourse(courseId, data);
  }

  @override
  Future<LectureEntity> createLecture({
    required String courseId,
    required String title,
    String? description,
    required int position,
    required String videoUrl,
    List<String> pdfUrls = const [],
    int points = 10,
  }) async {
    return await _apiDataSource.createLecture(courseId, {
      'title': title,
      'description': ?description,
      'position': position,
      'videoUrl': videoUrl,
      'pdfUrls': pdfUrls,
      'points': points,
      'published': false,
    });
  }

  @override
  Future<LectureEntity> updateLecture({
    required String lectureId,
    String? title,
    String? description,
    int? position,
    String? videoUrl,
    List<String> pdfUrls = const [],
    int? points,
    bool? published,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (position != null) data['position'] = position;
    if (videoUrl != null) data['videoUrl'] = videoUrl;
    if (pdfUrls.isNotEmpty) data['pdfUrls'] = pdfUrls;
    if (points != null) data['points'] = points;
    if (published != null) data['published'] = published;

    return await _apiDataSource.updateLecture(lectureId, data);
  }

  @override
  Future<void> deleteLecture(String lectureId) async {
    await _apiDataSource.deleteLecture(lectureId);
  }

  @override
  Future<QuizEntity> putLectureQuiz({
    required String lectureId,
    required List<QuizQuestionEntity> questions,
  }) async {
    final rawQuestions = questions.map((q) => {
      'prompt': q.prompt,
      'choices': q.choices,
      if (q.correctChoice != null) 'correctChoice': q.correctChoice,
    }).toList();

    return await _apiDataSource.putLectureQuiz(lectureId, rawQuestions);
  }

  @override
  Future<ExamEntity> createExam({
    required String courseId,
    required String title,
    String? instructions,
    int points = 50,
    required List<ExamQuestionEntity> questions,
  }) async {
    final rawQuestions = questions.map((q) => {
      'id': q.id,
      'type': q.isWritten ? 'WRITTEN' : 'MULTIPLE_CHOICE',
      'prompt': q.prompt,
      if (!q.isWritten) 'choices': q.choices,
      if (!q.isWritten && q.correctChoice != null) 'correctChoice': q.correctChoice,
      'imageUrls': q.imageUrls,
    }).toList();

    return await _apiDataSource.createExam(courseId, {
      'title': title,
      'instructions': ?instructions,
      'points': points,
      'published': false,
      'questions': rawQuestions,
    });
  }

  @override
  Future<List<ExamSubmissionEntity>> getExamSubmissions(String examId) async {
    return await _apiDataSource.getExamSubmissions(examId);
  }

  @override
  Future<ExamSubmissionEntity> gradeExamSubmission({
    required String submissionId,
    required double score,
    String? feedback,
    bool publish = false,
  }) async {
    return await _apiDataSource.gradeExamSubmission(
      submissionId: submissionId,
      score: score,
      feedback: feedback,
      publish: publish,
    );
  }
}
