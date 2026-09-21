import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localization.dart';
import '../../core/network/api_logger.dart';
import '../../core/theme/app_colors.dart';
import '../blocs/auth/admin_auth_bloc.dart';
import '../blocs/localization/admin_localization_cubit.dart';
import '../blocs/theme/admin_theme_cubit.dart';
import 'admin_api_logs_dialog.dart';

class AdminLayoutShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminLayoutShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedIndex = navigationShell.currentIndex;
    final authState = context.watch<AdminAuthBloc>().state;
    final adminUser = authState is AdminAuthenticated ? authState.user : null;

    final navItems = [
      _AdminNavItem(icon: Icons.dashboard_rounded, label: l10n.translate('dashboard')),
      _AdminNavItem(icon: Icons.category_rounded, label: l10n.translate('subjects')),
      _AdminNavItem(icon: Icons.vpn_key_rounded, label: l10n.translate('signup_codes')),
      _AdminNavItem(icon: Icons.manage_accounts_rounded, label: l10n.translate('users')),
      _AdminNavItem(icon: Icons.security_rounded, label: l10n.translate('permissions')),
      _AdminNavItem(icon: Icons.campaign_rounded, label: l10n.translate('announcements')),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('app_name'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          l10n.translate('executive_portal'),
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Navigation Items
                Expanded(
                  child: ListView.separated(
                    itemCount: navItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;
                      final item = navItems[index];

                      return InkWell(
                        onTap: () => navigationShell.goBranch(
                          index,
                          initialLocation: index == navigationShell.currentIndex,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Admin User Profile Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adminUser?.displayName ?? 'Administrator',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              adminUser?.username ?? 'admin',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                        onPressed: () {
                          context.read<AdminAuthBloc>().add(AdminAuthLogoutRequested());
                        },
                        tooltip: l10n.translate('logout'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Theme and Language Controls
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.read<AdminLocalizationCubit>().toggleLanguage(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.language_rounded, size: 15, color: theme.colorScheme.onSurface),
                              const SizedBox(width: 6),
                              Text(
                                l10n.isRtl ? 'English' : 'العربية',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.read<AdminThemeCubit>().toggleTheme(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? AppColors.accent : AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // API Logs Inspector button
                    InkWell(
                      onTap: () => AdminApiLogsDialog.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedBuilder(
                        animation: ApiLogStore.instance,
                        builder: (context, _) {
                          final errorCount = ApiLogStore.instance.errorCount;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: errorCount > 0
                                    ? AppColors.error
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.terminal_rounded,
                                  color: errorCount > 0 ? AppColors.error : theme.colorScheme.onSurface,
                                  size: 16,
                                ),
                                if (errorCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$errorCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          // Main Body
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;

  const _AdminNavItem({required this.icon, required this.label});
}
