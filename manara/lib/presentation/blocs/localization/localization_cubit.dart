import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class LocalizationCubit extends Cubit<Locale> {
  final SharedPreferences _prefs;

  LocalizationCubit(this._prefs) : super(const Locale('ar')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final code = _prefs.getString(StorageKeys.languageCode);
    if (code != null && (code == 'en' || code == 'ar')) {
      emit(Locale(code));
    }
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await _prefs.setString(StorageKeys.languageCode, newLocale.languageCode);
    emit(newLocale);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(StorageKeys.languageCode, locale.languageCode);
    emit(locale);
  }
}
