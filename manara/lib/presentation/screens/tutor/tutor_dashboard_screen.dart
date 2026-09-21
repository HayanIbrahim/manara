import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../../domain/entities/quiz_entities.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../desktop_pairing/mobile_qr_scanner_sheet.dart';
import '../../blocs/tutor/tutor_bloc.dart';
import '../../blocs/tutor/tutor_event.dart';
import '../../blocs/tutor/tutor_state.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TutorBloc>().add(TutorLoadCoursesRequested());
  }

  void _showCreateCourseDialog(BuildContext context) async {
    final l10n = AppLocalization.of(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '49.99');
    final imgCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600');

    List<SubjectEntity> subjects = [];
    try {
      subjects = await context.read<CatalogRepository>().getSubjects();
    } catch (_) {}

    String? selectedSubjectId = subjects.isNotEmpty ? subjects.first.id : null;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n.translate('create_course'),
              style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
            ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Course Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imgCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Cover Image URL'),
                ),
                const SizedBox(height: 16),
                if (subjects.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.darkSurfaceElevated,
                    style: const TextStyle(color: AppColors.textPrimary),
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(labelText: 'Select Assigned Subject'),
                    items: subjects
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, style: const TextStyle(color: AppColors.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedSubjectId = val);
                    },
                  ),
                ] else ...[
                  const Text(
                    'Note: Make sure an administrator has assigned a subject to your tutor account.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final img = imgCtrl.text.trim();
                final subjectId = selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : '');

                if (name.isNotEmpty && subjectId.isNotEmpty) {
                  context.read<TutorBloc>().add(
                        TutorCreateCourseSubmitted(
                          name: name,
                          description: desc.isNotEmpty ? desc : 'Comprehensive curriculum.',
                          imageUrl: img.isNotEmpty
                              ? img
                              : 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600',
                          price: price,
                          subjectId: subjectId,
                        ),
                      );
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a course name and ensure a subject is assigned.')),
                  );
                }
              },
              child: const Text('Create Course'),
            ),
          ],
        ),
      );
    },
  );
}

  void _showAddExamDialog(BuildContext context, String courseId) {
    final titleCtrl = TextEditingController(text: 'Midterm Examination');
    final instrCtrl = TextEditingController(text: 'Answer all questions thoroughly.');
    final pointsCtrl = TextEditingController(text: '50');
    final qPromptCtrl =
        TextEditingController(text: 'Explain the core principles covered in this course module.');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Course Exam',
            style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
          ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Exam Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instrCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Points (default: 50)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qPromptCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Question 1 Prompt (Written)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final instructions = instrCtrl.text.trim();
              final points = int.tryParse(pointsCtrl.text.trim()) ?? 50;
              final prompt = qPromptCtrl.text.trim();

              if (title.isNotEmpty && prompt.isNotEmpty) {
                final questions = [
                  ExamQuestionEntity(
                    id: 'q_${DateTime.now().millisecondsSinceEpoch}',
                    type: ExamQuestionType.written,
                    prompt: prompt,
                  ),
                ];
                context.read<TutorBloc>().add(
                      TutorCreateExamSubmitted(
                        courseId: courseId,
                        title: title,
                        instructions: instructions,
                        points: points,
                        questions: questions,
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create Exam'),
          ),
        ],
      );
    },
  );
}

  void _showAddLectureDialog(BuildContext context, String courseId, int defaultPosition) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final posCtrl = TextEditingController(text: defaultPosition.toString());
    final l10n = AppLocalization.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.translate('create_lecture'),
            style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
          ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Lecture Title'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Video URL (Stream / Drive)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: posCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Position Order (e.g. 1, 2, 3)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                final pos = int.tryParse(posCtrl.text.trim()) ?? defaultPosition;
                context.read<TutorBloc>().add(
                      TutorCreateLectureSubmitted(
                        courseId: courseId,
                        title: titleCtrl.text.trim(),
                        position: pos,
                        videoUrl: urlCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  void _showAddQuizDialog(BuildContext context, {String initialLectureId = ''}) {
    final lectureIdCtrl = TextEditingController(text: initialLectureId);

    // Initialize 5 questions to satisfy backend z.array().min(5) requirement
    final List<Map<String, TextEditingController>> questionCtrls = List.generate(5, (index) {
      return {
        'prompt': TextEditingController(text: 'Question ${index + 1}: Key concept check?'),
        'c0': TextEditingController(text: 'Option A (Correct)'),
        'c1': TextEditingController(text: 'Option B'),
        'c2': TextEditingController(text: 'Option C'),
        'c3': TextEditingController(text: 'Option D'),
      };
    });

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Create Mandatory Quiz (5 Questions)',
              style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
            ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: lectureIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Target Lecture ID'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Backend requires at least 5 verification questions for lecture unlocking:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(questionCtrls.length, (qIndex) {
                    final q = questionCtrls[qIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question #${qIndex + 1}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: q['prompt'],
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              decoration: const InputDecoration(labelText: 'Prompt', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: q['c0'],
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Choice 1 (Correct Answer)', isDense: true),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: q['c1'],
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Choice 2', isDense: true),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: q['c2'],
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Choice 3', isDense: true),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: q['c3'],
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Choice 4', isDense: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final targetLectureId = lectureIdCtrl.text.trim();
                if (targetLectureId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid Lecture ID'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                final questions = questionCtrls.map((q) {
                  return QuizQuestionEntity(
                    prompt: q['prompt']!.text.trim(),
                    choices: [
                      q['c0']!.text.trim(),
                      q['c1']!.text.trim(),
                      q['c2']!.text.trim(),
                      q['c3']!.text.trim(),
                    ],
                    correctChoice: 0,
                  );
                }).toList();

                context.read<TutorBloc>().add(
                      TutorPutQuizSubmitted(
                        lectureId: targetLectureId,
                        questions: questions,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save Quiz'),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          l10n.translate('tutor_dashboard'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            tooltip: 'Refresh Courses',
            onPressed: () => context.read<TutorBloc>().add(TutorLoadCoursesRequested()),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
            tooltip: 'Pair Desktop App',
            onPressed: () => MobileQrScannerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.grading_rounded, color: AppColors.secondary),
            tooltip: l10n.translate('submissions_to_grade'),
            onPressed: () => context.push('/tutor/grade'),
          ),
        ],
      ),
      body: BlocConsumer<TutorBloc, TutorState>(
        listener: (context, state) {
          if (state is TutorActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is TutorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is TutorLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          final courses = state is TutorCoursesLoaded ? state.courses : <CourseEntity>[];

          return RefreshIndicator(
            color: AppColors.secondary,
            backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            onRefresh: () async {
              context.read<TutorBloc>().add(TutorLoadCoursesRequested());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Tutor Overview Stats
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.school_outlined, color: AppColors.secondary, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              '${courses.length}',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'My Courses',
                              style: TextStyle(
                                color: AppColors.adaptiveTextMuted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, color: AppColors.gold, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              '${courses.fold<int>(0, (sum, c) => sum + c.videoCount)}',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Lectures',
                              style: TextStyle(
                                color: AppColors.adaptiveTextMuted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action buttons bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('tutor_manage_courses'),
                      style: TextStyle(
                        color: AppColors.adaptiveTextPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.translate('create_course')),
                      onPressed: () => _showCreateCourseDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (courses.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 56, color: AppColors.adaptiveTextMuted(context)),
                        const SizedBox(height: 12),
                        Text(
                          'No courses created yet',
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Create Course" to publish your first academic syllabus under an assigned subject.',
                          style: TextStyle(color: AppColors.adaptiveTextMuted(context), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

              // Courses list
              ...List.generate(courses.length, (index) {
                final course = courses[index];
                return AppAnimations.staggeredEntrance(
                  index: index,
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                course.imageUrl,
                                width: 60,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Container(width: 60, height: 50, color: Colors.white12),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          course.name,
                                          style: TextStyle(
                                            color: AppColors.adaptiveTextPrimary(context),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: course.published
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : AppColors.warning.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: course.published
                                                ? AppColors.success.withValues(alpha: 0.4)
                                                : AppColors.warning.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          course.published ? 'PUBLISHED' : 'DRAFT',
                                          style: TextStyle(
                                            color: course.published ? AppColors.success : AppColors.warning,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course.videoCount} lectures • \$${course.price.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: Icon(
                                course.published ? Icons.visibility_off_outlined : Icons.publish_rounded,
                                size: 16,
                                color: course.published ? AppColors.warning : AppColors.success,
                              ),
                              label: Text(
                                course.published ? 'Unpublish' : 'Publish',
                                style: TextStyle(
                                  color: course.published ? AppColors.warning : AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: () {
                                context.read<TutorBloc>().add(
                                      TutorPublishCourseSubmitted(
                                        courseId: course.id,
                                        published: !course.published,
                                      ),
                                    );
                              },
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.video_call_rounded, size: 16),
                              label: Text(l10n.translate('create_lecture'), style: const TextStyle(fontSize: 12)),
                              onPressed: () =>
                                  _showAddLectureDialog(context, course.id, course.videoCount + 1),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.assignment_outlined, size: 16),
                              label: const Text('Add Exam', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showAddExamDialog(context, course.id),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.quiz_rounded, size: 16),
                              label: Text(l10n.translate('create_quiz'), style: const TextStyle(fontSize: 12)),
                              onPressed: () => _showAddQuizDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    ),
  );
}
}
