import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../blocs/desktop_pairing/desktop_pairing_bloc.dart';
import '../../blocs/desktop_pairing/desktop_pairing_event.dart';
import '../../blocs/desktop_pairing/desktop_pairing_state.dart';

class MobileQrScannerSheet extends StatefulWidget {
  const MobileQrScannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MobileQrScannerSheet(),
    );
  }

  @override
  State<MobileQrScannerSheet> createState() => _MobileQrScannerSheetState();
}

class _MobileQrScannerSheetState extends State<MobileQrScannerSheet> {
  final _manualCodeController = TextEditingController();
  bool _isManualInput = false;
  bool _hasDetected = false;

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  void _authorizeChallenge(String challenge) {
    if (_hasDetected) return;
    _hasDetected = true;
    context.read<DesktopPairingBloc>().add(DesktopPairingAuthorizeRequested(challenge));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: BlocConsumer<DesktopPairingBloc, DesktopPairingState>(
        listener: (context, state) {
          if (state is DesktopPairingMobileAuthorizedSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('desktop_qr_approved')),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is DesktopPairingError) {
            setState(() => _hasDetected = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DesktopPairingLoading;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate('mobile_scan_qr'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isManualInput ? Icons.camera_alt_rounded : Icons.keyboard_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _isManualInput = !_isManualInput),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('mobile_approve_desc'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Scanner viewfinder or Manual input
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isManualInput
                        ? Container(
                            color: AppColors.darkSurfaceElevated,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Manual Challenge Input',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _manualCodeController,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Paste or type desktop challenge string...',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GlowingGlassButton(
                                  text: l10n.translate('authorize'),
                                  isLoading: isLoading,
                                  onPressed: () {
                                    final text = _manualCodeController.text.trim();
                                    if (text.isNotEmpty) _authorizeChallenge(text);
                                  },
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              MobileScanner(
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                                      _authorizeChallenge(barcode.rawValue!);
                                      break;
                                    }
                                  }
                                },
                              ),
                              // Reticle overlay
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.secondary, width: 2.5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              if (isLoading)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: AppColors.secondary),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
