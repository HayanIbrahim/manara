import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/gamification/gamification_bloc.dart';
import '../../blocs/gamification/gamification_event.dart';
import '../../blocs/gamification/gamification_state.dart';
import '../../widgets/achievement_badge_widget.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationBloc>().add(GamificationLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(l10n.translate('achievements')),
      ),
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state is GamificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          if (state is GamificationLoaded) {
            final badges = state.achievements;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                return AchievementBadgeWidget(achievement: badges[index]);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
