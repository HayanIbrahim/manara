import '../entities/course_entities.dart';

abstract class CatalogRepository {
  Future<List<SubjectEntity>> getSubjects();

  Future<List<CourseEntity>> searchCourses({
    String? query,
    String? subjectId,
    String? tutorId,
    int page = 1,
    int limit = 20,
  });

  Future<CourseEntity> getCourseDetails(String courseId);

  Future<Map<String, dynamic>> getTutorProfile(String tutorId);
}
