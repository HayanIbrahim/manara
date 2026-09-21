import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/announcements/admin_announcements_bloc.dart';
import '../../blocs/auth/admin_auth_bloc.dart';
import '../../blocs/signup_codes/admin_signup_codes_bloc.dart';
import '../../blocs/subjects/admin_subjects_bloc.dart';
import '../../blocs/users/admin_users_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _fetchIfAuthenticated();
  }

  void _fetchIfAuthenticated() {
    final authState = context.read<AdminAuthBloc>().state;
    if (authState is AdminAuthenticated) {
      context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested());
      context.read<AdminSignupCodesBloc>().add(AdminFetchSignupCodesRequested());
      context.read<AdminUsersBloc>().add(const AdminFetchUsersRequested());
      context.read<AdminAnnouncementsBloc>().add(AdminFetchAnnouncementsRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AdminAuthBloc>().state;
    final adminUser = authState is AdminAuthenticated ? authState.user : null;

    final usersState = context.watch<AdminUsersBloc>().state;
    final subjectsState = context.watch<AdminSubjectsBloc>().state;
    final codesState = context.watch<AdminSignupCodesBloc>().state;

    final users = usersState is AdminUsersLoaded ? usersState.users : [];
    final subjects = subjectsState is AdminSubjectsLoaded ? subjectsState.subjects : [];
    final codes = codesState is AdminSignupCodesLoaded ? codesState.codes : [];

    final tutorsCount = users.where((u) => u.role == UserRole.tutor).length;
    final studentsCount = users.where((u) => u.role == UserRole.student).length;
    final activeCodesCount = codes.where((c) => !c.isUsed).length;

    return BlocListener<AdminAuthBloc, AdminAuthState>(
      listener: (context, state) {
        if (state is AdminAuthenticated) {
          _fetchIfAuthenticated();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _fetchIfAuthenticated();
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.translate('dashboard')} — ${adminUser?.displayName ?? 'Admin'}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor platform metrics, user access bindings, and academic catalogs.',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            tooltip: 'Refresh Dashboard',
                            onPressed: _fetchIfAuthenticated,
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.vpn_key_rounded, size: 16),
                            label: Text(l10n.translate('generate_code')),
                            onPressed: () => context.go('/signup-codes'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.campaign_rounded, size: 16),
                            label: Text(l10n.translate('announcements')),
                            onPressed: () => context.go('/announcements'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

              // KPI Metric Cards Row
              Row(
                children: [
                  AdminKpiTile(
                    title: l10n.translate('total_users'),
                    value: '${users.length}',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                    subtitle: 'Total Registered Accounts',
                  ),
                  const SizedBox(width: 16),
                  AdminKpiTile(
                    title: l10n.translate('active_tutors'),
                    value: '$tutorsCount',
                    icon: Icons.school_rounded,
                    color: AppColors.secondary,
                    subtitle: 'Instructors & Authors',
                  ),
                  const SizedBox(width: 16),
                  AdminKpiTile(
                    title: l10n.translate('total_students'),
                    value: '$studentsCount',
                    icon: Icons.backpack_rounded,
                    color: AppColors.success,
                    subtitle: 'Enrolled Learners',
                  ),
                  const SizedBox(width: 16),
                  AdminKpiTile(
                    title: l10n.translate('pending_codes'),
                    value: '$activeCodesCount',
                    icon: Icons.confirmation_number_rounded,
                    color: AppColors.accent,
                    subtitle: 'Single-Use Access Tokens',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Two-column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Quick Actions & Recent Accounts
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Action Navigation Card
                        AdminGlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Executive Operations',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildQuickActionBtn(
                                    context,
                                    icon: Icons.add_circle_outline_rounded,
                                    label: l10n.translate('create_subject'),
                                    color: AppColors.primary,
                                    onTap: () => context.go('/subjects'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionBtn(
                                    context,
                                    icon: Icons.key_rounded,
                                    label: l10n.translate('generate_code'),
                                    color: AppColors.accent,
                                    onTap: () => context.go('/signup-codes'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionBtn(
                                    context,
                                    icon: Icons.security_rounded,
                                    label: l10n.translate('permissions'),
                                    color: AppColors.secondary,
                                    onTap: () => context.go('/permissions'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Recent Accounts Table
                        AdminGlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent User Accounts',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/users'),
                                    child: const Text('View All Users'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (users.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No accounts found.',
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: users.take(5).length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                  itemBuilder: (context, index) {
                                    final u = users[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                            child: Icon(
                                              u.role == UserRole.tutor
                                                  ? Icons.school_rounded
                                                  : Icons.person_rounded,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  u.displayName,
                                                  style: TextStyle(
                                                    color: theme.colorScheme.onSurface,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '@${u.username} • ${u.role.label}',
                                                  style: TextStyle(
                                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (u.isActive ? AppColors.success : AppColors.error)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              u.isActive ? 'ACTIVE' : 'DEACTIVATED',
                                              style: TextStyle(
                                                color: u.isActive ? AppColors.success : AppColors.error,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Column: Academic Subjects & Platform Health
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        // Academic Subjects Card
                        AdminGlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.translate('subjects'),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/subjects'),
                                    child: const Text('Manage'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (subjects.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'No academic subjects configured.',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: subjects.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.book_rounded, size: 14, color: AppColors.secondary),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.name,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // System Security & Platform Status Card
                        AdminGlassCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hardware & Security Health',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSecurityRow(
                                title: 'Device Binding Enforcement',
                                subtitle: 'x-device-id header verification active',
                                icon: Icons.fingerprint_rounded,
                                isOk: true,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityRow(
                                title: 'Screen Capture Lockdown',
                                subtitle: 'FLAG_SECURE mobile enforcement active',
                                icon: Icons.screenshot_rounded,
                                isOk: true,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              _buildSecurityRow(
                                title: 'Desktop Temporary Sessions',
                                subtitle: 'Auto memory & token wipe on close',
                                icon: Icons.desktop_windows_rounded,
                                isOk: true,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOk,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isOk ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isOk ? AppColors.success : AppColors.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isOk ? AppColors.success : AppColors.error,
          size: 18,
        ),
      ],
    );
  }
}
