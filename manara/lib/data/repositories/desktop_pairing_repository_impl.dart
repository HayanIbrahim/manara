import '../../domain/entities/auth_entities.dart';
import '../../domain/entities/desktop_entities.dart';
import '../../domain/repositories/desktop_pairing_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/api_data_source.dart';
import '../models/user_model.dart';

class DesktopPairingRepositoryImpl implements DesktopPairingRepository {
  final ApiDataSource _apiDataSource;
  final AuthLocalDataSource _localDataSource;

  DesktopPairingRepositoryImpl({
    required this._apiDataSource,
    required this._localDataSource,
  });

  @override
  Future<DesktopChallengeEntity> createChallenge() async {
    return await _apiDataSource.createDesktopChallenge();
  }

  @override
  Future<DesktopStatusEntity> getChallengeStatus(String challenge) async {
    return await _apiDataSource.getDesktopChallengeStatus(challenge);
  }

  @override
  Future<DesktopStatusEntity> authorizeChallenge(String challenge) async {
    return await _apiDataSource.authorizeDesktopChallenge(challenge);
  }

  @override
  Future<UserEntity> exchangeChallenge(String challenge) async {
    final response = await _apiDataSource.exchangeDesktopChallenge(challenge);
    final accessToken = response['accessToken']?.toString() ?? '';
    final userMap = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);

    await _localDataSource.saveToken(accessToken);
    await _localDataSource.saveUser(user);
    await _localDataSource.saveSessionType('desktop');

    return user;
  }

  @override
  Future<void> closeSession() async {
    await _apiDataSource.closeDesktopSession();
    await _localDataSource.purgeAll();
  }
}
