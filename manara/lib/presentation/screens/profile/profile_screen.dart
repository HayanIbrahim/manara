import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/localization/localization_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isGuest = authState is AuthGuest || authState is Unauthenticated;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('profile'),
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Banner Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    user != null && user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : (isGuest ? 'G' : 'U'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.displayName ?? (isGuest ? l10n.translate('guest_mode') : 'Account'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.username != null ? '@${user!.username}' : 'Browsing without account',
                  style: TextStyle(color: AppColors.adaptiveTextMuted(isDark), fontSize: 13),
                ),
                if (user != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.glassBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              l10n.translate('device_id_bound'),
                              style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (user.isTutor ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (user.isTutor ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isTutor ? Icons.school_rounded : Icons.person_rounded,
                              color: user.isTutor ? AppColors.secondary : AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.isTutor ? l10n.translate('role_tutor') : l10n.translate('role_student'),
                              style: TextStyle(
                                color: user.isTutor ? AppColors.secondary : AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preferences Group
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Theme Switcher Tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.gold : AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? AppColors.gold : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Theme Mode',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark ? 'Dark' : 'Light',
                        style: TextStyle(
                          color: isDark ? AppColors.gold : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: !isDark,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                      ),
                    ],
                  ),
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppColors.glassBorder : AppColors.lightBorder,
                ),
                // Language Switcher Tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppColors.secondary, size: 20),
                  ),
                  title: Text(
                    l10n.translate('switch_language'),
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Text(
                    l10n.isRtl ? 'العربية (AR)' : 'English (EN)',
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onTap: () => context.read<LocalizationCubit>().toggleLanguage(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout or Login action
          if (isGuest) ...[
            GlowingGlassButton(
              text: l10n.translate('login'),
              onPressed: () => context.go('/login'),
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l10n.translate('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              },
            ),
          ],
        ],
      ),
    );
  }
}
