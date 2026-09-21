import 'package:equatable/equatable.dart';
import '../../../domain/entities/course_entities.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<SubjectEntity> subjects;
  final List<CourseEntity> courses;
  final String? selectedSubjectId;
  final String searchQuery;

  const CatalogLoaded({
    this.subjects = const [],
    this.courses = const [],
    this.selectedSubjectId,
    this.searchQuery = '',
  });

  CatalogLoaded copyWith({
    List<SubjectEntity>? subjects,
    List<CourseEntity>? courses,
    String? selectedSubjectId,
    bool clearSubjectId = false,
    String? searchQuery,
  }) {
    return CatalogLoaded(
      subjects: subjects ?? this.subjects,
      courses: courses ?? this.courses,
      selectedSubjectId: clearSubjectId ? null : (selectedSubjectId ?? this.selectedSubjectId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [subjects, courses, selectedSubjectId, searchQuery];
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
