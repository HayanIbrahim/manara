import 'package:flutter_test/flutter_test.dart';
import 'package:manara_admin/core/l10n/app_localization.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppLocalization translations test', () {
    const enLocale = Locale('en');
    final enL10n = AppLocalization(enLocale);
    expect(enL10n.translate('app_name'), 'Manara Admin');
    expect(enL10n.translate('users'), 'User Accounts');
    expect(enL10n.isRtl, false);

    const arLocale = Locale('ar');
    final arL10n = AppLocalization(arLocale);
    expect(arL10n.translate('app_name'), 'لوحة تحكم منارة');
    expect(arL10n.translate('users'), 'حسابات المستخدمين');
    expect(arL10n.isRtl, true);
  });
}
