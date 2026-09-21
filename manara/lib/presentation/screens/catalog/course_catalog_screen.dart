import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/catalog/catalog_bloc.dart';
import '../../blocs/catalog/catalog_event.dart';
import '../../blocs/catalog/catalog_state.dart';
import '../../widgets/shimmer_loading.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(const CatalogFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      context.read<CatalogBloc>().add(CatalogSearchQueryChanged(val.trim()));
                    },
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.translate('search_courses_hint'),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<CatalogBloc>().add(const CatalogSearchQueryChanged(''));
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subject Filter Chips
                  BlocBuilder<CatalogBloc, CatalogState>(
                    builder: (context, state) {
                      final subjects = state is CatalogLoaded ? state.subjects : [];
                      final selectedSubjectId = state is CatalogLoaded ? state.selectedSubjectId : null;

                      return SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: subjects.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final isSelected = isAll ? selectedSubjectId == null : selectedSubjectId == subjects[index - 1].id;
                            final label = isAll ? l10n.translate('all_subjects') : subjects[index - 1].name;

                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (_) {
                                context.read<CatalogBloc>().add(
                                      CatalogFilterSubjectChanged(isAll ? null : subjects[index - 1].id),
                                    );
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.25),
                              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Courses Content Area
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state is CatalogLoading) {
                    return isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 340,
                              childAspectRatio: 1.15,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: 6,
                            itemBuilder: (_, _) => const CourseCardShimmer(),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: 4,
                            itemBuilder: (_, _) => const CourseCardShimmer(),
                          );
                  }

                  if (state is CatalogLoaded) {
                    final courses = state.courses;
                    if (courses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No courses found matching your criteria.',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (isDesktop) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return AppAnimations.staggeredEntrance(
                            index: index,
                            _CourseGridCard(course: course),
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return AppAnimations.staggeredEntrance(
                          index: index,
                          _CourseListCard(course: course),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseListCard extends StatelessWidget {
  final dynamic course;

  const _CourseListCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return GlassCard(
      onTap: () => context.push('/courses/${course.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Hero(
              tag: 'course_thumb_${course.id}',
              child: Image.network(
                course.imageUrl,
                width: 100,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 100,
                  height: 84,
                  color: AppColors.darkSurfaceElevated,
                  child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
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
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      course.ratingAverage.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      course.price == 0 ? l10n.translate('free') : '\$${course.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseGridCard extends StatelessWidget {
  final dynamic course;

  const _CourseGridCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return GlassCard(
      onTap: () => context.push('/courses/${course.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Hero(
                tag: 'course_thumb_${course.id}',
                child: Image.network(
                  course.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.darkSurfaceElevated,
                    child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  course.tutorName ?? l10n.translate('tutor'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          course.ratingAverage.toStringAsFixed(1),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      course.price == 0 ? l10n.translate('free') : '\$${course.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
