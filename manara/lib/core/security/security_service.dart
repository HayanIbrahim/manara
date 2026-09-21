import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/storage_keys.dart';

class SecurityService with WindowListener {
  SharedPreferences? _prefs;
  static SecurityService? _instance;
  VoidCallback? _onDesktopSessionWipe;

  SecurityService._();

  static SecurityService get instance => _instance ??= SecurityService._();

  void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  bool get isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  bool get isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void registerDesktopExitCallback(VoidCallback callback) {
    _onDesktopSessionWipe = callback;
  }

  /// Initialize security measures (FLAG_SECURE on Android, WindowManager on Desktop)
  Future<void> initializeSecurity() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await enableAndroidFlagSecure();
      } else if (isDesktopPlatform) {
        await _initializeDesktopWindow();
      }
    } catch (e) {
      debugPrint('[SecurityService] initializeSecurity warning: $e');
    }
  }

  /// Android Flag Secure for anti-piracy & screen recording lockdown
  Future<void> enableAndroidFlagSecure() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      debugPrint('[SecurityService] FLAG_SECURE successfully enabled on Android');
    } catch (e) {
      debugPrint('[SecurityService] Failed to set FLAG_SECURE: $e');
    }
  }

  /// Initialize desktop window manager and register listener
  Future<void> _initializeDesktopWindow() async {
    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      const windowOptions = WindowOptions(
        size: Size(1280, 820),
        minimumSize: Size(980, 640),
        center: true,
        backgroundColor: Color(0xFF0D0E15),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Manara Platform',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('[SecurityService] Desktop window initialization error: $e');
    }
  }

  @override
  void onWindowClose() async {
    debugPrint('[SecurityService] onWindowClose detected. Purging session & storage.');
    try {
      if (_onDesktopSessionWipe != null) {
        _onDesktopSessionWipe!();
      }
      await purgeTemporaryDesktopSession();
    } catch (e) {
      debugPrint('[SecurityService] Error during onWindowClose purge: $e');
    }
    await windowManager.destroy();
  }

  /// Retrieve or generate a persistent device_id securely
  Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await _getPrefs();
      String? deviceId = prefs.getString(StorageKeys.deviceId);
      if (deviceId == null || deviceId.isEmpty) {
        // Generate secure 32-character unique ID
        final uuid = const Uuid().v4().replaceAll('-', '');
        deviceId = 'dev_${uuid}_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
        await prefs.setString(StorageKeys.deviceId, deviceId);
      }
      return deviceId;
    } catch (e) {
      // Fallback in case of storage error
      return 'dev_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Store JWT securely
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(StorageKeys.accessToken, token);
  }

  /// Read JWT
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(StorageKeys.accessToken);
  }

  /// Clear token
  Future<void> clearToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(StorageKeys.accessToken);
  }

  /// Purge all temporary desktop tokens from memory and secure storage
  Future<void> purgeTemporaryDesktopSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.sessionType);
    await prefs.remove(StorageKeys.currentUser);
    debugPrint('[SecurityService] Temporary session wiped successfully.');
  }
}
