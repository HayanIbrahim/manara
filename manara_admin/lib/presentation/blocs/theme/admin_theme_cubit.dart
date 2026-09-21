import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class AdminThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  AdminThemeCubit(this._prefs) : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = _prefs.getString(StorageKeys.themeMode);
    if (mode == 'light') {
      emit(ThemeMode.light);
    } else {
      emit(ThemeMode.dark);
    }
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(StorageKeys.themeMode, next == ThemeMode.light ? 'light' : 'dark');
    emit(next);
  }
}
