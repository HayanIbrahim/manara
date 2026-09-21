import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/subjects/admin_subjects_bloc.dart';
import '../../widgets/admin_glass_widgets.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSubjectDialog({SubjectEntity? existing}) {
    final l10n = AppLocalization.of(context);
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final iconCtrl = TextEditingController(text: existing?.iconUrl ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(isEdit ? l10n.translate('edit_subject') : l10n.translate('create_subject')),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.translate('subject_name')),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(labelText: l10n.translate('subject_code')),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.translate('description')),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(labelText: 'Icon URL (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final code = codeCtrl.text.trim();
                if (name.isEmpty) return;

                if (isEdit) {
                  context.read<AdminSubjectsBloc>().add(
                        AdminUpdateSubjectRequested(
                          id: existing.id,
                          name: name,
                          code: code,
                          description: descCtrl.text.trim(),
                          iconUrl: iconCtrl.text.trim(),
                        ),
                      );
                } else {
                  context.read<AdminSubjectsBloc>().add(
                        AdminCreateSubjectRequested(
                          name: name,
                          code: code,
                          description: descCtrl.text.trim(),
                          iconUrl: iconCtrl.text.trim(),
                        ),
                      );
                }
                Navigator.pop(dialogCtx);
              },
              child: Text(l10n.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(SubjectEntity subject) {
    final l10n = AppLocalization.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.translate('delete_subject')),
        content: Text('${l10n.translate('confirm_delete')}\n\n"${subject.name}" (${subject.code})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<AdminSubjectsBloc>().add(AdminDeleteSubjectRequested(subject.id));
              Navigator.pop(dialogCtx);
            },
            child: Text(l10n.translate('delete')),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                        l10n.translate('subjects'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define academic domains, curriculum subjects, and assignable areas.',
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
                        tooltip: 'Refresh Subjects',
                        onPressed: () => context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested()),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.translate('create_subject')),
                        onPressed: () => _showSubjectDialog(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search bar
              SizedBox(
                width: 380,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search subjects...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subjects Table Card
              Expanded(
                child: AdminGlassCard(
                  padding: EdgeInsets.zero,
                  child: BlocConsumer<AdminSubjectsBloc, AdminSubjectsState>(
                    listener: (context, state) {
                      if (state is AdminSubjectsLoaded && state.successMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.successMessage!),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else if (state is AdminSubjectsError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AdminSubjectsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is AdminSubjectsLoaded) {
                        final query = _searchController.text.trim().toLowerCase();
                        final filtered = state.subjects.where((s) {
                          if (query.isEmpty) return true;
                          return s.name.toLowerCase().contains(query) ||
                              s.code.toLowerCase().contains(query);
                        }).toList();

                        if (filtered.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested());
                              await Future.delayed(const Duration(milliseconds: 600));
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No subjects match the search query.',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<AdminSubjectsBloc>().add(AdminFetchSubjectsRequested());
                            await Future.delayed(const Duration(milliseconds: 600));
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              ),
                              columns: [
                                DataColumn(label: Text(l10n.translate('subject_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('subject_code'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('description'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Courses', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.translate('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.book_rounded, size: 16, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          s.code,
                                          style: const TextStyle(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Text(
                                          s.description ?? '—',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('${s.coursesCount}')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                                            onPressed: () => _showSubjectDialog(existing: s),
                                            tooltip: l10n.translate('edit_subject'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                            onPressed: () => _confirmDelete(s),
                                            tooltip: l10n.translate('delete_subject'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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
