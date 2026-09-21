import '../../../core/security/security_service.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/api_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiDataSource _apiDataSource;
  final AuthLocalDataSource _localDataSource;
  final SecurityService _securityService;

  AuthRepositoryImpl({
    required this._apiDataSource,
    required this._localDataSource,
    SecurityService? securityService,
  })  : _securityService = securityService ?? SecurityService.instance;

  @override
  Future<String> getDeviceId() async {
    return await _securityService.getOrCreateDeviceId();
  }

  @override
  Future<String?> getSavedToken() async {
    return await _localDataSource.getToken();
  }

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final response = await _apiDataSource.login(
      username: username,
      password: password,
      deviceId: deviceId,
    );

    final rawData = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;
    final accessToken = rawData['accessToken']?.toString() ??
        rawData['token']?.toString() ??
        response['accessToken']?.toString() ??
        '';
    final userMap = (rawData['user'] is Map<String, dynamic>)
        ? rawData['user'] as Map<String, dynamic>
        : (response['user'] is Map<String, dynamic>)
            ? response['user'] as Map<String, dynamic>
            : (rawData['account'] is Map<String, dynamic>)
                ? rawData['account'] as Map<String, dynamic>
                : <String, dynamic>{};
    final user = UserModel.fromJson(userMap);

    await _localDataSource.saveToken(accessToken);
    await _localDataSource.saveUser(user);
    await _localDataSource.saveDeviceId(deviceId);
    await _localDataSource.saveSessionType('mobile');

    return user;
  }

  @override
  Future<UserEntity> register({
    required String signupCode,
    required UserRole role,
    required String username,
    String? email,
    required String displayName,
    required String password,
    required String deviceId,
  }) async {
    final roleStr = role == UserRole.tutor ? 'TUTOR' : 'STUDENT';
    final response = await _apiDataSource.register(
      signupCode: signupCode,
      role: roleStr,
      username: username,
      email: email,
      displayName: displayName,
      password: password,
      deviceId: deviceId,
    );

    final rawData = (response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : response;
    final accessToken = rawData['accessToken']?.toString() ??
        rawData['token']?.toString() ??
        response['accessToken']?.toString() ??
        '';
    final userMap = (rawData['user'] is Map<String, dynamic>)
        ? rawData['user'] as Map<String, dynamic>
        : (response['user'] is Map<String, dynamic>)
            ? response['user'] as Map<String, dynamic>
            : (rawData['account'] is Map<String, dynamic>)
                ? rawData['account'] as Map<String, dynamic>
                : <String, dynamic>{};
    final user = UserModel.fromJson(userMap);

    await _localDataSource.saveToken(accessToken);
    await _localDataSource.saveUser(user);
    await _localDataSource.saveDeviceId(deviceId);
    await _localDataSource.saveSessionType('mobile');

    return user;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _localDataSource.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final userResult = await _apiDataSource.getCurrentUser();
      final user = userResult['user'] as UserModel;
      final sessionType = userResult['sessionType']?.toString();
      if (sessionType != null && sessionType.isNotEmpty) {
        await _localDataSource.saveSessionType(sessionType);
      }
      await _localDataSource.saveUser(user);
      return user;
    } catch (_) {
      // If token rejected by server or invalid, purge session
      await _localDataSource.purgeAll();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final sessionType = await _localDataSource.getSessionType();
    if (sessionType == 'desktop') {
      await _apiDataSource.closeDesktopSession();
    }
    await _localDataSource.purgeAll();
  }
}
