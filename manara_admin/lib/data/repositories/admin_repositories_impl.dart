import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repositories.dart';
import '../datasources/local/admin_local_data_source.dart';
import '../datasources/remote/admin_remote_data_source.dart';
import '../models/admin_models.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminRemoteDataSource _remote;
  final AdminLocalDataSource _local;

  const AdminAuthRepositoryImpl(this._remote, this._local);

  @override
  Future<AdminUserEntity> login({required String username, required String password}) async {
    final res = await _remote.login(username: username, password: password);
    final token = res['accessToken']?.toString() ?? '';
    final userMap = res['user'] as Map<String, dynamic>? ?? {};
    final user = AdminUserModel.fromJson(userMap);

    await _local.saveToken(token);
    await _local.saveCurrentAdmin(user);
    return user;
  }

  @override
  Future<AdminUserEntity?> getCurrentAdmin() async {
    final token = await _local.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _remote.getCurrentAdmin();
      await _local.saveCurrentAdmin(user);
      return user;
    } catch (_) {
      // If the token is rejected by the server (401 / expired), purge local session
      await _local.purgeSession();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _local.purgeSession();
  }

  @override
  Future<String?> getSavedToken() async {
    return await _local.getToken();
  }
}

class AdminSubjectRepositoryImpl implements AdminSubjectRepository {
  final AdminRemoteDataSource _remote;

  const AdminSubjectRepositoryImpl(this._remote);

  @override
  Future<List<SubjectEntity>> getSubjects() async {
    return await _remote.getSubjects();
  }

  @override
  Future<SubjectEntity> createSubject({
    required String name,
    required String code,
    String? description,
    String? iconUrl,
  }) async {
    return await _remote.createSubject(name: name, code: code, description: description, iconUrl: iconUrl);
  }

  @override
  Future<SubjectEntity> updateSubject({
    required String id,
    String? name,
    String? code,
    String? description,
    String? iconUrl,
  }) async {
    return await _remote.updateSubject(id: id, name: name, code: code, description: description, iconUrl: iconUrl);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _remote.deleteSubject(id);
  }
}

class AdminSignupCodeRepositoryImpl implements AdminSignupCodeRepository {
  final AdminRemoteDataSource _remote;

  const AdminSignupCodeRepositoryImpl(this._remote);

  @override
  Future<List<SignupCodeEntity>> getSignupCodes() async {
    return await _remote.getSignupCodes();
  }

  @override
  Future<SignupCodeEntity> generateSignupCode({
    required UserRole role,
    DateTime? expiresAt,
  }) async {
    final roleStr = role == UserRole.tutor ? 'TUTOR' : 'STUDENT';
    return await _remote.generateSignupCode(role: roleStr, expiresAt: expiresAt);
  }
}

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminRemoteDataSource _remote;

  const AdminUserRepositoryImpl(this._remote);

  @override
  Future<List<AccountUserEntity>> getUsers({
    UserRole? role,
    AccountStatus? status,
    String? search,
  }) async {
    String? r;
    if (role != null) {
      if (role == UserRole.admin) r = 'ADMIN';
      if (role == UserRole.tutor) r = 'TUTOR';
      if (role == UserRole.student) r = 'STUDENT';
    }
    String? s;
    if (status != null) {
      s = status == AccountStatus.active ? 'ACTIVE' : 'DEACTIVATED';
    }
    return await _remote.getUsers(role: r, status: s, search: search);
  }

  @override
  Future<AccountUserEntity> updateUserStatus({
    required String id,
    required AccountStatus status,
  }) async {
    final statusStr = status == AccountStatus.active ? 'ACTIVE' : 'DEACTIVATED';
    return await _remote.updateUserStatus(id: id, status: statusStr);
  }

  @override
  Future<AccountUserEntity> resetUserDevice(String id) async {
    return await _remote.resetUserDevice(id);
  }
}

class AdminPermissionsRepositoryImpl implements AdminPermissionsRepository {
  final AdminRemoteDataSource _remote;

  const AdminPermissionsRepositoryImpl(this._remote);

  @override
  Future<void> assignTutorSubject({required String tutorId, required String subjectId}) async {
    await _remote.assignTutorSubject(tutorId: tutorId, subjectId: subjectId);
  }

  @override
  Future<void> unassignTutorSubject({required String tutorId, required String subjectId}) async {
    await _remote.unassignTutorSubject(tutorId: tutorId, subjectId: subjectId);
  }

  @override
  Future<void> grantStudentCourse({required String studentId, required String courseId}) async {
    await _remote.grantStudentCourse(studentId: studentId, courseId: courseId);
  }

  @override
  Future<void> revokeStudentCourse({required String studentId, required String courseId}) async {
    await _remote.revokeStudentCourse(studentId: studentId, courseId: courseId);
  }
}

class AdminAnnouncementRepositoryImpl implements AdminAnnouncementRepository {
  final AdminRemoteDataSource _remote;

  const AdminAnnouncementRepositoryImpl(this._remote);

  @override
  Future<List<AnnouncementEntity>> getAnnouncements() async {
    return await _remote.getAnnouncements();
  }

  @override
  Future<AnnouncementEntity> createAnnouncement({
    required String title,
    required String message,
    String targetRole = 'ALL',
    String? courseId,
  }) async {
    return await _remote.createAnnouncement(title: title, message: message, targetRole: targetRole, courseId: courseId);
  }
}
