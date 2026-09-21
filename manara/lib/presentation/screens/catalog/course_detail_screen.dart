import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/entities/exam_entities.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/student_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/star_rating_dialog.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseEntity? _course;
  List<LectureEntity> _lectures = [];
  List<ExamEntity> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final repo = context.read<CatalogRepository>();
      final studentRepo = context.read<StudentRepository>();
      final course = await repo.getCourseDetails(widget.courseId);
      List<LectureEntity> lectures = [];
      List<ExamEntity> exams = [];

      if (course.isEnrolled) {
        try {
          final learning = await studentRepo.getCourseLearningState(widget.courseId);
          lectures = (learning['lectures'] as List<dynamic>?)?.cast<LectureEntity>() ?? [];
          exams = (learning['exams'] as List<dynamic>?)?.cast<ExamEntity>() ?? [];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _course = course;
          _lectures = lectures;
          _exams = exams;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback detail
      if (mounted) {
        setState(() {
          _course = CourseEntity(
            id: widget.courseId,
            name: 'Advanced Flutter Architecture & Security',
            description:
                'Master Clean Architecture, BLoC pattern, native platform security, and device-locking authentication on Flutter for Mobile and Desktop.',
            imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600',
            price: 49.99,
            tutorId: 'tutor_1',
            subjectId: 'sub_1',
            videoCount: 12,
            ratingAverage: 4.9,
            ratingCount: 38,
            tutorName: 'Eng. Ahmad Hassan',
            isEnrolled: true,
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalization.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isGuest = authState is AuthGuest || authState is Unauthenticated;

    if (_isLoading || _course == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    final course = _course!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero Thumbnail App Bar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    size: 18,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.85),
                  child: IconButton(
                    icon: const Icon(Icons.star_outline_rounded, color: AppColors.gold, size: 20),
                    tooltip: l10n.translate('rate_course'),
                    onPressed: () {
                      if (isGuest) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in to rate this course.')),
                        );
                        return;
                      }
                      StarRatingDialog.show(
                        context,
                        title: l10n.translate('rate_course'),
                        subtitle: course.name,
                        onSubmit: (val, comment) async {
                          await context.read<StudentRepository>().rateCourse(
                                courseId: course.id,
                                value: val,
                                comment: comment,
                              );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'course_thumb_${course.id}',
                    child: Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.2),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Overview Details
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course.name,
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rating & Price Bar
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        course.ratingAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppColors.adaptiveTextPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' (${course.ratingCount} reviews)',
                        style: TextStyle(
                          color: AppColors.adaptiveTextMuted(context),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        course.price == 0 ? l10n.translate('free') : '\$${course.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tutor Profile Card
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, color: AppColors.secondary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.tutorName ?? l10n.translate('tutor'),
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                l10n.translate('tutor'),
                                style: TextStyle(
                                  color: AppColors.adaptiveTextMuted(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (isGuest) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please log in to rate the tutor.')),
                              );
                              return;
                            }
                            StarRatingDialog.show(
                              context,
                              title: l10n.translate('rate_tutor'),
                              subtitle: course.tutorName,
                              onSubmit: (val, comment) async {
                                await context.read<StudentRepository>().rateTutor(
                                      tutorId: course.tutorId,
                                      value: val,
                                      comment: comment,
                                    );
                              },
                            );
                          },
                          child: Text(
                            l10n.translate('rate_tutor'),
                            style: const TextStyle(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'About this Course',
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Curriculum / Syllabus Section
                  Text(
                    'Curriculum & Syllabus',
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_lectures.isNotEmpty) ...[
                    ..._lectures.map((lec) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: lec.locked
                                    ? (isDark ? Colors.white10 : Colors.black12)
                                    : AppColors.secondary.withValues(alpha: 0.15),
                                child: Icon(
                                  lec.locked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: lec.locked
                                      ? AppColors.adaptiveTextMuted(context)
                                      : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lesson ${lec.position}: ${lec.title}',
                                      style: TextStyle(
                                        color: AppColors.adaptiveTextPrimary(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                     if (lec.quiz != null)
                                       Text(
                                         'Quiz: ${lec.quiz!.questions.length} Questions (Pass: ${lec.quiz!.passPercent}%)',
                                         style: TextStyle(
                                           color: AppColors.adaptiveTextMuted(context),
                                           fontSize: 11,
                                         ),
                                       ),
                                  ],
                                ),
                              ),
                              if (!lec.locked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Unlocked',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_exams.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._exams.map((exam) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.title,
                                        style: TextStyle(
                                          color: AppColors.adaptiveTextPrimary(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${exam.questions.length} questions • ${exam.points} points',
                                        style: TextStyle(
                                          color: AppColors.adaptiveTextMuted(context),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ] else ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.video_collection_outlined, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                '${course.videoCount} Complete Video Lectures',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.quiz_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Sequential Quizzes with instant scoring',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.security_rounded, color: AppColors.gold, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Watermarked streaming & device-locked access',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // CTA / Player Access Guard
                  if (isGuest) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Video lectures, PDF notes, and quizzes require an active account.',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlowingGlassButton(
                      text: l10n.translate('login'),
                      onPressed: () => context.go('/login'),
                    ),
                  ] else ...[
                    GlowingGlassButton(
                      text: course.isEnrolled
                          ? 'Start / Continue Learning'
                          : 'Course Enrolled - Enter Player',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.push('/player/${course.id}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
