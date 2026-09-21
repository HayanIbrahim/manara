import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/announcements/admin_announcements_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _courseIdController = TextEditingController();
  String _selectedRole = 'ALL';

  @override
  void initState() {
    super.initState();
    context.read<AdminAnnouncementsBloc>().add(AdminFetchAnnouncementsRequested());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _courseIdController.dispose();
    super.dispose();
  }

  void _submitBroadcast() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    context.read<AdminAnnouncementsBloc>().add(
          AdminCreateAnnouncementRequested(
            title: title,
            message: message,
            targetRole: _selectedRole,
            courseId: _courseIdController.text.trim().isEmpty ? null : _courseIdController.text.trim(),
          ),
        );

    _titleController.clear();
    _messageController.clear();
    _courseIdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AdminAnnouncementsBloc, AdminAnnouncementsState>(
      listener: (context, state) {
        if (state is AdminAnnouncementsLoaded && state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AdminAnnouncementsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminAnnouncementsBloc>().add(AdminFetchAnnouncementsRequested());
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('announcements'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issue system-wide alerts, cohort announcements, or course-specific notifications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context.read<AdminAnnouncementsBloc>().add(AdminFetchAnnouncementsRequested());
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive Two-Column Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Creation Form
                        SizedBox(
                          width: 420,
                          child: _buildCreateForm(context, l10n, isDark),
                        ),
                        const SizedBox(width: 24),
                        // Right: Announcements List
                        Expanded(
                          child: _buildAnnouncementsList(context, state, l10n, isDark),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildCreateForm(context, l10n, isDark),
                        const SizedBox(height: 24),
                        _buildAnnouncementsList(context, state, l10n, isDark),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
    );
  }

  Widget _buildCreateForm(BuildContext context, AppLocalization l10n, bool isDark) {
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('send_broadcast'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Push real-time alert to platform apps',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.translate('broadcast_title'),
              hintText: 'e.g. Platform Maintenance Notice',
              prefixIcon: const Icon(Icons.title_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.translate('broadcast_message'),
              hintText: 'Provide full broadcast announcement text...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Role
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: l10n.translate('target_role'),
              prefixIcon: const Icon(Icons.group_rounded, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'ALL', child: Text(l10n.translate('all'))),
              DropdownMenuItem(value: 'STUDENT', child: Text(l10n.translate('student'))),
              DropdownMenuItem(value: 'TUTOR', child: Text(l10n.translate('tutor'))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
          const SizedBox(height: 16),

          // Optional Course ID
          TextField(
            controller: _courseIdController,
            decoration: InputDecoration(
              labelText: '${l10n.translate('course_id')} (Optional)',
              hintText: 'Leave empty for system-wide',
              prefixIcon: const Icon(Icons.school_outlined, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitBroadcast,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(l10n.translate('send_broadcast')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(
    BuildContext context,
    AdminAnnouncementsState state,
    AppLocalization l10n,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    if (state is AdminAnnouncementsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is AdminAnnouncementsLoaded && state.announcements.isEmpty) {
      return AdminGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 56,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No past broadcasts recorded',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AdminAnnouncementsLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Published Broadcasts (${state.announcements.length})',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.announcements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ann = state.announcements[index];
              return _buildAnnouncementCard(context, ann, l10n, isDark);
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementEntity ann,
    AppLocalization l10n,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    Color badgeColor;
    switch (ann.targetRole.toUpperCase()) {
      case 'STUDENT':
        badgeColor = AppColors.primary;
        break;
      case 'TUTOR':
        badgeColor = AppColors.secondary;
        break;
      default:
        badgeColor = AppColors.info;
        break;
    }

    return AdminGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ann.targetRole.toUpperCase(),
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (ann.courseId != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Course: ${ann.courseId}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${ann.createdAt.day}/${ann.createdAt.month}/${ann.createdAt.year} ${ann.createdAt.hour.toString().padLeft(2, '0')}:${ann.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ann.title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ann.body,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
