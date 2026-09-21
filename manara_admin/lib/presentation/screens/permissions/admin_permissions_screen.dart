import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/permissions/admin_permissions_bloc.dart';
import '../../blocs/subjects/admin_subjects_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminPermissionsScreen extends StatefulWidget {
  const AdminPermissionsScreen({super.key});

  @override
  State<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends State<AdminPermissionsScreen> {
  final _tutorIdController = TextEditingController();
  final _tutorSubjectIdController = TextEditingController();

  final _studentIdController = TextEditingController();
  final _studentCourseIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load subjects for easy selection helper if available
    context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested());
  }

  @override
  void dispose() {
    _tutorIdController.dispose();
    _tutorSubjectIdController.dispose();
    _studentIdController.dispose();
    _studentCourseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AdminPermissionsBloc, AdminPermissionsState>(
      listener: (context, state) {
        if (state is AdminPermissionsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AdminPermissionsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, permState) {
        final isLoading = permState is AdminPermissionsLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.translate('permissions'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Delegate tutor academic authority and grant direct student course enrollments',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Two Column Cards for Desktop
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTutorCard(context, l10n, isDark, isLoading)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStudentCard(context, l10n, isDark, isLoading)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildTutorCard(context, l10n, isDark, isLoading),
                        const SizedBox(height: 24),
                        _buildStudentCard(context, l10n, isDark, isLoading),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // Information Box on Security & Governance
              AdminGlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security_update_good_rounded, color: AppColors.info, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrative Security Governance',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tutor assignment binds academic syllabus editing rights to the designated teacher account. '
                            'Student course grants bypass default payment gateways and grant perpetual or term-bound educational access.',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorCard(BuildContext context, AppLocalization l10n, bool isDark, bool isLoading) {
    final theme = Theme.of(context);

    return AdminGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('assign_subject'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Link teacher account to an academic curriculum',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tutor ID input
          TextField(
            controller: _tutorIdController,
            decoration: InputDecoration(
              labelText: l10n.translate('tutor_id'),
              hintText: 'e.g. usr_tut_9921',
              prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subject ID input
          TextField(
            controller: _tutorSubjectIdController,
            decoration: InputDecoration(
              labelText: l10n.translate('subject_id'),
              hintText: 'e.g. sub_math_101',
              prefixIcon: const Icon(Icons.book_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons (Assign / Unassign)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final tutorId = _tutorIdController.text.trim();
                          final subjectId = _tutorSubjectIdController.text.trim();
                          if (tutorId.isEmpty || subjectId.isEmpty) return;
                          context.read<AdminPermissionsBloc>().add(
                                AdminAssignTutorSubjectRequested(
                                  tutorId: tutorId,
                                  subjectId: subjectId,
                                ),
                              );
                        },
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Assign'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final tutorId = _tutorIdController.text.trim();
                          final subjectId = _tutorSubjectIdController.text.trim();
                          if (tutorId.isEmpty || subjectId.isEmpty) return;
                          context.read<AdminPermissionsBloc>().add(
                                AdminUnassignTutorSubjectRequested(
                                  tutorId: tutorId,
                                  subjectId: subjectId,
                                ),
                              );
                        },
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text('Unassign'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, AppLocalization l10n, bool isDark, bool isLoading) {
    final theme = Theme.of(context);

    return AdminGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('grant_access'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Direct enrollment privilege override',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student ID input
          TextField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: l10n.translate('student_id'),
              hintText: 'e.g. usr_stu_5541',
              prefixIcon: const Icon(Icons.badge_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Course ID input
          TextField(
            controller: _studentCourseIdController,
            decoration: InputDecoration(
              labelText: l10n.translate('course_id'),
              hintText: 'e.g. crs_calc_401',
              prefixIcon: const Icon(Icons.play_lesson_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons (Grant / Revoke)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final studentId = _studentIdController.text.trim();
                          final courseId = _studentCourseIdController.text.trim();
                          if (studentId.isEmpty || courseId.isEmpty) return;
                          context.read<AdminPermissionsBloc>().add(
                                AdminGrantStudentCourseRequested(
                                  studentId: studentId,
                                  courseId: courseId,
                                ),
                              );
                        },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Grant Access'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final studentId = _studentIdController.text.trim();
                          final courseId = _studentCourseIdController.text.trim();
                          if (studentId.isEmpty || courseId.isEmpty) return;
                          context.read<AdminPermissionsBloc>().add(
                                AdminRevokeStudentCourseRequested(
                                  studentId: studentId,
                                  courseId: courseId,
                                ),
                              );
                        },
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
