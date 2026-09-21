import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final highlight = isDark
        ? AppColors.darkSurfaceElevated.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.glassBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const ShimmerSkeleton(width: 100, height: 80, borderRadius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerSkeleton(width: double.infinity, height: 16, borderRadius: 6),
                SizedBox(height: 10),
                ShimmerSkeleton(width: 140, height: 12, borderRadius: 6),
                SizedBox(height: 12),
                ShimmerSkeleton(width: 80, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
