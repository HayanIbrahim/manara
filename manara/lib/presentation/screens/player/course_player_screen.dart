import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/course_entities.dart';
import '../../blocs/course_player/course_player_bloc.dart';
import '../../blocs/course_player/course_player_event.dart';
import '../../blocs/course_player/course_player_state.dart';

class CoursePlayerScreen extends StatefulWidget {
  final String courseId;

  const CoursePlayerScreen({super.key, required this.courseId});

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late TabController _tabController;
  bool _isVideoInitialized = false;
  String? _activeVideoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (!kIsWeb && Platform.isWindows) {
      try {
        WindowsVideoPlayer.registerWith();
      } catch (_) {}
    }

    context.read<CoursePlayerBloc>().add(CoursePlayerLoadRequested(widget.courseId));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setupVideo(String videoUrl) {
    if (videoUrl == _activeVideoUrl && _videoController != null) return;
    _activeVideoUrl = videoUrl;

    _videoController?.dispose();
    _isVideoInitialized = false;

    // Default sample educational stream if dummy or empty
    final uri = (videoUrl.isNotEmpty && (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')))
        ? Uri.parse(videoUrl)
        : Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');

    _videoController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((err) {
        debugPrint('[CoursePlayer] Video init error: $err');
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalization.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: BlocBuilder<CoursePlayerBloc, CoursePlayerState>(
          builder: (context, state) {
            if (state is CoursePlayerLoaded) {
              return Text(
                state.activeLecture.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adaptiveTextPrimary(context),
                ),
              );
            }
            return Text(
              'Lecture Player',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.adaptiveTextPrimary(context),
              ),
            );
          },
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            tooltip: 'Reload Course',
            onPressed: () {
              context.read<CoursePlayerBloc>().add(CoursePlayerLoadRequested(widget.courseId));
            },
          ),
        ],
      ),
      body: BlocConsumer<CoursePlayerBloc, CoursePlayerState>(
        listener: (context, state) {
          if (state is CoursePlayerLoaded) {
            _setupVideo(state.activeLecture.videoUrl);
          }
        },
        builder: (context, state) {
          if (state is CoursePlayerLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          if (state is CoursePlayerLoaded) {
            final activeLecture = state.activeLecture;
            final exams = state.exams;

            if (isDesktop) {
              return Row(
                children: [
                  // Left: Video Player & PDF Notes
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildVideoPlayerSection(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildPdfViewerSection(activeLecture),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                  ),
                  // Right: Curriculum & Mandatory Quiz Drawer
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildCurriculumSection(state, l10n),
                    ),
                  ),
                ],
              );
            }

            // Mobile Layout
            return Column(
              children: [
                _buildVideoPlayerSection(),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.secondary,
                  labelColor: AppColors.secondary,
                  unselectedLabelColor: AppColors.adaptiveTextMuted(context),
                  tabs: [
                    Tab(text: l10n.translate('curriculum')),
                    Tab(text: l10n.translate('pdf_notes')),
                    Tab(text: l10n.translate('exams')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurriculumSection(state, l10n),
                      _buildPdfViewerSection(activeLecture),
                      _buildExamsSection(exams, l10n),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is CoursePlayerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Courses'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Failed to load course'));
        },
      ),
    );
  }

  Widget _buildVideoPlayerSection() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoController != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: VideoPlayer(_videoController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            // Custom Play/Pause Overlay
            if (_isVideoInitialized && _videoController != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumSection(CoursePlayerState state, AppLocalization l10n) {
    if (state is! CoursePlayerLoaded) return const SizedBox.shrink();

    final lectures = state.lectures;
    final active = state.activeLecture;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mandatory Quiz Action Banner for Active Lecture
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('mandatory_quiz'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate('quiz_requirement'),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  context.push('/quiz/${active.id}', extra: active.quiz);
                },
                child: const Text(
                  'Take Lecture Quiz (100% to Pass)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Text(
          l10n.translate('curriculum'),
          style: TextStyle(
            color: AppColors.adaptiveTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Lectures List with sequential lock indicators
        Expanded(
          child: ListView.separated(
            itemCount: lectures.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final lecture = lectures[index];
              final isSelected = lecture.id == active.id;
              final isUnlocked = state.isLectureUnlocked(lecture);

              return GlassCard(
                onTap: isUnlocked
                    ? () {
                        context.read<CoursePlayerBloc>().add(
                              CoursePlayerSelectLectureRequested(lecture),
                            );
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lecture ${lecture.position} is locked. Score 100% on previous quiz to unlock.',
                            ),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                glowColor: isSelected ? AppColors.secondary : null,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected
                          ? AppColors.secondary
                          : (isUnlocked
                              ? (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated)
                              : (isDark ? Colors.white12 : Colors.black12)),
                      child: Text(
                        '${lecture.position}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : (isUnlocked
                                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                  : AppColors.adaptiveTextMuted(context)),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lecture.title,
                        style: TextStyle(
                          color: isUnlocked
                              ? AppColors.adaptiveTextPrimary(context)
                              : AppColors.adaptiveTextMuted(context),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      isUnlocked
                          ? (isSelected ? Icons.play_arrow_rounded : Icons.check_circle_outline_rounded)
                          : Icons.lock_outline_rounded,
                      color: isSelected
                          ? AppColors.secondary
                          : (isUnlocked ? AppColors.success : AppColors.adaptiveTextMuted(context)),
                      size: 18,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPdfViewerSection(LectureEntity lecture) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (lecture.pdfUrls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: AppColors.adaptiveTextMuted(context), size: 48),
            const SizedBox(height: 12),
            Text(
              'No PDF attachments for this lecture.',
              style: TextStyle(color: AppColors.adaptiveTextSecondary(context), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final pdfUrl = lecture.pdfUrls.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
          ),
        ),
        child: SfPdfViewer.network(pdfUrl),
      ),
    );
  }

  Widget _buildExamsSection(List<dynamic> exams, AppLocalization l10n) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, color: AppColors.adaptiveTextMuted(context), size: 48),
            const SizedBox(height: 12),
            Text(
              'No exams assigned for this course.',
              style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return GlassCard(
          onTap: () => context.push('/exam/${exam.id}', extra: exam),
          child: Row(
            children: [
              const Icon(Icons.assignment_rounded, color: AppColors.secondary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: TextStyle(
                        color: AppColors.adaptiveTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.points} Points • ${exam.questions.length} Questions',
                      style: TextStyle(
                        color: AppColors.adaptiveTextMuted(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.adaptiveTextMuted(context),
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}
