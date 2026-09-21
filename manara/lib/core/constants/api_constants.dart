class ApiConstants {
  static const String serverRootUrl = 'https://manara-ifnk.onrender.com';
  static const String defaultBaseUrl = 'https://manara-ifnk.onrender.com/api/v1/';
  static const String healthEndpoint = 'https://manara-ifnk.onrender.com/health';

  // Auth
  static const String adminLogin = '/auth/admin/login';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Desktop QR
  static const String desktopChallenges = '/desktop/challenges';
  static String desktopChallengeStatus(String challenge) => '/desktop/challenges/$challenge/status';
  static String desktopChallengeAuthorize(String challenge) => '/desktop/challenges/$challenge/authorize';
  static String desktopChallengeExchange(String challenge) => '/desktop/challenges/$challenge/exchange';
  static const String desktopSessionCurrent = '/desktop/sessions/current';

  // Public Catalog
  static const String subjects = '/subjects';
  static const String courses = '/courses';
  static String courseDetails(String id) => '/courses/$id';
  static String tutorProfile(String id) => '/tutors/$id';

  // Gamification
  static const String leaderboard = '/leaderboard';

  // Student
  static const String studentCourses = '/student/courses';
  static String studentCourseLearning(String courseId) => '/student/courses/$courseId/learning';
  static String studentQuizAttempts(String lectureId) => '/student/lectures/$lectureId/quiz-attempts';
  static String studentExamSubmissions(String examId) => '/student/exams/$examId/submissions';
  static const String studentExamResults = '/student/exam-results';
  static String studentRateCourse(String courseId) => '/student/ratings/course/$courseId';
  static String studentRateTutor(String tutorId) => '/student/ratings/tutor/$tutorId';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentAchievements = '/student/achievements';

  // Tutor
  static const String tutorCourses = '/tutor/courses';
  static String tutorCourse(String id) => '/tutor/courses/$id';
  static String tutorCourseLectures(String courseId) => '/tutor/courses/$courseId/lectures';
  static String tutorLecture(String lectureId) => '/tutor/lectures/$lectureId';
  static String tutorLectureQuiz(String lectureId) => '/tutor/lectures/$lectureId/quiz';
  static String tutorCourseExams(String courseId) => '/tutor/courses/$courseId/exams';
  static String tutorExam(String examId) => '/tutor/exams/$examId';
  static String tutorExamSubmissions(String examId) => '/tutor/exams/$examId/submissions';
  static String tutorGradeSubmission(String submissionId) => '/tutor/submissions/$submissionId/grade';

  // Headers
  static const String headerDeviceId = 'x-device-id';
  static const String headerAuthorization = 'Authorization';
}
