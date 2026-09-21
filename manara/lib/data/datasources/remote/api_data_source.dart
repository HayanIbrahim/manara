import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/course_model.dart';
import '../../models/desktop_model.dart';
import '../../models/exam_model.dart';
import '../../models/gamification_model.dart';
import '../../models/quiz_model.dart';
import '../../models/user_model.dart';

class ApiDataSource {
  final ApiClient _client;

  ApiDataSource(this._client);

  // ================= AUTH ================= //
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final res = await _client.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
        'device_id': deviceId,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String signupCode,
    required String role,
    required String username,
    String? email,
    required String displayName,
    required String password,
    required String deviceId,
  }) async {
    final res = await _client.post(
      ApiConstants.register,
      data: {
        'signupCode': signupCode,
        'role': role,
        'username': username,
        if (email != null && email.isNotEmpty) 'email': email,
        'displayName': displayName,
        'password': password,
        'device_id': deviceId,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final res = await _client.get(ApiConstants.me);
    final data = res.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final sessionType = data['sessionType']?.toString() ?? 'mobile';
    return {
      'user': user,
      'sessionType': sessionType,
    };
  }

  // ================= DESKTOP QR ================= //
  Future<DesktopChallengeModel> createDesktopChallenge() async {
    final res = await _client.post(ApiConstants.desktopChallenges);
    return DesktopChallengeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DesktopStatusModel> getDesktopChallengeStatus(String challenge) async {
    final res = await _client.get(ApiConstants.desktopChallengeStatus(challenge));
    return DesktopStatusModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DesktopStatusModel> authorizeDesktopChallenge(String challenge) async {
    final res = await _client.post(ApiConstants.desktopChallengeAuthorize(challenge));
    return DesktopStatusModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> exchangeDesktopChallenge(String challenge) async {
    final res = await _client.post(ApiConstants.desktopChallengeExchange(challenge));
    return res.data as Map<String, dynamic>;
  }

  Future<void> closeDesktopSession() async {
    try {
      await _client.delete(ApiConstants.desktopSessionCurrent);
    } catch (_) {}
  }

  // ================= CATALOG ================= //
  Future<List<SubjectModel>> getSubjects() async {
    final res = await _client.get(ApiConstants.subjects);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CourseModel>> searchCourses({
    String? query,
    String? subjectId,
    String? tutorId,
    int page = 1,
    int limit = 20,
  }) async {
    final qParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query != null && query.isNotEmpty) qParams['q'] = query;
    if (subjectId != null && subjectId.isNotEmpty) qParams['subjectId'] = subjectId;
    if (tutorId != null && tutorId.isNotEmpty) qParams['tutorId'] = tutorId;

    final res = await _client.get(ApiConstants.courses, queryParameters: qParams);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CourseModel> getCourseDetails(String courseId) async {
    final res = await _client.get(ApiConstants.courseDetails(courseId));
    return CourseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTutorProfile(String tutorId) async {
    final res = await _client.get(ApiConstants.tutorProfile(tutorId));
    return res.data as Map<String, dynamic>;
  }

  // ================= STUDENT ================= //
  Future<List<CourseModel>> getStudentCourses() async {
    final res = await _client.get(ApiConstants.studentCourses);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getCourseLearningState(String courseId) async {
    final res = await _client.get(ApiConstants.studentCourseLearning(courseId));
    final data = res.data as Map<String, dynamic>;
    final courseData = (data['course'] is Map<String, dynamic>)
        ? data['course'] as Map<String, dynamic>
        : data;

    final course = CourseModel.fromJson(courseData);
    final lecturesRaw = (courseData['lectures'] is List)
        ? courseData['lectures'] as List<dynamic>
        : (data['lectures'] as List<dynamic>? ?? []);
    final lectures = lecturesRaw.map((e) => LectureModel.fromJson(e as Map<String, dynamic>)).toList();
    final examsRaw = (courseData['exams'] is List)
        ? courseData['exams'] as List<dynamic>
        : (data['exams'] as List<dynamic>? ?? []);
    final exams = examsRaw.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'course': course,
      'lectures': lectures,
      'exams': exams,
    };
  }

  Future<QuizAttemptResultModel> submitQuizAttempt({
    required String lectureId,
    required List<int> answers,
  }) async {
    final res = await _client.post(
      ApiConstants.studentQuizAttempts(lectureId),
      data: {'answers': answers},
    );
    return QuizAttemptResultModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ExamSubmissionModel> submitExam({
    required String examId,
    required List<Map<String, dynamic>> answers,
    List<String> attachmentUrls = const [],
  }) async {
    final res = await _client.post(
      ApiConstants.studentExamSubmissions(examId),
      data: {
        'answers': answers,
        'attachmentUrls': attachmentUrls,
      },
    );
    return ExamSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ExamSubmissionModel>> getExamResults() async {
    final res = await _client.get(ApiConstants.studentExamResults);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => ExamSubmissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RatingModel> rateCourse({
    required String courseId,
    required int value,
    String? comment,
  }) async {
    final res = await _client.put(
      ApiConstants.studentRateCourse(courseId),
      data: {
        'value': value,
        'comment': ?comment,
      },
    );
    return RatingModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RatingModel> rateTutor({
    required String tutorId,
    required int value,
    String? comment,
  }) async {
    final res = await _client.put(
      ApiConstants.studentRateTutor(tutorId),
      data: {
        'value': value,
        'comment': ?comment,
      },
    );
    return RatingModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ================= TUTOR ================= //
  Future<List<CourseModel>> getTutorCourses() async {
    final res = await _client.get(ApiConstants.tutorCourses);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CourseModel> createCourse({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    required String subjectId,
  }) async {
    final res = await _client.post(
      ApiConstants.tutorCourses,
      data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'subjectId': subjectId,
        'published': false,
      },
    );
    return CourseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CourseModel> updateCourse(String courseId, Map<String, dynamic> data) async {
    final res = await _client.patch(ApiConstants.tutorCourse(courseId), data: data);
    return CourseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LectureModel> createLecture(String courseId, Map<String, dynamic> data) async {
    final res = await _client.post(ApiConstants.tutorCourseLectures(courseId), data: data);
    return LectureModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LectureModel> updateLecture(String lectureId, Map<String, dynamic> data) async {
    final res = await _client.patch(ApiConstants.tutorLecture(lectureId), data: data);
    return LectureModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteLecture(String lectureId) async {
    await _client.delete(ApiConstants.tutorLecture(lectureId));
  }

  Future<QuizModel> putLectureQuiz(String lectureId, List<Map<String, dynamic>> questions) async {
    final res = await _client.put(
      ApiConstants.tutorLectureQuiz(lectureId),
      data: {'questions': questions},
    );
    return QuizModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ExamModel> createExam(String courseId, Map<String, dynamic> data) async {
    final res = await _client.post(ApiConstants.tutorCourseExams(courseId), data: data);
    return ExamModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ExamSubmissionModel>> getExamSubmissions(String examId) async {
    final res = await _client.get(ApiConstants.tutorExamSubmissions(examId));
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => ExamSubmissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExamSubmissionModel> gradeExamSubmission({
    required String submissionId,
    required double score,
    String? feedback,
    bool publish = false,
  }) async {
    final res = await _client.patch(
      ApiConstants.tutorGradeSubmission(submissionId),
      data: {
        'score': score,
        'feedback': ?feedback,
        'publish': publish,
      },
    );
    return ExamSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ================= GAMIFICATION ================= //
  Future<List<LeaderboardEntryModel>> getLeaderboard() async {
    final res = await _client.get(ApiConstants.leaderboard);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AchievementModel>> getStudentAchievements() async {
    final res = await _client.get(ApiConstants.studentAchievements);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnnouncementModel>> getStudentAnnouncements() async {
    final res = await _client.get(ApiConstants.studentAnnouncements);
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
