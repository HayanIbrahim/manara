import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/security/security_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/api_logs_dialog.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _triggerShake = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _triggerShake = true);
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginSubmitted(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDesktop = SecurityService.instance.isDesktopPlatform ||
        MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.user.isTutor) {
              context.go('/tutor');
            } else {
              context.go('/dashboard');
            }
          } else if (state is AuthGuest) {
            context.go('/courses');
          } else if (state is Unauthenticated) {
            if (state.isDeviceMismatch || state.errorMessage != null) {
              setState(() => _triggerShake = true);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final isMismatch = state is Unauthenticated && state.isDeviceMismatch;
          final errorMessage = state is Unauthenticated ? state.errorMessage : null;

          return Stack(
            children: [
              // Ambient background glows
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.terminal_rounded, color: Colors.white70),
                  tooltip: 'API Logs & Errors',
                  onPressed: () => ApiLogsDialog.show(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: ShakeAnimationWidget(
                      shake: _triggerShake,
                      onComplete: () => setState(() => _triggerShake = false),
                      child: GlassContainer(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Platform Emblem & Title
                            Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 22,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.translate('app_name'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.security_rounded, color: AppColors.success, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.translate('device_id_bound'),
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Device mismatch / error message banner
                            if (errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        isMismatch ? l10n.translate('device_mismatch') : errorMessage,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Username
                            CustomTextField(
                              controller: _usernameController,
                              label: l10n.translate('username'),
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 18),

                            // Password
                            CustomTextField(
                              controller: _passwordController,
                              label: l10n.translate('password'),
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Primary Login Action
                            GlowingGlassButton(
                              text: l10n.translate('login'),
                              isLoading: isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 14),

                            // Desktop QR Flow Trigger (shown on desktop or wide screens)
                            if (isDesktop) ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  side: const BorderSide(color: AppColors.secondary, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => context.push('/desktop-qr'),
                                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                                label: Text(
                                  l10n.translate('generate_desktop_qr'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Register navigation
                            TextButton(
                              onPressed: () => context.push('/register'),
                              child: Text(
                                l10n.translate('signup'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ),

                            // Guest mode option
                            TextButton(
                              onPressed: () => context.read<AuthBloc>().add(AuthGuestModeSelected()),
                              child: Text(
                                l10n.translate('guest_mode'),
                                style: const TextStyle(color: AppColors.secondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
