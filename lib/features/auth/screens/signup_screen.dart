import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/apple_sign_in_button.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/auth_scaffold.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

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
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]').hasMatch(password)) {
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

  void _onGoogleSignUp() => ref.read(authProvider.notifier).signInWithGoogle();

  void _onAppleSignUp() => ref.read(authProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        AtlasToast.error(context, next.error!);
      }
    });

    return AuthScaffold(
      title: 'Make your Atlas',
      subtitle: 'A kinder way to grow, one small day at a time.',
      isBusy: authState.isLoading,
      busyLabel: 'Creating your account…',
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  controller: _fullNameController,
                  label: 'Name',
                  hint: 'What should we call you?',
                  icon: Symbols.person_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.validateFullName,
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Symbols.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Symbols.lock_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.validatePassword,
                ),
                AnimatedSize(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  child: _passwordController.text.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 0),
                          child: _PasswordStrengthBar(strength: _passwordStrength),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hint: 'Type it once more',
                  icon: Symbols.lock_rounded,
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
                  onSubmitted: (_) => _onCreateAccount(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Create account',
          height: 56,
          expand: true,
          busy: authState.isLoading,
          onTap: authState.isLoading ? null : _onCreateAccount,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AuthDivider(),
        const SizedBox(height: AppSpacing.lg),
        // Apple requires Sign in with Apple to appear at least as prominently
        // as other third-party sign-in options (Guideline 4.8), so it leads.
        if (AppleSignInButton.isSupported) ...[
          AppleSignInButton(onPressed: authState.isLoading ? null : _onAppleSignUp),
          const SizedBox(height: AppSpacing.xs),
        ],
        GoogleSignInButton(onPressed: authState.isLoading ? null : _onGoogleSignUp),
        const SizedBox(height: AppSpacing.lg),
        AuthFooterLink(
          leading: 'Already have an account? ',
          action: 'Log in',
          onTap: () => context.goNamed(RouteNames.login),
        ),
      ],
    );
  }
}

/// How sturdy the password is. A sunrise fill and a calm word; never red.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final double strength;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = switch (strength) {
      <= 0.25 => 'Could be stronger',
      <= 0.5 => 'Fair',
      <= 0.75 => 'Good',
      _ => 'Strong',
    };
    return Row(
      children: [
        Expanded(child: GradientBar(value: strength, gradient: AppColors.sunriseBar)),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
      ],
    );
  }
}
