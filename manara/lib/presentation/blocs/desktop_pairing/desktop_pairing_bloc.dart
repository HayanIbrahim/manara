import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/desktop_entities.dart';
import '../../../domain/repositories/desktop_pairing_repository.dart';
import 'desktop_pairing_event.dart';
import 'desktop_pairing_state.dart';

class DesktopPairingBloc extends Bloc<DesktopPairingEvent, DesktopPairingState> {
  final DesktopPairingRepository _pairingRepository;
  Timer? _pollingTimer;
  String? _currentChallenge;

  DesktopPairingBloc(this._pairingRepository) : super(DesktopPairingInitial()) {
    on<DesktopPairingCreateChallengeRequested>(_onCreateChallenge);
    on<DesktopPairingPollTick>(_onPollTick);
    on<DesktopPairingAuthorizeRequested>(_onAuthorizeRequested);
    on<DesktopPairingResetRequested>(_onResetRequested);
  }

  Future<void> _onCreateChallenge(
    DesktopPairingCreateChallengeRequested event,
    Emitter<DesktopPairingState> emit,
  ) async {
    _stopPolling();
    emit(DesktopPairingLoading());

    try {
      final challengeData = await _pairingRepository.createChallenge();
      _currentChallenge = challengeData.challenge;

      emit(DesktopPairingWaitingForMobile(
        challenge: challengeData.challenge,
        expiresAt: challengeData.expiresAt,
        status: DesktopChallengeStatus.pending,
      ));

      _startPolling();
    } catch (e) {
      emit(DesktopPairingError(message: e.toString()));
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      add(DesktopPairingPollTick());
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _onPollTick(
    DesktopPairingPollTick event,
    Emitter<DesktopPairingState> emit,
  ) async {
    final challenge = _currentChallenge;
    if (challenge == null || state is! DesktopPairingWaitingForMobile) {
      _stopPolling();
      return;
    }

    try {
      final statusData = await _pairingRepository.getChallengeStatus(challenge);

      if (statusData.isApproved) {
        _stopPolling();
        emit(DesktopPairingLoading());
        final user = await _pairingRepository.exchangeChallenge(challenge);
        emit(DesktopPairingApprovedSuccess(user));
      } else if (statusData.isExpired) {
        _stopPolling();
        emit(const DesktopPairingError(
          message: 'The QR code challenge has expired. Please generate a new one.',
          isExpired: true,
        ));
      }
    } catch (_) {
      // Keep polling on temporary network glitch until timeout
    }
  }

  Future<void> _onAuthorizeRequested(
    DesktopPairingAuthorizeRequested event,
    Emitter<DesktopPairingState> emit,
  ) async {
    emit(DesktopPairingLoading());
    try {
      await _pairingRepository.authorizeChallenge(event.challenge);
      emit(DesktopPairingMobileAuthorizedSuccess(event.challenge));
    } catch (e) {
      emit(DesktopPairingError(message: e.toString()));
    }
  }

  void _onResetRequested(
    DesktopPairingResetRequested event,
    Emitter<DesktopPairingState> emit,
  ) {
    _stopPolling();
    _currentChallenge = null;
    emit(DesktopPairingInitial());
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
