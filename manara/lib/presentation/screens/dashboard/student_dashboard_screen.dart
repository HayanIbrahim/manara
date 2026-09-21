import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/security/security_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/student/student_bloc.dart';
import '../../blocs/student/student_event.dart';
import '../../blocs/student/student_state.dart';
import '../../widgets/achievement_badge_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../desktop_pairing/mobile_qr_scanner_sheet.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StudentBloc>().add(StudentLoadDashboardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isMobile = SecurityService.instance.isMobilePlatform ||
        MediaQuery.of(context).size.width < 840;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 880;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            context.read<StudentBloc>().add(StudentRefreshRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Header with greeting & QR scan trigger
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.translate('continue_learning')},',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.displayName ?? 'Student',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Points pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${user?.points ?? 250} ${l10n.translate('points')}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMobile) ...[
                            const SizedBox(width: 10),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.lightSurfaceElevated,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary, size: 20),
                              onPressed: () => MobileQrScannerSheet.show(context),
                              tooltip: l10n.translate('mobile_scan_qr'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Desktop KPI Metrics Row (Only shown on Desktop)
              if (isDesktop)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<StudentBloc, StudentState>(
                      builder: (context, state) {
                        final courseCount = state is StudentDashboardLoaded ? state.enrolledCourses.length : 0;
                        final achievementCount = state is StudentDashboardLoaded ? state.achievements.length : 0;
                        final announcementCount = state is StudentDashboardLoaded ? state.announcements.length : 0;

                        return Row(
                          children: [
                            _buildKpiCard(
                              context,
                              icon: Icons.auto_stories_rounded,
                              iconColor: AppColors.primary,
                              label: l10n.translate('enrolled_courses'),
                              value: '$courseCount',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 14),
                            _buildKpiCard(
                              context,
                              icon: Icons.military_tech_rounded,
                              iconColor: AppColors.gold,
                              label: l10n.translate('achievements'),
                              value: '$achievementCount',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 14),
                            _buildKpiCard(
                              context,
                              icon: Icons.campaign_rounded,
                              iconColor: AppColors.secondary,
                              label: l10n.translate('announcements'),
                              value: '$announcementCount',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 14),
                            _buildKpiCard(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              iconColor: AppColors.tertiary,
                              label: 'Learning Streak',
                              value: '5 Days',
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // Overall Progress Hero Card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: AppAnimations.staggeredEntrance(
                    index: 0,
                    GlassCard(
                      borderRadius: 24,
                      glowColor: AppColors.primary,
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Learning Momentum',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Keep your streak going by finishing quizzes today!',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: const LinearProgressIndicator(
                                    value: 0.72,
                                    minHeight: 8,
                                    backgroundColor: AppColors.darkSurface,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '72%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Enrolled Courses Section Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('enrolled_courses'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/courses'),
                        child: Text(
                          l10n.translate('browse_courses'),
                          style: const TextStyle(color: AppColors.secondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Enrolled Courses List
              BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoading) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const CourseCardShimmer(),
                          childCount: 2,
                        ),
                      ),
                    );
                  }

                  if (state is StudentDashboardLoaded) {
                    final courses = state.enrolledCourses;
                    if (courses.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurfaceElevated.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                l10n.translate('no_enrolled_courses'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/courses'),
                                child: Text(l10n.translate('browse_courses')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final course = courses[index];
                            return AppAnimations.staggeredEntrance(
                              index: index,
                              GlassCard(
                                onTap: () => context.push('/player/${course.id}'),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Hero(
                                        tag: 'course_thumb_${course.id}',
                                        child: Image.network(
                                          course.imageUrl,
                                          width: 90,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 90,
                                            height: 75,
                                            color: AppColors.darkSurfaceElevated,
                                            child: const Icon(Icons.book_rounded, color: AppColors.textMuted),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course.tutorName ?? l10n.translate('tutor'),
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: const LinearProgressIndicator(
                                              value: 0.60,
                                              minHeight: 5,
                                              backgroundColor: AppColors.darkSurface,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: courses.length,
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              // Announcements Feed Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l10n.translate('announcements'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentDashboardLoaded && state.announcements.isNotEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = state.announcements[index];
                            return GlassCard(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.campaign_rounded, color: AppColors.secondary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: state.announcements.length,
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              // Achievements Preview Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('achievements'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/achievements'),
                        child: const Text('View All', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentDashboardLoaded && state.achievements.isNotEmpty) {
                    final previewList = state.achievements.take(2).toList();
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => AchievementBadgeWidget(achievement: previewList[index]),
                          childCount: previewList.length,
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox(height: 40));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x0A0F172A),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
