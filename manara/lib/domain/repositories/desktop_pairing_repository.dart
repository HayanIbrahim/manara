import '../entities/auth_entities.dart';
import '../entities/desktop_entities.dart';

abstract class DesktopPairingRepository {
  /// Desktop side: Creates a short-lived QR challenge
  Future<DesktopChallengeEntity> createChallenge();

  /// Desktop side: Polls challenge status (PENDING -> APPROVED -> CONSUMED)
  Future<DesktopStatusEntity> getChallengeStatus(String challenge);

  /// Mobile side: Logged-in user authorizes the challenge with bearer token and deviceId
  Future<DesktopStatusEntity> authorizeChallenge(String challenge);

  /// Desktop side: Once APPROVED, exchange challenge for desktop JWT
  Future<UserEntity> exchangeChallenge(String challenge);

  /// Desktop side: Close temporary desktop session on app close
  Future<void> closeSession();
}
