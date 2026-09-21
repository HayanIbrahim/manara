import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/course_entities.dart';
import '../../../domain/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _catalogRepository;
  List<SubjectEntity> _cachedSubjects = [];

  CatalogBloc(this._catalogRepository) : super(CatalogInitial()) {
    on<CatalogFetchRequested>(_onFetchRequested);
    on<CatalogFilterSubjectChanged>(_onFilterSubjectChanged);
    on<CatalogSearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onFetchRequested(
    CatalogFetchRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      if (_cachedSubjects.isEmpty) {
        _cachedSubjects = await _catalogRepository.getSubjects();
      }

      final courses = await _catalogRepository.searchCourses(
        query: event.query,
        subjectId: event.subjectId,
        tutorId: event.tutorId,
      );

      emit(CatalogLoaded(
        subjects: _cachedSubjects,
        courses: courses,
        selectedSubjectId: event.subjectId,
        searchQuery: event.query ?? '',
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onFilterSubjectChanged(
    CatalogFilterSubjectChanged event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    final query = currentState is CatalogLoaded ? currentState.searchQuery : null;

    emit(CatalogLoading());
    try {
      final courses = await _catalogRepository.searchCourses(
        query: query,
        subjectId: event.subjectId,
      );

      emit(CatalogLoaded(
        subjects: _cachedSubjects,
        courses: courses,
        selectedSubjectId: event.subjectId,
        searchQuery: query ?? '',
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onSearchQueryChanged(
    CatalogSearchQueryChanged event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    final subjectId = currentState is CatalogLoaded ? currentState.selectedSubjectId : null;

    emit(CatalogLoading());
    try {
      final courses = await _catalogRepository.searchCourses(
        query: event.query,
        subjectId: subjectId,
      );

      emit(CatalogLoaded(
        subjects: _cachedSubjects,
        courses: courses,
        selectedSubjectId: subjectId,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }
}
