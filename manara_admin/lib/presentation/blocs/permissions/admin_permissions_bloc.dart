import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminPermissionsEvent extends Equatable {
  const AdminPermissionsEvent();
  @override
  List<Object?> get props => [];
}

class AdminAssignTutorSubjectRequested extends AdminPermissionsEvent {
  final String tutorId;
  final String subjectId;

  const AdminAssignTutorSubjectRequested({required this.tutorId, required this.subjectId});

  @override
  List<Object?> get props => [tutorId, subjectId];
}

class AdminUnassignTutorSubjectRequested extends AdminPermissionsEvent {
  final String tutorId;
  final String subjectId;

  const AdminUnassignTutorSubjectRequested({required this.tutorId, required this.subjectId});

  @override
  List<Object?> get props => [tutorId, subjectId];
}

class AdminGrantStudentCourseRequested extends AdminPermissionsEvent {
  final String studentId;
  final String courseId;

  const AdminGrantStudentCourseRequested({required this.studentId, required this.courseId});

  @override
  List<Object?> get props => [studentId, courseId];
}

class AdminRevokeStudentCourseRequested extends AdminPermissionsEvent {
  final String studentId;
  final String courseId;

  const AdminRevokeStudentCourseRequested({required this.studentId, required this.courseId});

  @override
  List<Object?> get props => [studentId, courseId];
}

// States
abstract class AdminPermissionsState extends Equatable {
  const AdminPermissionsState();
  @override
  List<Object?> get props => [];
}

class AdminPermissionsInitial extends AdminPermissionsState {}

class AdminPermissionsLoading extends AdminPermissionsState {}

class AdminPermissionsSuccess extends AdminPermissionsState {
  final String message;
  const AdminPermissionsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminPermissionsError extends AdminPermissionsState {
  final String message;
  const AdminPermissionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminPermissionsBloc extends Bloc<AdminPermissionsEvent, AdminPermissionsState> {
  final AdminPermissionsRepository _repository;

  AdminPermissionsBloc(this._repository) : super(AdminPermissionsInitial()) {
    on<AdminAssignTutorSubjectRequested>((event, emit) async {
      emit(AdminPermissionsLoading());
      try {
        await _repository.assignTutorSubject(tutorId: event.tutorId, subjectId: event.subjectId);
        emit(const AdminPermissionsSuccess('Subject assigned to tutor successfully'));
      } catch (e) {
        emit(AdminPermissionsError(e.toString()));
      }
    });

    on<AdminUnassignTutorSubjectRequested>((event, emit) async {
      emit(AdminPermissionsLoading());
      try {
        await _repository.unassignTutorSubject(tutorId: event.tutorId, subjectId: event.subjectId);
        emit(const AdminPermissionsSuccess('Subject unassigned from tutor'));
      } catch (e) {
        emit(AdminPermissionsError(e.toString()));
      }
    });

    on<AdminGrantStudentCourseRequested>((event, emit) async {
      emit(AdminPermissionsLoading());
      try {
        await _repository.grantStudentCourse(studentId: event.studentId, courseId: event.courseId);
        emit(const AdminPermissionsSuccess('Course enrollment granted to student'));
      } catch (e) {
        emit(AdminPermissionsError(e.toString()));
      }
    });

    on<AdminRevokeStudentCourseRequested>((event, emit) async {
      emit(AdminPermissionsLoading());
      try {
        await _repository.revokeStudentCourse(studentId: event.studentId, courseId: event.courseId);
        emit(const AdminPermissionsSuccess('Course enrollment revoked'));
      } catch (e) {
        emit(AdminPermissionsError(e.toString()));
      }
    });
  }
}
