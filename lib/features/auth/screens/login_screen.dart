import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/apple_sign_in_button.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _onGoogleSignIn() => ref.read(authProvider.notifier).signInWithGoogle();

  void _onAppleSignIn() => ref.read(authProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

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

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: "Let's tend to your world.",
      isBusy: authState.isLoading,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
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
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: Validators.validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => _onLogin(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot password?'),
          ),
        ),
        AppSpacing.gapXs,
        AppButton(
          label: 'Log in',
          onPressed: authState.isLoading ? null : _onLogin,
          isLoading: authState.isLoading,
        ),
        AppSpacing.gapLg,
        _OrDivider(theme: theme),
        AppSpacing.gapLg,
        // Apple requires Sign in with Apple to appear at least as prominently
        // as other third-party sign-in options (Guideline 4.8), so it leads.
        if (AppleSignInButton.isSupported) ...[
          AppleSignInButton(
            onPressed: authState.isLoading ? null : _onAppleSignIn,
          ),
          AppSpacing.gapMd,
        ],
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.outline,
          icon: Icons.g_mobiledata_rounded,
          onPressed: authState.isLoading ? null : _onGoogleSignIn,
        ),
        AppSpacing.gapXl,
        _FooterLink(
          leading: "New here? ",
          action: 'Create an account',
          onTap: () => context.goNamed(RouteNames.signup),
        ),
        AppSpacing.gapLg,
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
