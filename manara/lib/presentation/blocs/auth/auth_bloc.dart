import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../domain/entities/auth_entities.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthGuestModeSelected>(_onGuestModeSelected);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthDesktopSessionApproved>(_onDesktopSessionApproved);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await _authRepository.getSavedToken();
      if (token == null || token.isEmpty) {
        emit(const Unauthenticated());
        return;
      }

      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  bool _isLoggingIn = false;
  bool _isRegistering = false;

  Future<void> _onLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    if (_isLoggingIn || state is AuthLoading) return;
    _isLoggingIn = true;
    emit(AuthLoading());
    try {
      final deviceId = await _authRepository.getDeviceId();
      final user = await _authRepository.login(
        username: event.username.trim(),
        password: event.password,
        deviceId: deviceId,
      );
      emit(Authenticated(user: user));
    } on ApiException catch (e) {
      final isMismatch = e.isDeviceMismatch || e.statusCode == 403;
      emit(Unauthenticated(
        isDeviceMismatch: isMismatch,
        errorMessage: isMismatch
            ? 'Device mismatch. Contact Admin'
            : e.message,
      ));
    } catch (e) {
      emit(Unauthenticated(errorMessage: e.toString()));
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> _onRegisterSubmitted(AuthRegisterSubmitted event, Emitter<AuthState> emit) async {
    if (_isRegistering || state is AuthLoading) return;
    _isRegistering = true;
    emit(AuthLoading());
    try {
      final deviceId = await _authRepository.getDeviceId();
      final user = await _authRepository.register(
        signupCode: event.signupCode.trim(),
        role: event.role,
        username: event.username.trim(),
        email: event.email?.trim(),
        displayName: event.displayName.trim(),
        password: event.password,
        deviceId: deviceId,
      );
      emit(Authenticated(user: user));
    } on ApiException catch (e) {
      emit(Unauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(Unauthenticated(errorMessage: e.toString()));
    } finally {
      _isRegistering = false;
    }
  }

  void _onGuestModeSelected(AuthGuestModeSelected event, Emitter<AuthState> emit) {
    emit(AuthGuest());
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(const Unauthenticated());
  }

  void _onDesktopSessionApproved(AuthDesktopSessionApproved event, Emitter<AuthState> emit) {
    emit(Authenticated(user: event.user, sessionType: SessionType.desktop));
  }
}
