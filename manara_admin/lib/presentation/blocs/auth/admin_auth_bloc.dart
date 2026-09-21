import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();
  @override
  List<Object?> get props => [];
}

class AdminAuthCheckRequested extends AdminAuthEvent {}

class AdminAuthLoginSubmitted extends AdminAuthEvent {
  final String username;
  final String password;

  const AdminAuthLoginSubmitted({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AdminAuthLogoutRequested extends AdminAuthEvent {}

// States
abstract class AdminAuthState extends Equatable {
  const AdminAuthState();
  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthenticated extends AdminAuthState {
  final AdminUserEntity user;

  const AdminAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AdminUnauthenticated extends AdminAuthState {
  final String? errorMessage;

  const AdminUnauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

// BLoC
class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminAuthRepository _authRepository;

  AdminAuthBloc(this._authRepository) : super(AdminAuthInitial()) {
    on<AdminAuthCheckRequested>(_onCheckRequested);
    on<AdminAuthLoginSubmitted>(_onLoginSubmitted);
    on<AdminAuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AdminAuthCheckRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(AdminAuthLoading());
    try {
      final user = await _authRepository.getCurrentAdmin();
      if (user != null) {
        emit(AdminAuthenticated(user));
      } else {
        emit(const AdminUnauthenticated());
      }
    } catch (_) {
      emit(const AdminUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    AdminAuthLoginSubmitted event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(AdminAuthLoading());
    try {
      final user = await _authRepository.login(
        username: event.username,
        password: event.password,
      );
      emit(AdminAuthenticated(user));
    } catch (e) {
      emit(AdminUnauthenticated(errorMessage: e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    AdminAuthLogoutRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AdminUnauthenticated());
  }
}
