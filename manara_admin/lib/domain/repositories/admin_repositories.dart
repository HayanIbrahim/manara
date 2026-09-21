import '../entities/admin_entities.dart';

abstract class AdminAuthRepository {
  Future<AdminUserEntity> login({required String username, required String password});
  Future<AdminUserEntity?> getCurrentAdmin();
  Future<void> logout();
  Future<String?> getSavedToken();
}

abstract class AdminSubjectRepository {
  Future<List<SubjectEntity>> getSubjects();
  Future<SubjectEntity> createSubject({
    required String name,
    required String code,
    String? description,
    String? iconUrl,
  });
  Future<SubjectEntity> updateSubject({
    required String id,
    String? name,
    String? code,
    String? description,
    String? iconUrl,
  });
  Future<void> deleteSubject(String id);
}

abstract class AdminSignupCodeRepository {
  Future<List<SignupCodeEntity>> getSignupCodes();
  Future<SignupCodeEntity> generateSignupCode({
    required UserRole role,
    DateTime? expiresAt,
  });
}

abstract class AdminUserRepository {
  Future<List<AccountUserEntity>> getUsers({
    UserRole? role,
    AccountStatus? status,
    String? search,
  });
  Future<AccountUserEntity> updateUserStatus({
    required String id,
    required AccountStatus status,
  });
  Future<AccountUserEntity> resetUserDevice(String id);
}

abstract class AdminPermissionsRepository {
  Future<void> assignTutorSubject({required String tutorId, required String subjectId});
  Future<void> unassignTutorSubject({required String tutorId, required String subjectId});
  Future<void> grantStudentCourse({required String studentId, required String courseId});
  Future<void> revokeStudentCourse({required String studentId, required String courseId});
}

abstract class AdminAnnouncementRepository {
  Future<List<AnnouncementEntity>> getAnnouncements();
  Future<AnnouncementEntity> createAnnouncement({
    required String title,
    required String message,
    String targetRole = 'ALL',
    String? courseId,
  });
}
