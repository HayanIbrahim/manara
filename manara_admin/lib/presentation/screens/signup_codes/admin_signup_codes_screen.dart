import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/signup_codes/admin_signup_codes_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminSignupCodesScreen extends StatefulWidget {
  const AdminSignupCodesScreen({super.key});

  @override
  State<AdminSignupCodesScreen> createState() => _AdminSignupCodesScreenState();
}

class _AdminSignupCodesScreenState extends State<AdminSignupCodesScreen> {
  UserRole _selectedRole = UserRole.student;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 14));
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminSignupCodesBloc>().add(AdminFetchSignupCodesRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String code) {
    final l10n = AppLocalization.of(context);
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.translate('copied')} ($code)'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('signup_codes'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate and track single-use onboarding registration codes.',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Code Generator Panel Card
              AdminGlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Role Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserRole>(
                          value: _selectedRole,
                          dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          items: [
                            DropdownMenuItem(
                              value: UserRole.student,
                              child: Text('Role: ${l10n.translate('student')}'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.tutor,
                              child: Text('Role: ${l10n.translate('tutor')}'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Expiration Picker
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        'Expires: ${DateFormat('yyyy-MM-dd').format(_expirationDate)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expirationDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _expirationDate = picked);
                      },
                    ),
                    const SizedBox(width: 14),

                    // Generate Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.vpn_key_rounded, size: 16),
                      label: Text(l10n.translate('generate_code')),
                      onPressed: () {
                        context.read<AdminSignupCodesBloc>().add(
                              AdminGenerateSignupCodeRequested(
                                role: _selectedRole,
                                expiresAt: _expirationDate,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Freshly Created Code Banner
              BlocBuilder<AdminSignupCodesBloc, AdminSignupCodesState>(
                builder: (context, state) {
                  if (state is AdminSignupCodesLoaded && state.newlyCreatedCode != null) {
                    final newCode = state.newlyCreatedCode!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New single-use code generated successfully (share with user):',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                SelectableText(
                                  newCode.code,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text(l10n.translate('copy')),
                            onPressed: () => _copyToClipboard(newCode.code),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Search bar
              SizedBox(
                width: 380,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search code or used by...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Codes Table
              Expanded(
                child: AdminGlassCard(
                  padding: EdgeInsets.zero,
                  child: BlocBuilder<AdminSignupCodesBloc, AdminSignupCodesState>(
                    builder: (context, state) {
                      if (state is AdminSignupCodesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is AdminSignupCodesLoaded) {
                        final query = _searchController.text.trim().toLowerCase();
                        final filtered = state.codes.where((c) {
                          if (query.isEmpty) return true;
                          return c.code.toLowerCase().contains(query) ||
                              c.id.toLowerCase().contains(query) ||
                              (c.usedBy?.toLowerCase().contains(query) ?? false);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No signup codes found.',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              ),
                              columns: [
                                DataColumn(label: Text(l10n.translate('code'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('role'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('expires_at'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('used_by'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((c) {
                                final isTutor = c.role == UserRole.tutor;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      c.code.isNotEmpty
                                          ? SelectableText(
                                              c.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : Tooltip(
                                              message: 'Code is cryptographically hashed in database for security. Plaintext is only revealed upon creation.',
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '••••••••',
                                                    style: TextStyle(
                                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                      letterSpacing: 2.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      c.id.length > 8 ? c.id.substring(c.id.length - 6) : (c.id.isEmpty ? 'HASHED' : c.id),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontFamily: 'monospace',
                                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (isTutor ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.role.label,
                                          style: TextStyle(
                                            color: isTutor ? AppColors.secondary : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Builder(
                                        builder: (context) {
                                          final isExpired = !c.isUsed && DateTime.now().isAfter(c.expiresAt);
                                          final Color badgeColor;
                                          final String statusText;
                                          if (c.isUsed) {
                                            badgeColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
                                            statusText = 'USED';
                                          } else if (isExpired) {
                                            badgeColor = AppColors.warning;
                                            statusText = 'EXPIRED';
                                          } else {
                                            badgeColor = AppColors.success;
                                            statusText = 'AVAILABLE';
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(Text(DateFormat('yyyy-MM-dd').format(c.expiresAt))),
                                    DataCell(Text(c.usedBy ?? '—')),
                                    DataCell(
                                      IconButton(
                                        icon: Icon(
                                          c.code.isNotEmpty ? Icons.copy_rounded : Icons.info_outline_rounded,
                                          size: 16,
                                          color: c.isUsed
                                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                              : (c.code.isNotEmpty ? null : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                        ),
                                        onPressed: () {
                                          if (c.isUsed) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('⚠️ This signup code has already been consumed on the server and cannot be reused.'),
                                                backgroundColor: AppColors.error,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          } else if (c.code.isNotEmpty) {
                                            _copyToClipboard(c.code);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Plaintext code is only revealed once upon creation. Backend stores cryptographically hashed codes for security.'),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: c.isUsed
                                            ? 'Code Already Used'
                                            : (c.code.isNotEmpty ? l10n.translate('copy') : 'Security Info'),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
