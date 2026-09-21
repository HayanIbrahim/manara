import '../entities/auth_entities.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String username,
    required String password,
    required String deviceId,
  });

  Future<UserEntity> register({
    required String signupCode,
    required UserRole role,
    required String username,
    String? email,
    required String displayName,
    required String password,
    required String deviceId,
  });

  Future<UserEntity?> getCurrentUser();

  Future<void> logout();

  Future<String?> getSavedToken();

  Future<String> getDeviceId();
}
