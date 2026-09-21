import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/admin_auth_bloc.dart';
import '../screens/announcements/admin_announcements_screen.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/permissions/admin_permissions_screen.dart';
import '../screens/signup_codes/admin_signup_codes_screen.dart';
import '../screens/subjects/admin_subjects_screen.dart';
import '../screens/users/admin_users_screen.dart';
import '../widgets/admin_layout_shell.dart';

CustomTransitionPage<void> _buildAdminTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(opacity: curve, child: child);
    },
  );
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin_root');

GoRouter createAdminRouter(AdminAuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthBlocListenable(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AdminAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildAdminTransition(
          context: context,
          state: state,
          child: const AdminLoginScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminLayoutShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminDashboardScreen(),
                ),
              ),
            ],
          ),
          // Branch 1: Subjects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subjects',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminSubjectsScreen(),
                ),
              ),
            ],
          ),
          // Branch 2: Signup Codes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/signup-codes',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminSignupCodesScreen(),
                ),
              ),
            ],
          ),
          // Branch 3: Users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminUsersScreen(),
                ),
              ),
            ],
          ),
          // Branch 4: Permissions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/permissions',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminPermissionsScreen(),
                ),
              ),
            ],
          ),
          // Branch 5: Announcements
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/announcements',
                pageBuilder: (context, state) => _buildAdminTransition(
                  context: context,
                  state: state,
                  child: const AdminAnnouncementsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AuthBlocListenable extends ChangeNotifier {
  _AuthBlocListenable(AdminAuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
