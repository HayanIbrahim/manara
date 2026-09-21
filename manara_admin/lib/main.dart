import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'core/l10n/app_localization.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/admin_local_data_source.dart';
import 'data/datasources/remote/admin_remote_data_source.dart';
import 'data/repositories/admin_repositories_impl.dart';
import 'presentation/blocs/announcements/admin_announcements_bloc.dart';
import 'presentation/blocs/auth/admin_auth_bloc.dart';
import 'presentation/blocs/localization/admin_localization_cubit.dart';
import 'presentation/blocs/permissions/admin_permissions_bloc.dart';
import 'presentation/blocs/signup_codes/admin_signup_codes_bloc.dart';
import 'presentation/blocs/subjects/admin_subjects_bloc.dart';
import 'presentation/blocs/theme/admin_theme_cubit.dart';
import 'presentation/blocs/users/admin_users_bloc.dart';
import 'presentation/router/admin_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop window sizing and properties
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1366, 850),
        minimumSize: Size(1024, 700),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Manara - Executive Portal',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }

  // Local persistent storage
  final prefs = await SharedPreferences.getInstance();
  final localDataSource = AdminLocalDataSourceImpl(prefs);

  // Network client with token handling
  final apiClient = ApiClient(
    tokenProvider: () => localDataSource.getToken(),
  );
  final remoteDataSource = AdminRemoteDataSourceImpl(apiClient);

  // Repositories
  final authRepository = AdminAuthRepositoryImpl(remoteDataSource, localDataSource);
  final subjectRepository = AdminSubjectRepositoryImpl(remoteDataSource);
  final signupCodeRepository = AdminSignupCodeRepositoryImpl(remoteDataSource);
  final userRepository = AdminUserRepositoryImpl(remoteDataSource);
  final permissionsRepository = AdminPermissionsRepositoryImpl(remoteDataSource);
  final announcementRepository = AdminAnnouncementRepositoryImpl(remoteDataSource);

  // Initialize Auth BLoC and check initial status
  final authBloc = AdminAuthBloc(authRepository)..add(AdminAuthCheckRequested());

  // Initialize Router
  final router = createAdminRouter(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AdminThemeCubit>(create: (_) => AdminThemeCubit(prefs)),
        BlocProvider<AdminLocalizationCubit>(create: (_) => AdminLocalizationCubit(prefs)),
        BlocProvider<AdminAuthBloc>.value(value: authBloc),
        BlocProvider<AdminSubjectsBloc>(create: (_) => AdminSubjectsBloc(subjectRepository)),
        BlocProvider<AdminSignupCodesBloc>(create: (_) => AdminSignupCodesBloc(signupCodeRepository)),
        BlocProvider<AdminUsersBloc>(create: (_) => AdminUsersBloc(userRepository)),
        BlocProvider<AdminPermissionsBloc>(create: (_) => AdminPermissionsBloc(permissionsRepository)),
        BlocProvider<AdminAnnouncementsBloc>(create: (_) => AdminAnnouncementsBloc(announcementRepository)),
      ],
      child: ManaraAdminApp(router: router),
    ),
  );
}

class ManaraAdminApp extends StatelessWidget {
  final dynamic router;

  const ManaraAdminApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AdminThemeCubit>().state;
    final locale = context.watch<AdminLocalizationCubit>().state;

    return MaterialApp.router(
      title: 'Manara Admin',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizationDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
