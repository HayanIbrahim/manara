import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../blocs/exam/exam_bloc.dart';
import '../../blocs/exam/exam_event.dart';
import '../../blocs/exam/exam_state.dart';

class ExamScreen extends StatefulWidget {
  final String examId;
  final ExamEntity? initialExam;

  const ExamScreen({super.key, required this.examId, this.initialExam});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final Map<String, TextEditingController> _textControllers = {};
  final _attachmentUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final exam = widget.initialExam ??
        ExamEntity(
          id: widget.examId,
          courseId: 'course_1',
          title: 'Midterm Comprehensive Examination',
          instructions: 'Answer all multiple choice questions and provide a concise written summary for section 2.',
          points: 100,
          questions: const [
            ExamQuestionEntity(
              id: 'q1',
              type: ExamQuestionType.multipleChoice,
              prompt: 'Which HTTP header is mandatory on mobile requests for student/tutor accounts?',
              choices: [
                'x-api-version',
                'x-device-id',
                'x-platform-origin',
                'x-user-agent',
              ],
            ),
            ExamQuestionEntity(
              id: 'q2',
              type: ExamQuestionType.written,
              prompt: 'Explain the mechanism used to ensure temporary desktop sessions are not persisted.',
            ),
            ExamQuestionEntity(
              id: 'q3',
              type: ExamQuestionType.multipleChoice,
              prompt: 'What status must a desktop challenge reach before the client can exchange it for a JWT?',
              choices: [
                'PENDING',
                'APPROVED',
                'CONSUMED',
                'VERIFIED',
              ],
            ),
          ],
        );

    for (final q in exam.questions) {
      if (q.isWritten) {
        _textControllers[q.id] = TextEditingController();
      }
    }

    context.read<ExamBloc>().add(ExamLoadRequested(exam));
  }

  @override
  void dispose() {
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    _attachmentUrlController.dispose();
    super.dispose();
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
          l10n.translate('exams'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ExamBloc, ExamState>(
        listener: (context, state) {
          if (state is ExamSubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('exam_submitted')),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ExamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ExamActive) {
            final exam = state.exam;
            final answers = state.answers;
            final attachmentUrls = state.attachmentUrls;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.title,
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (exam.instructions != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                exam.instructions!,
                                style: TextStyle(
                                  color: AppColors.adaptiveTextSecondary(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${exam.points} Points Total',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Questions List
                      ...List.generate(exam.questions.length, (index) {
                        final q = exam.questions[index];
                        final currentAnswer = answers[q.id];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: GlassContainer(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${index + 1} • ${q.isMultipleChoice ? 'MCQ' : 'Written'}',
                                        style: TextStyle(
                                          color: AppColors.adaptiveTextMuted(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  q.prompt,
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // MCQ Choices
                                if (q.isMultipleChoice) ...[
                                  ...List.generate(q.choices.length, (cIndex) {
                                    final choice = q.choices[cIndex];
                                    final isSelected = currentAnswer?.choice == cIndex;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () {
                                          context.read<ExamBloc>().add(
                                                ExamAnswerUpdated(
                                                  questionId: q.id,
                                                  choice: cIndex,
                                                ),
                                              );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: 0.15)
                                                : (isDark
                                                    ? AppColors.darkSurfaceElevated
                                                    : AppColors.lightSurfaceElevated),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.secondary
                                                  : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.radio_button_checked_rounded
                                                    : Icons.radio_button_off_rounded,
                                                color: isSelected ? AppColors.secondary : AppColors.adaptiveTextMuted(context),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  choice,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? AppColors.adaptiveTextPrimary(context)
                                                        : AppColors.adaptiveTextSecondary(context),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],

                                // Written Text Area
                                if (q.isWritten) ...[
                                  TextField(
                                    controller: _textControllers[q.id],
                                    maxLines: 4,
                                    onChanged: (text) {
                                      context.read<ExamBloc>().add(
                                            ExamAnswerUpdated(
                                              questionId: q.id,
                                              text: text,
                                            ),
                                          );
                                    },
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextPrimary(context),
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: l10n.translate('written_answer_hint'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                      // Image Attachments Section
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_file_rounded, color: AppColors.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.translate('upload_image'),
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextPrimary(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _attachmentUrlController,
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextPrimary(context),
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter image URL (e.g. https://...)...',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    final url = _attachmentUrlController.text.trim();
                                    if (url.isNotEmpty) {
                                      context.read<ExamBloc>().add(ExamAddAttachmentUrlRequested(url));
                                      _attachmentUrlController.clear();
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            if (attachmentUrls.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: attachmentUrls.map((url) {
                                  return Chip(
                                    label: Text(
                                      url,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.adaptiveTextPrimary(context),
                                      ),
                                    ),
                                    backgroundColor: isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceElevated,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Submit Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: GlowingGlassButton(
                      text: l10n.translate('submit_exam'),
                      isLoading: state.isSubmitting,
                      onPressed: () => context.read<ExamBloc>().add(ExamSubmitRequested()),
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is ExamSubmissionSuccess) {
            final sub = state.submission;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
                      const SizedBox(height: 18),
                      Text(
                        l10n.translate('exam_submitted'),
                        style: TextStyle(
                          color: AppColors.adaptiveTextPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${sub.status.name.toUpperCase()}',
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      GlowingGlassButton(
                        text: 'Done',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        },
      ),
    );
  }
}
