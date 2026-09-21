import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class AdminLocalizationCubit extends Cubit<Locale> {
  final SharedPreferences _prefs;

  AdminLocalizationCubit(this._prefs) : super(const Locale('ar')) {
    _loadLocale();
  }

  void _loadLocale() {
    final code = _prefs.getString(StorageKeys.languageCode);
    if (code == 'en') {
      emit(const Locale('en'));
    } else {
      emit(const Locale('ar'));
    }
  }

  Future<void> toggleLanguage() async {
    final next = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await _prefs.setString(StorageKeys.languageCode, next.languageCode);
    emit(next);
  }
}
