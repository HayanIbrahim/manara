import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/exam_entities.dart';
import '../../domain/entities/quiz_entities.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/catalog/course_catalog_screen.dart';
import '../screens/catalog/course_detail_screen.dart';
import '../screens/dashboard/student_dashboard_screen.dart';
import '../screens/desktop_pairing/desktop_qr_pairing_screen.dart';
import '../screens/exam/exam_screen.dart';
import '../screens/gamification/achievements_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/player/course_player_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/tutor/exam_grading_screen.dart';
import '../screens/tutor/tutor_dashboard_screen.dart';
import '../widgets/adaptive_nav_shell.dart';

CustomTransitionPage<void> _buildFadeSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.05, 0.0);
      const end = Offset.zero;
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: end).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorDashboard = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final GlobalKey<NavigatorState> _shellNavigatorCourses = GlobalKey<NavigatorState>(debugLabel: 'courses');
final GlobalKey<NavigatorState> _shellNavigatorLeaderboard = GlobalKey<NavigatorState>(debugLabel: 'leaderboard');
final GlobalKey<NavigatorState> _shellNavigatorProfile = GlobalKey<NavigatorState>(debugLabel: 'profile');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        context: context,
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        context: context,
        state: state,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/desktop-qr',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        context: context,
        state: state,
        child: const DesktopQrPairingScreen(),
      ),
    ),

    // Stateful Navigation Shell with 4 branches
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AdaptiveNavShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Dashboard
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDashboard,
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => _buildFadeSlideTransition(
                context: context,
                state: state,
                child: const StudentDashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/tutor',
              pageBuilder: (context, state) => _buildFadeSlideTransition(
                context: context,
                state: state,
                child: const TutorDashboardScreen(),
              ),
            ),
          ],
        ),
        // Branch 2: Courses Catalog
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCourses,
          routes: [
            GoRoute(
              path: '/courses',
              pageBuilder: (context, state) => _buildFadeSlideTransition(
                context: context,
                state: state,
                child: const CourseCatalogScreen(),
              ),
            ),
          ],
        ),
        // Branch 3: Leaderboard
        StatefulShellBranch(
          navigatorKey: _shellNavigatorLeaderboard,
          routes: [
            GoRoute(
              path: '/leaderboard',
              pageBuilder: (context, state) => _buildFadeSlideTransition(
                context: context,
                state: state,
                child: const LeaderboardScreen(),
              ),
            ),
          ],
        ),
        // Branch 4: Profile
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfile,
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => _buildFadeSlideTransition(
                context: context,
                state: state,
                child: const ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),

    // Nested Feature Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/courses/:id',
      pageBuilder: (context, state) {
        final courseId = state.pathParameters['id'] ?? '';
        return _buildFadeSlideTransition(
          context: context,
          state: state,
          child: CourseDetailScreen(courseId: courseId),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/player/:id',
      pageBuilder: (context, state) {
        final courseId = state.pathParameters['id'] ?? '';
        return _buildFadeSlideTransition(
          context: context,
          state: state,
          child: CoursePlayerScreen(courseId: courseId),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quiz/:lectureId',
      pageBuilder: (context, state) {
        final lectureId = state.pathParameters['lectureId'] ?? '';
        final initialQuiz = state.extra is QuizEntity ? state.extra as QuizEntity : null;
        return _buildFadeSlideTransition(
          context: context,
          state: state,
          child: QuizScreen(lectureId: lectureId, initialQuiz: initialQuiz),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/exam/:examId',
      pageBuilder: (context, state) {
        final examId = state.pathParameters['examId'] ?? '';
        final initialExam = state.extra is ExamEntity ? state.extra as ExamEntity : null;
        return _buildFadeSlideTransition(
          context: context,
          state: state,
          child: ExamScreen(examId: examId, initialExam: initialExam),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tutor/grade',
      pageBuilder: (context, state) {
        final initialSubmission = state.extra is ExamSubmissionEntity ? state.extra as ExamSubmissionEntity : null;
        return _buildFadeSlideTransition(
          context: context,
          state: state,
          child: ExamGradingScreen(initialSubmission: initialSubmission),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/achievements',
      pageBuilder: (context, state) => _buildFadeSlideTransition(
        context: context,
        state: state,
        child: const AchievementsScreen(),
      ),
    ),
  ],
);
