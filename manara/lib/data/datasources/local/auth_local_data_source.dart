import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  Future<void> saveDeviceId(String deviceId);
  Future<String?> getDeviceId();

  Future<void> saveUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();

  Future<void> saveSessionType(String sessionType);
  Future<String?> getSessionType();
  Future<void> clearSessionType();

  Future<void> purgeAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl({
    required this._prefs,
  });

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.accessToken, token);
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(StorageKeys.accessToken);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(StorageKeys.accessToken);
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    await _prefs.setString(StorageKeys.deviceId, deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    return _prefs.getString(StorageKeys.deviceId);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final raw = jsonEncode(user.toJson());
    await _prefs.setString(StorageKeys.currentUser, raw);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final raw = _prefs.getString(StorageKeys.currentUser);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await _prefs.remove(StorageKeys.currentUser);
  }

  @override
  Future<void> saveSessionType(String sessionType) async {
    await _prefs.setString(StorageKeys.sessionType, sessionType);
  }

  @override
  Future<String?> getSessionType() async {
    return _prefs.getString(StorageKeys.sessionType);
  }

  @override
  Future<void> clearSessionType() async {
    await _prefs.remove(StorageKeys.sessionType);
  }

  @override
  Future<void> purgeAll() async {
    await clearToken();
    await clearUser();
    await clearSessionType();
  }
}
