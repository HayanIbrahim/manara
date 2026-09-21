import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../../models/admin_models.dart';

abstract class AdminLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  Future<void> saveCurrentAdmin(AdminUserModel admin);
  Future<AdminUserModel?> getCachedAdmin();
  Future<void> clearCurrentAdmin();

  Future<void> purgeSession();
}

class AdminLocalDataSourceImpl implements AdminLocalDataSource {
  final SharedPreferences _prefs;

  const AdminLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.adminToken, token);
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(StorageKeys.adminToken);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(StorageKeys.adminToken);
  }

  @override
  Future<void> saveCurrentAdmin(AdminUserModel admin) async {
    final raw = jsonEncode(admin.toJson());
    await _prefs.setString(StorageKeys.currentAdmin, raw);
  }

  @override
  Future<AdminUserModel?> getCachedAdmin() async {
    final raw = _prefs.getString(StorageKeys.currentAdmin);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AdminUserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCurrentAdmin() async {
    await _prefs.remove(StorageKeys.currentAdmin);
  }

  @override
  Future<void> purgeSession() async {
    await clearToken();
    await clearCurrentAdmin();
  }
}
