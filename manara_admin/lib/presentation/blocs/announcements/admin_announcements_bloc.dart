import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminAnnouncementsEvent extends Equatable {
  const AdminAnnouncementsEvent();
  @override
  List<Object?> get props => [];
}

class AdminFetchAnnouncementsRequested extends AdminAnnouncementsEvent {}

class AdminCreateAnnouncementRequested extends AdminAnnouncementsEvent {
  final String title;
  final String message;
  final String targetRole;
  final String? courseId;

  const AdminCreateAnnouncementRequested({
    required this.title,
    required this.message,
    this.targetRole = 'ALL',
    this.courseId,
  });

  @override
  List<Object?> get props => [title, message, targetRole, courseId];
}

// States
abstract class AdminAnnouncementsState extends Equatable {
  const AdminAnnouncementsState();
  @override
  List<Object?> get props => [];
}

class AdminAnnouncementsInitial extends AdminAnnouncementsState {}

class AdminAnnouncementsLoading extends AdminAnnouncementsState {}

class AdminAnnouncementsLoaded extends AdminAnnouncementsState {
  final List<AnnouncementEntity> announcements;
  final String? actionSuccessMessage;

  const AdminAnnouncementsLoaded({required this.announcements, this.actionSuccessMessage});

  @override
  List<Object?> get props => [announcements, actionSuccessMessage];
}

class AdminAnnouncementsError extends AdminAnnouncementsState {
  final String message;
  const AdminAnnouncementsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminAnnouncementsBloc extends Bloc<AdminAnnouncementsEvent, AdminAnnouncementsState> {
  final AdminAnnouncementRepository _repository;

  AdminAnnouncementsBloc(this._repository) : super(AdminAnnouncementsInitial()) {
    on<AdminFetchAnnouncementsRequested>(_onFetch);
    on<AdminCreateAnnouncementRequested>(_onCreate);
  }

  Future<void> _onFetch(
    AdminFetchAnnouncementsRequested event,
    Emitter<AdminAnnouncementsState> emit,
  ) async {
    emit(AdminAnnouncementsLoading());
    try {
      final items = await _repository.getAnnouncements();
      emit(AdminAnnouncementsLoaded(announcements: items));
    } catch (e) {
      emit(AdminAnnouncementsError(e.toString()));
    }
  }

  Future<void> _onCreate(
    AdminCreateAnnouncementRequested event,
    Emitter<AdminAnnouncementsState> emit,
  ) async {
    try {
      await _repository.createAnnouncement(
        title: event.title,
        message: event.message,
        targetRole: event.targetRole,
        courseId: event.courseId,
      );
      final items = await _repository.getAnnouncements();
      emit(AdminAnnouncementsLoaded(
        announcements: items,
        actionSuccessMessage: 'Announcement published successfully',
      ));
    } catch (e) {
      emit(AdminAnnouncementsError(e.toString()));
    }
  }
}
