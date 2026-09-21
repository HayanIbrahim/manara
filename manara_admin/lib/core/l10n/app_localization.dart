import 'package:flutter/material.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization) ??
        AppLocalization(const Locale('en'));
  }

  bool get isRtl => locale.languageCode == 'ar';

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'app_name': 'Manara Admin',
      'executive_portal': 'Executive Management Portal',
      'username': 'Username',
      'password': 'Password',
      'login': 'Sign In as Administrator',
      'logout': 'Sign Out',
      'dashboard': 'Overview',
      'subjects': 'Academic Subjects',
      'signup_codes': 'Signup Codes',
      'users': 'User Accounts',
      'permissions': 'Permissions & Access',
      'announcements': 'System Broadcasts',
      'total_users': 'Total Accounts',
      'active_tutors': 'Active Tutors',
      'total_students': 'Total Students',
      'active_courses': 'Published Courses',
      'pending_codes': 'Active Codes',
      'generate_code': 'Generate Single-Use Code',
      'code': 'Signup Code',
      'role': 'Role',
      'expires_at': 'Expires At',
      'status': 'Status',
      'used_by': 'Used By',
      'actions': 'Actions',
      'copy': 'Copy Code',
      'copied': 'Code copied to clipboard!',
      'create_subject': 'New Subject',
      'edit_subject': 'Edit Subject',
      'delete_subject': 'Delete Subject',
      'subject_name': 'Subject Name',
      'subject_code': 'Subject Code',
      'description': 'Description',
      'save': 'Save Changes',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm_delete': 'Are you sure you want to delete this subject?',
      'device_reset': 'Reset Device',
      'device_reset_confirm': 'Are you sure you want to clear the bound device for this user? They will be permitted to log in from a new hardware device.',
      'activate': 'Activate',
      'deactivate': 'Deactivate',
      'active': 'Active',
      'deactivated': 'Deactivated',
      'broadcast_title': 'Broadcast Title',
      'broadcast_message': 'Broadcast Message',
      'target_role': 'Target Role',
      'send_broadcast': 'Publish Broadcast',
      'all': 'All Users',
      'student': 'Student',
      'tutor': 'Tutor',
      'admin': 'Admin',
      'search': 'Search by username, name, or email...',
      'grant_access': 'Grant Course Access',
      'assign_subject': 'Assign Subject to Tutor',
      'student_id': 'Student ID',
      'course_id': 'Course ID',
      'tutor_id': 'Tutor ID',
      'subject_id': 'Subject ID',
      'quick_login': 'One-Click Quick Login',
      'quick_login_sub': 'Sign in with default administrator credentials',
      'or_divider': 'OR QUICK ACCESS',
    },
    'ar': {
      'app_name': 'لوحة تحكم منارة',
      'executive_portal': 'البوابة الإدارية التنفيذية',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول كمسؤول',
      'logout': 'تسجيل الخروج',
      'dashboard': 'لوحة المعلومات',
      'subjects': 'المواد الدراسية',
      'signup_codes': 'أكواد التسجيل',
      'users': 'حسابات المستخدمين',
      'permissions': 'الصلاحيات والوصول',
      'announcements': 'التعميمات والإشعارات',
      'total_users': 'إجمالي الحسابات',
      'active_tutors': 'المعلمون النشطون',
      'total_students': 'إجمالي الطلاب',
      'active_courses': 'الدورات المفعلة',
      'pending_codes': 'الأكواد المتاحة',
      'generate_code': 'توليد كود تسجيل لمرة واحدة',
      'code': 'كود التسجيل',
      'role': 'الدور',
      'expires_at': 'تاريخ الانتهاء',
      'status': 'الحالة',
      'used_by': 'مستخدم بواسطة',
      'actions': 'الإجراءات',
      'copy': 'نسخ الكود',
      'copied': 'تم نسخ الكود للحافظة!',
      'create_subject': 'إضافة مادة جديدة',
      'edit_subject': 'تعديل المادة',
      'delete_subject': 'حذف المادة',
      'subject_name': 'اسم المادة',
      'subject_code': 'رمز المادة',
      'description': 'الوصف',
      'save': 'حفظ التغييرات',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'confirm_delete': 'هل أنت متأكد من حذف هذه المادة الدراسية؟',
      'device_reset': 'فك ارتباط الجهاز',
      'device_reset_confirm': 'هل أنت متأكد من رغبتك في فك ارتباط الجهاز لهذا الحساب؟ سيتمكن المستخدم من تسجيل الدخول عبر جهاز جديد.',
      'activate': 'تفعيل الحساب',
      'deactivate': 'تعطيل الحساب',
      'active': 'نشط',
      'deactivated': 'معطل',
      'broadcast_title': 'عنوان التعميم',
      'broadcast_message': 'نص التعميم',
      'target_role': 'الفئة المستهدفة',
      'send_broadcast': 'إرسال التعميم',
      'all': 'الجميع',
      'student': 'طالب',
      'tutor': 'معلم',
      'admin': 'مسؤول',
      'search': 'بحث باسم المستخدم، الاسم أو البريد...',
      'grant_access': 'منح صلاحية الوصول للدورة',
      'assign_subject': 'تعيين مادة دراسية لمعلم',
      'student_id': 'معرف الطالب',
      'course_id': 'معرف الدورة',
      'tutor_id': 'معرف المعلم',
      'subject_id': 'معرف المادة',
      'quick_login': 'تسجيل الدخول السريع بنقرة واحدة',
      'quick_login_sub': 'الدخول المباشر بالبيانات الافتراضية',
      'or_divider': 'أو الدخول السريع',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async => AppLocalization(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
