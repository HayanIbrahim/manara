import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/desktop_pairing/desktop_pairing_bloc.dart';
import '../../blocs/desktop_pairing/desktop_pairing_event.dart';
import '../../blocs/desktop_pairing/desktop_pairing_state.dart';

class DesktopQrPairingScreen extends StatefulWidget {
  const DesktopQrPairingScreen({super.key});

  @override
  State<DesktopQrPairingScreen> createState() => _DesktopQrPairingScreenState();
}

class _DesktopQrPairingScreenState extends State<DesktopQrPairingScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 180;

  @override
  void initState() {
    super.initState();
    context.read<DesktopPairingBloc>().add(DesktopPairingCreateChallengeRequested());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    final initialDiff = expiresAt.difference(DateTime.now()).inSeconds;
    setState(() {
      _remainingSeconds = initialDiff > 0 ? initialDiff : 0;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds = diff);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _countdownTimer?.cancel();
          context.read<DesktopPairingBloc>().add(DesktopPairingResetRequested());
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            l10n.translate('desktop_qr_title'),
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
            onPressed: () {
              _countdownTimer?.cancel();
              context.read<DesktopPairingBloc>().add(DesktopPairingResetRequested());
              context.pop();
            },
          ),
        ),
        body: BlocConsumer<DesktopPairingBloc, DesktopPairingState>(
          listener: (context, state) {
            if (state is DesktopPairingApprovedSuccess) {
              _countdownTimer?.cancel();
              context.read<AuthBloc>().add(AuthDesktopSessionApproved(state.user));
              if (state.user.isTutor) {
                context.go('/tutor');
              } else {
                context.go('/dashboard');
              }
            } else if (state is DesktopPairingWaitingForMobile) {
              _startCountdown(state.expiresAt);
            } else if (state is DesktopPairingError) {
              _countdownTimer?.cancel();
            }
          },
          builder: (context, state) {
            final isExpiredByCountdown =
                state is DesktopPairingWaitingForMobile && _remainingSeconds <= 0;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.secondary, width: 2),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.secondary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          l10n.translate('desktop_qr_title'),
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.translate('desktop_qr_desc'),
                          style: TextStyle(
                            color: AppColors.adaptiveTextSecondary(context),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // QR Card or Loading or Expired
                        if (state is DesktopPairingLoading) ...[
                          const SizedBox(
                            height: 240,
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.secondary),
                            ),
                          ),
                        ] else if (isExpiredByCountdown ||
                            (state is DesktopPairingError && state.isExpired)) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.timer_off_outlined,
                                    color: AppColors.error, size: 42),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.translate('desktop_qr_expired'),
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Security policy requires challenge refresh every 3 minutes.',
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextSecondary(context),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                GlowingGlassButton(
                                  text: l10n.translate('desktop_qr_refresh'),
                                  onPressed: () {
                                    context.read<DesktopPairingBloc>().add(
                                          DesktopPairingCreateChallengeRequested(),
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else if (state is DesktopPairingWaitingForMobile) ...[
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: state.challenge,
                                  version: QrVersions.auto,
                                  size: 220.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Countdown & Waiting indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _remainingSeconds < 30
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _remainingSeconds < 30
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : AppColors.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: _remainingSeconds < 30
                                      ? AppColors.error
                                      : AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Expires in ${_formatTime(_remainingSeconds)}',
                                  style: TextStyle(
                                    color: _remainingSeconds < 30
                                        ? AppColors.error
                                        : AppColors.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.translate('desktop_qr_waiting'),
                                style: TextStyle(
                                  color: AppColors.adaptiveTextSecondary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Copyable challenge code chip for dev / manual mobile entry
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: state.challenge));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Challenge code copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 14, color: AppColors.adaptiveTextMuted(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Code: ${state.challenge.length > 16 ? '${state.challenge.substring(0, 16)}...' : state.challenge}',
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextMuted(context),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (state is DesktopPairingError) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 36),
                                const SizedBox(height: 10),
                                Text(
                                  state.message,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                GlowingGlassButton(
                                  text: l10n.translate('desktop_qr_refresh'),
                                  onPressed: () {
                                    context.read<DesktopPairingBloc>().add(
                                          DesktopPairingCreateChallengeRequested(),
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
