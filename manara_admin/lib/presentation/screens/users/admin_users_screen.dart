import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/users/admin_users_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;
  AccountStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchUsers() {
    context.read<AdminUsersBloc>().add(
          AdminFetchUsersRequested(
            role: _selectedRole,
            status: _selectedStatus,
            search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          ),
        );
  }

  void _showResetDeviceDialog(AccountUserEntity user) {
    final l10n = AppLocalization.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phonelink_erase_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Text(l10n.translate('device_reset')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('device_reset_confirm')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${user.displayName} (@${user.username})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AdminUsersBloc>().add(AdminResetUserDeviceRequested(user.id));
            },
            child: Text(l10n.translate('device_reset')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AdminUsersBloc, AdminUsersState>(
      listener: (context, state) {
        if (state is AdminUsersLoaded && state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AdminUsersError) {
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
            _fetchUsers();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('users'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audit registered accounts, oversee security roles, and reset hardware locks',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _fetchUsers,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Controls Card
              AdminGlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _fetchUsers(),
                        decoration: InputDecoration(
                          hintText: l10n.translate('search'),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchUsers();
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Role Filter Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRole,
                        isDense: true,
                        decoration: InputDecoration(
                          labelText: l10n.translate('role'),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                          DropdownMenuItem(value: UserRole.admin, child: Text(l10n.translate('admin'))),
                          DropdownMenuItem(value: UserRole.tutor, child: Text(l10n.translate('tutor'))),
                          DropdownMenuItem(value: UserRole.student, child: Text(l10n.translate('student'))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedRole = val);
                          _fetchUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<AccountStatus?>(
                        initialValue: _selectedStatus,
                        isDense: true,
                        decoration: InputDecoration(
                          labelText: l10n.translate('status'),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                          DropdownMenuItem(value: AccountStatus.active, child: Text(l10n.translate('active'))),
                          DropdownMenuItem(value: AccountStatus.deactivated, child: Text(l10n.translate('deactivated'))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedStatus = val);
                          _fetchUsers();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Users Table View
              if (state is AdminUsersLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is AdminUsersLoaded && state.users.isEmpty)
                AdminGlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No user accounts match current criteria',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is AdminUsersLoaded)
                AdminGlassCard(
                  padding: const EdgeInsets.all(0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 320,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                          ),
                          dataRowMinHeight: 64,
                          dataRowMaxHeight: 64,
                          horizontalMargin: 20,
                          columnSpacing: 24,
                          columns: [
                            const DataColumn(label: Text('USER / IDENTITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text(l10n.translate('role').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text(l10n.translate('status').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('HARDWARE DEVICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text(l10n.translate('actions').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: state.users.map((user) {
                            return _buildUserRow(context, user, isDark, l10n);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
    );
  }

  DataRow _buildUserRow(BuildContext context, AccountUserEntity user, bool isDark, AppLocalization l10n) {
    Color roleColor;
    IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleColor = AppColors.adminBadge;
        roleIcon = Icons.shield_rounded;
        break;
      case UserRole.tutor:
        roleColor = AppColors.secondary;
        roleIcon = Icons.school_rounded;
        break;
      case UserRole.student:
        roleColor = AppColors.primary;
        roleIcon = Icons.person_rounded;
        break;
    }

    final isActive = user.status == AccountStatus.active;

    return DataRow(
      cells: [
        // User info cell
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '@${user.username} • ${user.email ?? "No email"}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Role badge cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 13, color: roleColor),
                const SizedBox(width: 5),
                Text(
                  user.role.label,
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Status cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? l10n.translate('active') : l10n.translate('deactivated'),
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hardware device cell
        DataCell(
          Row(
            children: [
              Icon(
                user.isDeviceBound ? Icons.phone_android_rounded : Icons.device_unknown_rounded,
                size: 16,
                color: user.isDeviceBound ? AppColors.info : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 6),
              Text(
                user.isDeviceBound
                    ? (user.deviceId != null && user.deviceId!.isNotEmpty
                        ? '${user.deviceId!.substring(0, user.deviceId!.length > 12 ? 12 : user.deviceId!.length)}...'
                        : 'Bound')
                    : 'Unbound',
                style: TextStyle(
                  color: user.isDeviceBound
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: user.isDeviceBound ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        // Actions cell
        DataCell(
          Row(
            children: [
              // Toggle Status
              IconButton(
                icon: Icon(
                  isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: isActive ? AppColors.warning : AppColors.success,
                  size: 20,
                ),
                tooltip: isActive ? l10n.translate('deactivate') : l10n.translate('activate'),
                onPressed: () {
                  context.read<AdminUsersBloc>().add(
                        AdminToggleUserStatusRequested(
                          id: user.id,
                          currentStatus: user.status,
                        ),
                      );
                },
              ),
              const SizedBox(width: 4),

              // Device Reset Button (active only if device is bound)
              IconButton(
                icon: Icon(
                  Icons.phonelink_erase_rounded,
                  color: user.isDeviceBound ? AppColors.error : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  size: 20,
                ),
                tooltip: user.isDeviceBound ? l10n.translate('device_reset') : 'No device bound',
                onPressed: user.isDeviceBound ? () => _showResetDeviceDialog(user) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
