import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<Map<String, dynamic>> login({required String username, required String password});
  Future<AdminUserModel> getCurrentAdmin();

  Future<List<SubjectModel>> getSubjects();
  Future<SubjectModel> createSubject({required String name, required String code, String? description, String? iconUrl});
  Future<SubjectModel> updateSubject({required String id, String? name, String? code, String? description, String? iconUrl});
  Future<void> deleteSubject(String id);

  Future<List<SignupCodeModel>> getSignupCodes();
  Future<SignupCodeModel> generateSignupCode({required String role, DateTime? expiresAt});

  Future<List<AccountUserModel>> getUsers({String? role, String? status, String? search});
  Future<AccountUserModel> updateUserStatus({required String id, required String status});
  Future<AccountUserModel> resetUserDevice(String id);

  Future<void> assignTutorSubject({required String tutorId, required String subjectId});
  Future<void> unassignTutorSubject({required String tutorId, required String subjectId});
  Future<void> grantStudentCourse({required String studentId, required String courseId});
  Future<void> revokeStudentCourse({required String studentId, required String courseId});

  Future<List<AnnouncementModel>> getAnnouncements();
  Future<AnnouncementModel> createAnnouncement({required String title, required String message, String targetRole = 'ALL', String? courseId});
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _client;

  const AdminRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> login({required String username, required String password}) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.adminLogin,
      data: {'username': username, 'password': password},
    );
    return res.data ?? {};
  }

  @override
  Future<AdminUserModel> getCurrentAdmin() async {
    final res = await _client.get<Map<String, dynamic>>(ApiConstants.me);
    final data = res.data ?? {};
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    return AdminUserModel.fromJson(userMap);
  }

  @override
  Future<List<SubjectModel>> getSubjects() async {
    final res = await _client.get(ApiConstants.adminSubjects);
    final data = res.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List;
    }
    return items.map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SubjectModel> createSubject({required String name, required String code, String? description, String? iconUrl}) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.adminSubjects,
      data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (iconUrl != null && iconUrl.isNotEmpty) 'imageUrl': iconUrl,
      },
    );
    return SubjectModel.fromJson(res.data ?? {});
  }

  @override
  Future<SubjectModel> updateSubject({required String id, String? name, String? code, String? description, String? iconUrl}) async {
    final res = await _client.patch<Map<String, dynamic>>(
      ApiConstants.adminSubject(id),
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
        'description': ?description,
        'imageUrl': ?iconUrl,
      },
    );
    return SubjectModel.fromJson(res.data ?? {});
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _client.delete(ApiConstants.adminSubject(id));
  }

  @override
  Future<List<SignupCodeModel>> getSignupCodes() async {
    final res = await _client.get(ApiConstants.adminSignupCodes);
    final data = res.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      if (data['items'] is List) {
        items = data['items'] as List;
      } else if (data['data'] is List) {
        items = data['data'] as List;
      } else if (data['codes'] is List) {
        items = data['codes'] as List;
      }
    }
    return items.map((e) => SignupCodeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SignupCodeModel> generateSignupCode({required String role, DateTime? expiresAt}) async {
    final hours = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inHours
        : 72;

    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.adminSignupCodes,
      data: {
        'role': role,
        'expiresInHours': (hours > 0 && hours <= 720) ? hours : 72,
      },
    );
    final raw = res.data ?? {};
    final dataMap = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : (raw['item'] is Map<String, dynamic>)
            ? raw['item'] as Map<String, dynamic>
            : raw;
    return SignupCodeModel.fromJson(dataMap);
  }

  @override
  Future<List<AccountUserModel>> getUsers({String? role, String? status, String? search}) async {
    final query = <String, dynamic>{};
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final res = await _client.get(ApiConstants.adminUsers, queryParameters: query);
    final data = res.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List;
    }
    return items.map((e) => AccountUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AccountUserModel> updateUserStatus({required String id, required String status}) async {
    final res = await _client.patch<Map<String, dynamic>>(
      ApiConstants.adminUserStatus(id),
      data: {'status': status},
    );
    return AccountUserModel.fromJson(res.data ?? {});
  }

  @override
  Future<AccountUserModel> resetUserDevice(String id) async {
    final res = await _client.post<Map<String, dynamic>>(ApiConstants.adminUserDeviceReset(id));
    return AccountUserModel.fromJson(res.data ?? {});
  }

  @override
  Future<void> assignTutorSubject({required String tutorId, required String subjectId}) async {
    await _client.put(ApiConstants.adminTutorSubject(tutorId, subjectId));
  }

  @override
  Future<void> unassignTutorSubject({required String tutorId, required String subjectId}) async {
    await _client.delete(ApiConstants.adminTutorSubject(tutorId, subjectId));
  }

  @override
  Future<void> grantStudentCourse({required String studentId, required String courseId}) async {
    await _client.put(ApiConstants.adminStudentCourse(studentId, courseId));
  }

  @override
  Future<void> revokeStudentCourse({required String studentId, required String courseId}) async {
    await _client.delete(ApiConstants.adminStudentCourse(studentId, courseId));
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final res = await _client.get(ApiConstants.adminAnnouncements);
    final data = res.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List;
    }
    return items.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String message,
    String targetRole = 'ALL',
    String? courseId,
  }) async {
    final audience = targetRole == 'COURSE'
        ? 'COURSE'
        : (targetRole == 'STUDENT' || targetRole == 'STUDENTS' ? 'STUDENTS' : 'ALL');
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.adminAnnouncements,
      data: {
        'title': title,
        'body': message,
        'audience': audience,
        'courseIds': (courseId != null && courseId.isNotEmpty) ? [courseId] : <String>[],
        'studentIds': <String>[],
      },
    );
    return AnnouncementModel.fromJson(res.data ?? {});
  }
}
