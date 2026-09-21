import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../blocs/tutor/tutor_bloc.dart';
import '../../blocs/tutor/tutor_event.dart';
import '../../blocs/tutor/tutor_state.dart';

class ExamGradingScreen extends StatefulWidget {
  final ExamSubmissionEntity? initialSubmission;

  const ExamGradingScreen({super.key, this.initialSubmission});

  @override
  State<ExamGradingScreen> createState() => _ExamGradingScreenState();
}

class _ExamGradingScreenState extends State<ExamGradingScreen> {
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;
  late final ExamSubmissionEntity _submission;
  bool _publish = true;
  double _scoreSlider = 85;

  @override
  void initState() {
    super.initState();
    _submission = widget.initialSubmission ??
        const ExamSubmissionEntity(
          id: 'sub_101',
          examId: 'exam_midterm_1',
          studentId: 'student_42',
          status: ExamSubmissionStatus.submitted,
          answers: [
            ExamAnswerEntity(
              questionId: 'q1',
              choice: 1,
            ),
            ExamAnswerEntity(
              questionId: 'q2',
              text:
                  'Temporary desktop sessions use short-lived pairing tokens that are held only in memory. When window_manager detects onWindowClose, it triggers /desktop/sessions/current to revoke the token and purges the local cache.',
            ),
          ],
          attachmentUrls: [
            'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
          ],
          examTitle: 'Midterm Security Examination',
        );

    final initialScore = _submission.score ?? 85.0;
    _scoreSlider = initialScore;
    _scoreController = TextEditingController(text: initialScore.round().toString());
    _feedbackController = TextEditingController(
      text: _submission.feedback ??
          'Strong understanding of Clean Architecture principles. Remember to separate data models and entities.',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
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
          l10n.translate('grade_exam'),
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
      body: BlocConsumer<TutorBloc, TutorState>(
        listener: (context, state) {
          if (state is TutorActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isSaving = state is TutorLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student info header card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _submission.examTitle ?? 'Exam Submission',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Student ID: ${_submission.studentId} • Status: ${_submission.status.name.toUpperCase()}',
                              style: TextStyle(
                                color: AppColors.adaptiveTextMuted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Student's Answers Card
                Text(
                  'Submitted Answers',
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                ...List.generate(_submission.answers.length, (index) {
                  final ans = _submission.answers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question #${index + 1}',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (ans.choice != null) ...[
                            Text(
                              'Selected Choice: Option ${ans.choice! + 1}',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (ans.text != null) ...[
                            Text(
                              ans.text!,
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                if (_submission.attachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Attachments',
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _submission.attachmentUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 100,
                            height: 70,
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            child: Icon(Icons.broken_image_rounded, color: AppColors.adaptiveTextMuted(context)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Grading Controls Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Score (0 - 100):',
                            style: TextStyle(
                              color: AppColors.adaptiveTextPrimary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              '${_scoreSlider.round()} / 100',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _scoreSlider,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: AppColors.secondary,
                        inactiveColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        onChanged: (val) {
                          setState(() {
                            _scoreSlider = val;
                            _scoreController.text = val.round().toString();
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Written Feedback
                      Text(
                        l10n.translate('feedback'),
                        style: TextStyle(
                          color: AppColors.adaptiveTextSecondary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        style: TextStyle(
                          color: AppColors.adaptiveTextPrimary(context),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter constructive grading notes for the student...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Publish toggle
                      SwitchListTile(
                        value: _publish,
                        activeThumbColor: AppColors.secondary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.translate('publish_result'),
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Make results immediately visible to the student',
                          style: TextStyle(
                            color: AppColors.adaptiveTextMuted(context),
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (val) => setState(() => _publish = val),
                      ),
                      const SizedBox(height: 14),

                      // Save Grade Button
                      GlowingGlassButton(
                        text: 'Submit Evaluation',
                        isLoading: isSaving,
                        onPressed: () {
                          context.read<TutorBloc>().add(
                                TutorGradeSubmissionSubmitted(
                                  submissionId: _submission.id,
                                  score: _scoreSlider,
                                  feedback: _feedbackController.text.trim(),
                                  publish: _publish,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
