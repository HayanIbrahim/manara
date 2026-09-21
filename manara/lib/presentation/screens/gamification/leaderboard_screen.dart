import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/gamification_entities.dart';
import '../../blocs/gamification/gamification_bloc.dart';
import '../../blocs/gamification/gamification_event.dart';
import '../../blocs/gamification/gamification_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationBloc>().add(GamificationLoadRequested());
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
          l10n.translate('leaderboard'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<GamificationBloc>().add(GamificationLoadRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state is GamificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          if (state is GamificationLoaded) {
            final items = state.leaderboard;
            final topThree = items.take(3).toList();
            final remaining = items.skip(3).toList();

            return RefreshIndicator(
              color: AppColors.secondary,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              onRefresh: () async {
                context.read<GamificationBloc>().add(GamificationLoadRequested());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Top 3 Podium Card
                  if (topThree.isNotEmpty) ...[
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      glowColor: AppColors.gold,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Rank 2 (Silver)
                          if (topThree.length > 1)
                            _PodiumColumn(
                              entry: topThree[1],
                              rankColor: AppColors.silver,
                              height: 100,
                              avatarSize: 52,
                            ),
                          // Rank 1 (Gold)
                          _PodiumColumn(
                            entry: topThree[0],
                            rankColor: AppColors.gold,
                            height: 126,
                            avatarSize: 64,
                            isCrown: true,
                          ),
                          // Rank 3 (Bronze)
                          if (topThree.length > 2)
                            _PodiumColumn(
                              entry: topThree[2],
                              rankColor: AppColors.bronze,
                              height: 84,
                              avatarSize: 48,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Top 100 Scholars',
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Remaining List Items with Staggered Cascading Animation
                  ...List.generate(remaining.length, (index) {
                    final entry = remaining[index];

                    return AppAnimations.staggeredEntrance(
                      index: index,
                      GlassCard(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${entry.rank}',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextMuted(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : 'S',
                                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.displayName,
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.points} pts',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }

          return Center(
            child: Text(
              'No leaderboard data',
              style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
            ),
          );
        },
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntryEntity entry;
  final Color rankColor;
  final double height;
  final double avatarSize;
  final bool isCrown;

  const _PodiumColumn({
    required this.entry,
    required this.rankColor,
    required this.height,
    required this.avatarSize,
    this.isCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrown) ...[
          const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 26),
          const SizedBox(height: 4),
        ],
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                child: Text(
                  entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : 'S',
                  style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: rankColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${entry.rank}',
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.points} pts',
          style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
