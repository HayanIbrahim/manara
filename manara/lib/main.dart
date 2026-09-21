import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/app_localization.dart';
import 'core/network/api_client.dart';
import 'core/security/security_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_data_source.dart';
import 'data/datasources/remote/api_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/catalog_repository_impl.dart';
import 'data/repositories/desktop_pairing_repository_impl.dart';
import 'data/repositories/gamification_repository_impl.dart';
import 'data/repositories/student_repository_impl.dart';
import 'data/repositories/tutor_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/repositories/desktop_pairing_repository.dart';
import 'domain/repositories/gamification_repository.dart';
import 'domain/repositories/student_repository.dart';
import 'domain/repositories/tutor_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/catalog/catalog_bloc.dart';
import 'presentation/blocs/course_player/course_player_bloc.dart';
import 'presentation/blocs/desktop_pairing/desktop_pairing_bloc.dart';
import 'presentation/blocs/exam/exam_bloc.dart';
import 'presentation/blocs/gamification/gamification_bloc.dart';
import 'presentation/blocs/localization/localization_cubit.dart';
import 'presentation/blocs/quiz/quiz_bloc.dart';
import 'presentation/blocs/student/student_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/tutor/tutor_bloc.dart';
import 'presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. Initialize Security Service (FLAG_SECURE on Android, window_manager on Desktop)
  final securityService = SecurityService.instance;
  securityService.init(prefs);
  await securityService.initializeSecurity();

  // 3. Set up Local Data Source
  final authLocalDataSource = AuthLocalDataSourceImpl(prefs: prefs);

  // 4. Set up ApiClient with dynamic bearer token & device ID providers
  final apiClient = ApiClient(
    tokenProvider: () => authLocalDataSource.getToken(),
    deviceIdProvider: () => securityService.getOrCreateDeviceId(),
    sessionTypeProvider: () => authLocalDataSource.getSessionType(),
  );

  // 5. Remote Data Source
  final apiDataSource = ApiDataSource(apiClient);

  // 6. Repository Implementations
  final authRepository = AuthRepositoryImpl(
    apiDataSource: apiDataSource,
    localDataSource: authLocalDataSource,
    securityService: securityService,
  );

  final desktopPairingRepository = DesktopPairingRepositoryImpl(
    apiDataSource: apiDataSource,
    localDataSource: authLocalDataSource,
  );

  // Hook desktop session purge on window close
  securityService.registerDesktopExitCallback(() {
    desktopPairingRepository.closeSession();
  });

  final catalogRepository = CatalogRepositoryImpl(apiDataSource);
  final studentRepository = StudentRepositoryImpl(apiDataSource);
  final tutorRepository = TutorRepositoryImpl(apiDataSource);
  final gamificationRepository = GamificationRepositoryImpl(apiDataSource);

  runApp(
    ManaraApp(
      prefs: prefs,
      authRepository: authRepository,
      desktopPairingRepository: desktopPairingRepository,
      catalogRepository: catalogRepository,
      studentRepository: studentRepository,
      tutorRepository: tutorRepository,
      gamificationRepository: gamificationRepository,
    ),
  );
}

class ManaraApp extends StatelessWidget {
  final SharedPreferences prefs;
  final AuthRepository authRepository;
  final DesktopPairingRepository desktopPairingRepository;
  final CatalogRepository catalogRepository;
  final StudentRepository studentRepository;
  final TutorRepository tutorRepository;
  final GamificationRepository gamificationRepository;

  const ManaraApp({
    super.key,
    required this.prefs,
    required this.authRepository,
    required this.desktopPairingRepository,
    required this.catalogRepository,
    required this.studentRepository,
    required this.tutorRepository,
    required this.gamificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DesktopPairingRepository>.value(value: desktopPairingRepository),
        RepositoryProvider<CatalogRepository>.value(value: catalogRepository),
        RepositoryProvider<StudentRepository>.value(value: studentRepository),
        RepositoryProvider<TutorRepository>.value(value: tutorRepository),
        RepositoryProvider<GamificationRepository>.value(value: gamificationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocalizationCubit>(
            create: (_) => LocalizationCubit(prefs),
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(prefs),
          ),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider<DesktopPairingBloc>(
            create: (_) => DesktopPairingBloc(desktopPairingRepository),
          ),
          BlocProvider<CatalogBloc>(
            create: (_) => CatalogBloc(catalogRepository),
          ),
          BlocProvider<StudentBloc>(
            create: (_) => StudentBloc(
              studentRepository: studentRepository,
              gamificationRepository: gamificationRepository,
            ),
          ),
          BlocProvider<CoursePlayerBloc>(
            create: (_) => CoursePlayerBloc(studentRepository),
          ),
          BlocProvider<QuizBloc>(
            create: (_) => QuizBloc(studentRepository),
          ),
          BlocProvider<ExamBloc>(
            create: (_) => ExamBloc(studentRepository),
          ),
          BlocProvider<TutorBloc>(
            create: (_) => TutorBloc(tutorRepository),
          ),
          BlocProvider<GamificationBloc>(
            create: (_) => GamificationBloc(gamificationRepository),
          ),
        ],
        child: BlocBuilder<LocalizationCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp.router(
                  title: 'Manara Platform',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: locale,
                  supportedLocales: const [
                    Locale('ar'),
                    Locale('en'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizationDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: appRouter,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
