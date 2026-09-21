import '../../domain/entities/course_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/remote/api_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final ApiDataSource _apiDataSource;

  CatalogRepositoryImpl(this._apiDataSource);

  @override
  Future<List<SubjectEntity>> getSubjects() async {
    return await _apiDataSource.getSubjects();
  }

  @override
  Future<List<CourseEntity>> searchCourses({
    String? query,
    String? subjectId,
    String? tutorId,
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiDataSource.searchCourses(
      query: query,
      subjectId: subjectId,
      tutorId: tutorId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<CourseEntity> getCourseDetails(String courseId) async {
    return await _apiDataSource.getCourseDetails(courseId);
  }

  @override
  Future<Map<String, dynamic>> getTutorProfile(String tutorId) async {
    return await _apiDataSource.getTutorProfile(tutorId);
  }
}
