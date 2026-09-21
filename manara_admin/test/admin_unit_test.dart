import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manara_admin/core/theme/app_theme.dart';
import 'package:manara_admin/domain/entities/admin_entities.dart';
import 'package:manara_admin/data/models/admin_models.dart';
import 'package:manara_admin/presentation/blocs/theme/admin_theme_cubit.dart';
import 'package:manara_admin/presentation/blocs/localization/admin_localization_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Domain & Models', () {
    test('AdminUserModel serialization roundtrip', () {
      final json = {
        'id': 'adm_1',
        'username': 'chief_admin',
        'displayName': 'System Administrator',
        'email': 'admin@manara.edu',
        'role': 'admin',
      };

      final model = AdminUserModel.fromJson(json);
      expect(model.id, 'adm_1');
      expect(model.username, 'chief_admin');
      expect(model.displayName, 'System Administrator');
      expect(model.role, UserRole.admin);

      final outJson = model.toJson();
      expect(outJson['username'], 'chief_admin');
    });

    test('SubjectModel serialization roundtrip', () {
      final json = {
        'id': 'sub_1',
        'name': 'Mathematics',
        'code': 'MATH101',
        'description': 'Calculus & Linear Algebra',
        'coursesCount': 5,
      };

      final model = SubjectModel.fromJson(json);
      expect(model.id, 'sub_1');
      expect(model.name, 'Mathematics');
      expect(model.code, 'MATH101');
      expect(model.coursesCount, 5);
    });

    test('SignupCodeModel serialization roundtrip', () {
      final json = {
        'id': 'sc_1',
        'code': 'MANARA-7721',
        'role': 'tutor',
        'expiresAt': '2026-12-31T23:59:59Z',
        'isUsed': false,
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final model = SignupCodeModel.fromJson(json);
      expect(model.id, 'sc_1');
      expect(model.code, 'MANARA-7721');
      expect(model.role, UserRole.tutor);
      expect(model.isUsed, false);
    });

    test('AccountUserModel serialization and properties', () {
      final json = {
        'id': 'usr_1',
        'username': 'student_ahmed',
        'displayName': 'Ahmed Hassan',
        'role': 'student',
        'status': 'active',
        'deviceId': 'hw_win_38283848',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final model = AccountUserModel.fromJson(json);
      expect(model.id, 'usr_1');
      expect(model.isDeviceBound, true);
      expect(model.isActive, true);
    });

    test('AnnouncementModel serialization', () {
      final json = {
        'id': 'ann_1',
        'title': 'Server Maintenance',
        'body': 'Platform will undergo routine maintenance at 02:00 UTC.',
        'targetRole': 'ALL',
        'createdAt': '2026-09-14T00:00:00Z',
      };

      final model = AnnouncementModel.fromJson(json);
      expect(model.id, 'ann_1');
      expect(model.title, 'Server Maintenance');
      expect(model.body, contains('routine maintenance'));
      expect(model.targetRole, 'ALL');
    });
  });

  group('Admin Theme & Localization Cubits', () {
    test('AdminThemeCubit toggles between Dark and Light mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = AdminThemeCubit(prefs);

      expect(cubit.state, ThemeMode.dark);

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);

      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
    });

    test('AdminLocalizationCubit toggles between Arabic and English', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = AdminLocalizationCubit(prefs);

      expect(cubit.state.languageCode, 'ar');

      await cubit.toggleLanguage();
      expect(cubit.state.languageCode, 'en');

      await cubit.toggleLanguage();
      expect(cubit.state.languageCode, 'ar');
    });
  });

  group('AppTheme Verification', () {
    test('Both Light and Dark themes provide valid configurations', () {
      final darkTheme = AppTheme.darkTheme;
      final lightTheme = AppTheme.lightTheme;

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.scaffoldBackgroundColor, isNotNull);
      expect(lightTheme.scaffoldBackgroundColor, isNotNull);
    });

    test('AccountUserModel parses deviceBound flag correctly', () {
      final json = {
        'id': 'usr_2',
        'username': 'student_sara',
        'displayName': 'Sara Ali',
        'role': 'student',
        'status': 'active',
        'deviceBound': true,
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final model = AccountUserModel.fromJson(json);
      expect(model.deviceBound, true);
      expect(model.isDeviceBound, true);
    });
  });
}
