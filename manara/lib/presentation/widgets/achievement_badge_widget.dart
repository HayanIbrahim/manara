import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../domain/entities/gamification_entities.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final AchievementEntity achievement;

  const AchievementBadgeWidget({super.key, required this.achievement});

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'play_circle':
        return Icons.play_circle_filled_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      glowColor: isUnlocked ? AppColors.gold : null,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked ? AppColors.goldGradient : null,
              color: isUnlocked ? null : AppColors.darkSurfaceElevated,
              border: Border.all(
                color: isUnlocked ? AppColors.gold : AppColors.glassBorder,
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              _resolveIcon(achievement.badgeIcon),
              color: isUnlocked ? Colors.black87 : AppColors.textMuted,
              size: 26,
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
                        achievement.title,
                        style: TextStyle(
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16)
                    else
                      const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progressFraction,
                      minHeight: 4,
                      backgroundColor: AppColors.darkSurfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
