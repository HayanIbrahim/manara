class ApiConstants {
  static const String defaultBaseUrl = 'https://manara-ifnk.onrender.com/api/v1/';
  static const String serverRootUrl = 'https://manara-ifnk.onrender.com';
  static const String healthEndpoint = '/health';

  // Admin Auth
  static const String adminLogin = '/auth/admin/login';
  static const String me = '/auth/me';

  // Subjects Management
  static const String adminSubjects = '/admin/subjects';
  static String adminSubject(String id) => '/admin/subjects/$id';

  // Signup Codes Management
  static const String adminSignupCodes = '/admin/signup-codes';

  // User Accounts & Device Reset
  static const String adminUsers = '/admin/users';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static String adminUserDeviceReset(String id) => '/admin/users/$id/device-reset';

  // Tutor Subject Mapping
  static String adminTutorSubject(String tutorId, String subjectId) =>
      '/admin/tutors/$tutorId/subjects/$subjectId';

  // Student Course Access
  static String adminStudentCourse(String studentId, String courseId) =>
      '/admin/students/$studentId/courses/$courseId';

  // Announcements
  static const String adminAnnouncements = '/admin/announcements';

  // Public Catalog for reference
  static const String publicCourses = '/courses';

  // Headers
  static const String headerAuthorization = 'Authorization';
}
