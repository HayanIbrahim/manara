import 'package:equatable/equatable.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();
  @override
  List<Object?> get props => [];
}

class StudentLoadDashboardRequested extends StudentEvent {}

class StudentRefreshRequested extends StudentEvent {}
