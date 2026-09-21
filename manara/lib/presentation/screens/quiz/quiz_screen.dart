import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/quiz_entities.dart';
import '../../blocs/course_player/course_player_bloc.dart';
import '../../blocs/course_player/course_player_event.dart';
import '../../blocs/quiz/quiz_bloc.dart';
import '../../blocs/quiz/quiz_event.dart';
import '../../blocs/quiz/quiz_state.dart';

class QuizScreen extends StatefulWidget {
  final String lectureId;
  final QuizEntity? initialQuiz;

  const QuizScreen({super.key, required this.lectureId, this.initialQuiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _shakeTrigger = false;

  @override
  void initState() {
    super.initState();
    final quiz = widget.initialQuiz;
    if (quiz != null && quiz.questions.isNotEmpty) {
      context.read<QuizBloc>().add(
            QuizInitializeRequested(lectureId: widget.lectureId, quiz: quiz),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(l10n.translate('mandatory_quiz')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<QuizBloc, QuizState>(
        listener: (context, state) {
          if (state is QuizPassedSuccess) {
            context.read<CoursePlayerBloc>().add(
                  CoursePlayerUnlockNextLectureTriggered(widget.lectureId),
                );
          } else if (state is QuizFailedRetry) {
            setState(() => _shakeTrigger = true);
          } else if (state is QuizError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is QuizActive) {
            final quiz = state.quiz;
            final questions = quiz.questions;
            final selected = state.selectedChoices;

            return Column(
              children: [
                // Top Progress indicator
                LinearProgressIndicator(
                  value: questions.isNotEmpty ? selected.length / questions.length : 0,
                  backgroundColor: AppColors.darkSurfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 4,
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 24),
                    itemBuilder: (context, qIndex) {
                      final q = questions[qIndex];
                      final chosenChoice = selected[qIndex];

                      return GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${l10n.translate('question')} ${qIndex + 1} ${l10n.translate('of')} ${questions.length}',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q.prompt,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Choices with animated selection
                            ...List.generate(q.choices.length, (cIndex) {
                              final choiceText = q.choices[cIndex];
                              final isChoiceSelected = chosenChoice == cIndex;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () {
                                    context.read<QuizBloc>().add(
                                          QuizSelectChoiceRequested(
                                            questionIndex: qIndex,
                                            choiceIndex: cIndex,
                                          ),
                                        );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isChoiceSelected
                                          ? AppColors.primary.withValues(alpha: 0.2)
                                          : AppColors.darkSurfaceElevated,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isChoiceSelected ? AppColors.secondary : AppColors.glassBorder,
                                        width: isChoiceSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isChoiceSelected ? AppColors.secondary : Colors.transparent,
                                            border: Border.all(
                                              color: isChoiceSelected ? AppColors.secondary : AppColors.textMuted,
                                            ),
                                          ),
                                          child: isChoiceSelected
                                              ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            choiceText,
                                            style: TextStyle(
                                              color: isChoiceSelected
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                              fontSize: 14,
                                              fontWeight: isChoiceSelected ? FontWeight.bold : FontWeight.normal,
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
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Submit Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border(top: BorderSide(color: AppColors.glassBorder)),
                  ),
                  child: SafeArea(
                    child: GlowingGlassButton(
                      text: l10n.translate('submit_quiz'),
                      isLoading: state.isSubmitting,
                      onPressed: state.isAllAnswered
                          ? () => context.read<QuizBloc>().add(QuizSubmitAttemptRequested())
                          : null,
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is QuizPassedSuccess) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.success, width: 2),
                        ),
                        child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 48),
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 20),
                      Text(
                        '100% Score! (5/5)',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.translate('quiz_passed'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      GlowingGlassButton(
                        text: l10n.translate('next_lecture'),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is QuizFailedRetry) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ShakeAnimationWidget(
                  shake: _shakeTrigger,
                  onComplete: () => setState(() => _shakeTrigger = false),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.error, width: 2),
                          ),
                          child: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 44),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Score: ${state.result.score}% (${state.result.correct}/${state.result.total})',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.translate('quiz_failed'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 26),
                        GlowingGlassButton(
                          text: l10n.translate('try_again'),
                          onPressed: () {
                            context.read<QuizBloc>().add(QuizResetRequested());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 52, color: AppColors.secondary),
                    const SizedBox(height: 16),
                    const Text(
                      'No quiz questions published for this lecture yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    GlowingGlassButton(
                      text: 'Return to Course',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
