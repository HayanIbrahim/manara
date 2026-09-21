import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();
  @override
  List<Object?> get props => [];
}

class AdminFetchUsersRequested extends AdminUsersEvent {
  final UserRole? role;
  final AccountStatus? status;
  final String? search;

  const AdminFetchUsersRequested({this.role, this.status, this.search});

  @override
  List<Object?> get props => [role, status, search];
}

class AdminToggleUserStatusRequested extends AdminUsersEvent {
  final String id;
  final AccountStatus currentStatus;

  const AdminToggleUserStatusRequested({required this.id, required this.currentStatus});

  @override
  List<Object?> get props => [id, currentStatus];
}

class AdminResetUserDeviceRequested extends AdminUsersEvent {
  final String id;

  const AdminResetUserDeviceRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class AdminUsersState extends Equatable {
  const AdminUsersState();
  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<AccountUserEntity> users;
  final String? actionSuccessMessage;

  const AdminUsersLoaded({required this.users, this.actionSuccessMessage});

  @override
  List<Object?> get props => [users, actionSuccessMessage];
}

class AdminUsersError extends AdminUsersState {
  final String message;
  const AdminUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final AdminUserRepository _repository;
  UserRole? _lastRole;
  AccountStatus? _lastStatus;
  String? _lastSearch;

  AdminUsersBloc(this._repository) : super(AdminUsersInitial()) {
    on<AdminFetchUsersRequested>(_onFetch);
    on<AdminToggleUserStatusRequested>(_onToggleStatus);
    on<AdminResetUserDeviceRequested>(_onResetUserDevice);
  }

  Future<void> _onFetch(
    AdminFetchUsersRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    _lastRole = event.role;
    _lastStatus = event.status;
    _lastSearch = event.search;

    emit(AdminUsersLoading());
    try {
      final users = await _repository.getUsers(
        role: event.role,
        status: event.status,
        search: event.search,
      );
      emit(AdminUsersLoaded(users: users));
    } catch (e) {
      emit(AdminUsersError(e.toString()));
    }
  }

  Future<void> _onToggleStatus(
    AdminToggleUserStatusRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    try {
      final targetStatus = event.currentStatus == AccountStatus.active
          ? AccountStatus.deactivated
          : AccountStatus.active;

      await _repository.updateUserStatus(id: event.id, status: targetStatus);
      final users = await _repository.getUsers(
        role: _lastRole,
        status: _lastStatus,
        search: _lastSearch,
      );
      emit(AdminUsersLoaded(
        users: users,
        actionSuccessMessage: 'Account status updated successfully',
      ));
    } catch (e) {
      emit(AdminUsersError(e.toString()));
    }
  }

  Future<void> _onResetUserDevice(
    AdminResetUserDeviceRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    try {
      await _repository.resetUserDevice(event.id);
      final users = await _repository.getUsers(
        role: _lastRole,
        status: _lastStatus,
        search: _lastSearch,
      );
      emit(AdminUsersLoaded(
        users: users,
        actionSuccessMessage: 'Device binding cleared successfully. User can now bind a new device.',
      ));
    } catch (e) {
      emit(AdminUsersError(e.toString()));
    }
  }
}
