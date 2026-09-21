import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminSubjectsEvent extends Equatable {
  const AdminSubjectsEvent();
  @override
  List<Object?> get props => [];
}

class AdminFetchSubjectsRequested extends AdminSubjectsEvent {}

class AdminCreateSubjectRequested extends AdminSubjectsEvent {
  final String name;
  final String code;
  final String? description;
  final String? iconUrl;

  const AdminCreateSubjectRequested({
    required this.name,
    required this.code,
    this.description,
    this.iconUrl,
  });

  @override
  List<Object?> get props => [name, code, description, iconUrl];
}

class AdminUpdateSubjectRequested extends AdminSubjectsEvent {
  final String id;
  final String? name;
  final String? code;
  final String? description;
  final String? iconUrl;

  const AdminUpdateSubjectRequested({
    required this.id,
    this.name,
    this.code,
    this.description,
    this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, code, description, iconUrl];
}

class AdminDeleteSubjectRequested extends AdminSubjectsEvent {
  final String id;
  const AdminDeleteSubjectRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class AdminSubjectsState extends Equatable {
  const AdminSubjectsState();
  @override
  List<Object?> get props => [];
}

class AdminSubjectsInitial extends AdminSubjectsState {}

class AdminSubjectsLoading extends AdminSubjectsState {}

class AdminSubjectsLoaded extends AdminSubjectsState {
  final List<SubjectEntity> subjects;
  final String? successMessage;

  const AdminSubjectsLoaded({required this.subjects, this.successMessage});

  @override
  List<Object?> get props => [subjects, successMessage];
}

class AdminSubjectsError extends AdminSubjectsState {
  final String message;
  const AdminSubjectsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminSubjectsBloc extends Bloc<AdminSubjectsEvent, AdminSubjectsState> {
  final AdminSubjectRepository _repository;

  AdminSubjectsBloc(this._repository) : super(AdminSubjectsInitial()) {
    on<AdminFetchSubjectsRequested>(_onFetch);
    on<AdminCreateSubjectRequested>(_onCreate);
    on<AdminUpdateSubjectRequested>(_onUpdate);
    on<AdminDeleteSubjectRequested>(_onDelete);
  }

  Future<void> _onFetch(
    AdminFetchSubjectsRequested event,
    Emitter<AdminSubjectsState> emit,
  ) async {
    emit(AdminSubjectsLoading());
    try {
      final subjects = await _repository.getSubjects();
      emit(AdminSubjectsLoaded(subjects: subjects));
    } catch (e) {
      emit(AdminSubjectsError(e.toString()));
    }
  }

  Future<void> _onCreate(
    AdminCreateSubjectRequested event,
    Emitter<AdminSubjectsState> emit,
  ) async {
    try {
      await _repository.createSubject(
        name: event.name,
        code: event.code,
        description: event.description,
        iconUrl: event.iconUrl,
      );
      final subjects = await _repository.getSubjects();
      emit(AdminSubjectsLoaded(subjects: subjects, successMessage: 'Subject created successfully'));
    } catch (e) {
      emit(AdminSubjectsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    AdminUpdateSubjectRequested event,
    Emitter<AdminSubjectsState> emit,
  ) async {
    try {
      await _repository.updateSubject(
        id: event.id,
        name: event.name,
        code: event.code,
        description: event.description,
        iconUrl: event.iconUrl,
      );
      final subjects = await _repository.getSubjects();
      emit(AdminSubjectsLoaded(subjects: subjects, successMessage: 'Subject updated successfully'));
    } catch (e) {
      emit(AdminSubjectsError(e.toString()));
    }
  }

  Future<void> _onDelete(
    AdminDeleteSubjectRequested event,
    Emitter<AdminSubjectsState> emit,
  ) async {
    try {
      await _repository.deleteSubject(event.id);
      final subjects = await _repository.getSubjects();
      emit(AdminSubjectsLoaded(subjects: subjects, successMessage: 'Subject deleted successfully'));
    } catch (e) {
      emit(AdminSubjectsError(e.toString()));
    }
  }
}
