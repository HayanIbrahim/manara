import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../domain/entities/auth_entities.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/api_logs_dialog.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  DateTime? _lastSubmitTime;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final text = _codeController.text.trim().toUpperCase();
    if (text.contains('TUTOR') && _selectedRole != UserRole.tutor) {
      setState(() => _selectedRole = UserRole.tutor);
    } else if (text.contains('STUDENT') && _selectedRole != UserRole.student) {
      setState(() => _selectedRole = UserRole.student);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final now = DateTime.now();
    if (_isSubmitting || context.read<AuthBloc>().state is AuthLoading) return;
    if (_lastSubmitTime != null && now.difference(_lastSubmitTime!).inMilliseconds < 3000) {
      return; // Ignore rapid double clicks
    }
    _lastSubmitTime = now;

    final code = _codeController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty || username.isEmpty || displayName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    if (code.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup code must be at least 8 characters long.')),
      );
      return;
    }

    if (username.length < 3 || username.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be between 3 and 64 characters.')),
      );
      return;
    }

    if (password.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 10 characters long.')),
      );
      return;
    }

    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    context.read<AuthBloc>().add(
          AuthRegisterSubmitted(
            signupCode: code,
            role: _selectedRole,
            username: username,
            displayName: displayName,
            email: email.isNotEmpty ? email : null,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(l10n.translate('signup')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal_rounded),
            tooltip: 'API Logs & Errors',
            onPressed: () => ApiLogsDialog.show(context),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is! AuthLoading && _isSubmitting) {
            setState(() => _isSubmitting = false);
          }
          if (state is Authenticated) {
            if (state.user.isTutor) {
              context.go('/tutor');
            } else {
              context.go('/dashboard');
            }
          } else if (state is Unauthenticated && state.errorMessage != null) {
            String msg = state.errorMessage!;
            final upper = msg.toUpperCase();
            if (upper.contains('SIGNUP_CODE_ALREADY_USED') ||
                upper.contains('SIGNUP_CODE_ACCOUNT_MISSING') ||
                upper.contains('CONSUMED BY ANOTHER') ||
                upper.contains('ALREADY BEEN USED') ||
                upper.contains('ALREADY USED') ||
                upper.contains('ACCOUNT_MISSING')) {
              msg = 'This signup code has already been consumed or has no linked account. Please request a new single-use code from the Admin portal.';
            } else if (upper.contains('INVALID_SIGNUP_CODE') || upper.contains('EXPIRED')) {
              msg = 'The signup code is invalid or has expired.';
            } else if (upper.contains('SIGNUP_CODE_ROLE_MISMATCH') || upper.contains('ROLE MISMATCH')) {
              msg = 'Role mismatch: This signup code belongs to the ${_selectedRole == UserRole.tutor ? "Student" : "Tutor"} role.';
            } else if (upper.contains('CONFLICT') || upper.contains('ALREADY REGISTERED') || upper.contains('ALREADY EXISTS') || upper.contains('TAKEN')) {
              msg = 'This username or email is already registered. Please choose another username.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final inProgress = isLoading || _isSubmitting;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: IgnorePointer(
                  ignoring: inProgress,
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Admin single use code
                        CustomTextField(
                          controller: _codeController,
                          label: l10n.translate('signup_code'),
                          hint: 'e.g. EDU-STUDENT-... or EDU-TUTOR-...',
                          helperText: 'Role auto-selects based on code prefix',
                          prefixIcon: Icons.key_rounded,
                        ),
                        const SizedBox(height: 18),

                        // Role selection
                        Text(
                          l10n.translate('role'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Center(child: Text(l10n.translate('role_student'))),
                                selected: _selectedRole == UserRole.student,
                                onSelected: (_) => setState(() => _selectedRole = UserRole.student),
                                selectedColor: AppColors.primary.withValues(alpha: 0.3),
                                backgroundColor: AppColors.darkSurfaceElevated,
                                labelStyle: TextStyle(
                                  color: _selectedRole == UserRole.student
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: Center(child: Text(l10n.translate('role_tutor'))),
                                selected: _selectedRole == UserRole.tutor,
                                onSelected: (_) => setState(() => _selectedRole = UserRole.tutor),
                                selectedColor: AppColors.primary.withValues(alpha: 0.3),
                                backgroundColor: AppColors.darkSurfaceElevated,
                                labelStyle: TextStyle(
                                  color: _selectedRole == UserRole.tutor
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Full Name
                        CustomTextField(
                          controller: _displayNameController,
                          label: l10n.translate('display_name'),
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 18),

                        // Username
                        CustomTextField(
                          controller: _usernameController,
                          label: l10n.translate('username'),
                          helperText: '3 to 64 characters (lowercase)',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 18),

                        // Email
                        CustomTextField(
                          controller: _emailController,
                          label: l10n.translate('email'),
                          helperText: 'Optional — used for notifications',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 18),

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          label: l10n.translate('password'),
                          helperText: 'Minimum 10 characters required',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 28),

                        GlowingGlassButton(
                          text: l10n.translate('signup'),
                          isLoading: inProgress,
                          onPressed: inProgress ? null : _handleRegister,
                        ),
                        if (inProgress) ...[
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Registering account with server, please wait...',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
