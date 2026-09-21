import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/localization/localization_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isGuest = authState is AuthGuest || authState is Unauthenticated;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(l10n.translate('profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Banner Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    user != null && user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : (isGuest ? 'G' : 'U'),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.displayName ?? (isGuest ? l10n.translate('guest_mode') : 'Account'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.username != null ? '@${user!.username}' : 'Browsing without account',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                if (user != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          l10n.translate('device_id_bound'),
                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Group
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.secondary),
                  title: Text(l10n.translate('switch_language'), style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: Text(
                    l10n.isRtl ? 'العربية (AR)' : 'English (EN)',
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => context.read<LocalizationCubit>().toggleLanguage(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout or Login action
          if (isGuest) ...[
            GlowingGlassButton(
              text: l10n.translate('login'),
              onPressed: () => context.go('/login'),
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l10n.translate('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              },
            ),
          ],
        ],
      ),
    );
  }
}
