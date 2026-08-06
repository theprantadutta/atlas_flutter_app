import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/apple_sign_in_button.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/auth_scaffold.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

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

  void _onGoogleSignUp() => ref.read(authProvider.notifier).signInWithGoogle();

  void _onAppleSignUp() => ref.read(authProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        AtlasToast.error(context, next.error!);
      }
    });

    return AuthScaffold(
      title: 'Begin your world',
      subtitle: 'A calmer way to grow, one day at a time.',
      isBusy: authState.isLoading,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _fullNameController,
                label: 'Name',
                hint: 'What should we call you?',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: Validators.validateFullName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              AppSpacing.gapMd,
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              AppSpacing.gapMd,
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a strong password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              if (_passwordController.text.isNotEmpty) ...[
                AppSpacing.gapXs,
                _PasswordStrengthBar(strength: _passwordStrength),
              ],
              AppSpacing.gapMd,
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                prefixIcon: Icons.lock_outline_rounded,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _onCreateAccount(),
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,
        AppButton(
          label: 'Create account',
          onPressed: authState.isLoading ? null : _onCreateAccount,
          isLoading: authState.isLoading,
        ),
        AppSpacing.gapLg,
        _OrDivider(theme: theme),
        AppSpacing.gapLg,
        // Apple requires Sign in with Apple to appear at least as prominently
        // as other third-party sign-in options (Guideline 4.8), so it leads.
        if (AppleSignInButton.isSupported) ...[
          AppleSignInButton(
            onPressed: authState.isLoading ? null : _onAppleSignUp,
          ),
          AppSpacing.gapMd,
        ],
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.outline,
          icon: Icons.g_mobiledata_rounded,
          onPressed: authState.isLoading ? null : _onGoogleSignUp,
        ),
        AppSpacing.gapXl,
        _FooterLink(
          leading: 'Already have an account? ',
          action: 'Log in',
          onTap: () => context.goNamed(RouteNames.login),
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final double strength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (strength) {
      <= 0.25 => 'Weak',
      <= 0.5 => 'Fair',
      <= 0.75 => 'Good',
      _ => 'Strong',
    };
    final color = switch (strength) {
      <= 0.25 => AppColors.error,
      <= 0.5 => AppColors.warning,
      <= 0.75 => AppColors.info,
      _ => AppColors.success,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: strength),
            duration: AppMotion.fast,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outline)),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.leading,
    required this.action,
    required this.onTap,
  });
  final String leading;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leading,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
