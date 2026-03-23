import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  double _passwordStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]')
        .hasMatch(password)) {
      strength += 0.25;
    }

    setState(() => _passwordStrength = strength);
  }

  void _onCreateAccount() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
        );
  }

  void _onGoogleSignUp() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    // Show error snackbar when the error changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Main Content ───
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 36),

                      // ─── Header ───
                      _buildHeader(theme),

                      const SizedBox(height: 32),

                      // ─── Form ───
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              hint: 'John Doe',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.validateFullName,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateEmail,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Create a strong password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validatePassword,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 8),

                            // ─── Password Strength Indicator ───
                            _buildPasswordStrengthBar(theme),

                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onSubmitted: (_) => _onCreateAccount(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── Create Account Button ───
                      AppButton(
                        label: 'Create Account',
                        onPressed:
                            authState.isLoading ? null : _onCreateAccount,
                        isLoading: authState.isLoading,
                      ),

                      const SizedBox(height: 24),

                      // ─── OR Divider ───
                      _buildOrDivider(theme),

                      const SizedBox(height: 24),

                      // ─── Google Sign Up ───
                      AppButton(
                        label: 'Continue with Google',
                        variant: AppButtonVariant.outline,
                        icon: Icons.g_mobiledata_rounded,
                        onPressed:
                            authState.isLoading ? null : _onGoogleSignUp,
                      ),

                      const Spacer(),

                      // ─── Login Link ───
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.login),
                              child: Text(
                                'Log In',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Loading Overlay ───
            if (authState.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Header Widget ──────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Start your journey today',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ─── Password Strength Bar ──────────────────────────────────────

  Widget _buildPasswordStrengthBar(ThemeData theme) {
    final label = switch (_passwordStrength) {
      <= 0.0 => '',
      <= 0.25 => 'Weak',
      <= 0.5 => 'Fair',
      <= 0.75 => 'Good',
      _ => 'Strong',
    };

    final color = switch (_passwordStrength) {
      <= 0.0 => Colors.transparent,
      <= 0.25 => AppColors.error,
      <= 0.5 => AppColors.warning,
      <= 0.75 => AppColors.info,
      _ => AppColors.success,
    };

    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── OR Divider ─────────────────────────────────────────────────

  Widget _buildOrDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: theme.colorScheme.outline),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}
