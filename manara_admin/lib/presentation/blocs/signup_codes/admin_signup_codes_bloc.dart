import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/repositories/admin_repositories.dart';

// Events
abstract class AdminSignupCodesEvent extends Equatable {
  const AdminSignupCodesEvent();
  @override
  List<Object?> get props => [];
}

class AdminFetchSignupCodesRequested extends AdminSignupCodesEvent {}

class AdminGenerateSignupCodeRequested extends AdminSignupCodesEvent {
  final UserRole role;
  final DateTime? expiresAt;

  const AdminGenerateSignupCodeRequested({required this.role, this.expiresAt});

  @override
  List<Object?> get props => [role, expiresAt];
}

// States
abstract class AdminSignupCodesState extends Equatable {
  const AdminSignupCodesState();
  @override
  List<Object?> get props => [];
}

class AdminSignupCodesInitial extends AdminSignupCodesState {}

class AdminSignupCodesLoading extends AdminSignupCodesState {}

class AdminSignupCodesLoaded extends AdminSignupCodesState {
  final List<SignupCodeEntity> codes;
  final SignupCodeEntity? newlyCreatedCode;

  const AdminSignupCodesLoaded({required this.codes, this.newlyCreatedCode});

  @override
  List<Object?> get props => [codes, newlyCreatedCode];
}

class AdminSignupCodesError extends AdminSignupCodesState {
  final String message;
  const AdminSignupCodesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminSignupCodesBloc extends Bloc<AdminSignupCodesEvent, AdminSignupCodesState> {
  final AdminSignupCodeRepository _repository;
  final Map<String, String> _knownPlaintextCodes = {};

  AdminSignupCodesBloc(this._repository) : super(AdminSignupCodesInitial()) {
    _loadStoredCodes();
    on<AdminFetchSignupCodesRequested>(_onFetch);
    on<AdminGenerateSignupCodeRequested>(_onGenerate);
  }

  Future<void> _loadStoredCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('signup_code_'));
      for (final key in keys) {
        final id = key.substring('signup_code_'.length);
        final code = prefs.getString(key);
        if (code != null && code.isNotEmpty) {
          _knownPlaintextCodes[id] = code;
        }
      }
    } catch (_) {}
  }

  Future<void> _persistCode(String id, String code) async {
    if (id.isEmpty || code.isEmpty) return;
    _knownPlaintextCodes[id] = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signup_code_$id', code);
    } catch (_) {}
  }

  List<SignupCodeEntity> _enrichWithKnownCodes(List<SignupCodeEntity> codes) {
    return codes.map((c) {
      if (c.code.isEmpty && _knownPlaintextCodes.containsKey(c.id)) {
        return SignupCodeEntity(
          id: c.id,
          code: _knownPlaintextCodes[c.id]!,
          role: c.role,
          expiresAt: c.expiresAt,
          isUsed: c.isUsed,
          usedBy: c.usedBy,
          usedAt: c.usedAt,
          createdAt: c.createdAt,
        );
      }
      return c;
    }).toList();
  }

  Future<void> _onFetch(
    AdminFetchSignupCodesRequested event,
    Emitter<AdminSignupCodesState> emit,
  ) async {
    emit(AdminSignupCodesLoading());
    try {
      await _loadStoredCodes();
      final codes = await _repository.getSignupCodes();
      final enriched = _enrichWithKnownCodes(codes);
      emit(AdminSignupCodesLoaded(codes: enriched));
    } catch (e) {
      emit(AdminSignupCodesError(e.toString()));
    }
  }

  Future<void> _onGenerate(
    AdminGenerateSignupCodeRequested event,
    Emitter<AdminSignupCodesState> emit,
  ) async {
    try {
      final created = await _repository.generateSignupCode(
        role: event.role,
        expiresAt: event.expiresAt,
      );

      final codes = await _repository.getSignupCodes();

      // If created code is not empty, associate with id
      if (created.code.isNotEmpty) {
        if (created.id.isNotEmpty) {
          await _persistCode(created.id, created.code);
        } else if (codes.isNotEmpty) {
          // If server response lacked an id, match the newest code for this role
          final matching = codes.firstWhere(
            (c) => c.role == created.role && !_knownPlaintextCodes.containsKey(c.id),
            orElse: () => codes.first,
          );
          await _persistCode(matching.id, created.code);
        }
      }

      final enriched = _enrichWithKnownCodes(codes);

      final index = enriched.indexWhere((c) =>
          (created.id.isNotEmpty && c.id == created.id) ||
          (created.code.isNotEmpty && c.code == created.code));
      if (index >= 0) {
        enriched.removeAt(index);
      }
      enriched.insert(0, created);

      emit(AdminSignupCodesLoaded(codes: enriched, newlyCreatedCode: created));
    } catch (e) {
      emit(AdminSignupCodesError(e.toString()));
    }
  }
}
