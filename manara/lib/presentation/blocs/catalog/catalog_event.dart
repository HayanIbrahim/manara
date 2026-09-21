import 'package:equatable/equatable.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => [];
}

class CatalogFetchRequested extends CatalogEvent {
  final String? query;
  final String? subjectId;
  final String? tutorId;

  const CatalogFetchRequested({this.query, this.subjectId, this.tutorId});

  @override
  List<Object?> get props => [query, subjectId, tutorId];
}

class CatalogFilterSubjectChanged extends CatalogEvent {
  final String? subjectId;
  const CatalogFilterSubjectChanged(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class CatalogSearchQueryChanged extends CatalogEvent {
  final String query;
  const CatalogSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
