import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/apple_sign_in_button.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/auth_scaffold.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

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
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        AtlasToast.error(context, next.error!);
      }
    });

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Pick up where you left off.',
      isBusy: authState.isLoading,
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                  hint: 'Your password',
                  icon: Symbols.lock_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.validatePassword,
                  onSubmitted: (_) => _onLogin(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            onTap: () => _showForgotPassword(context),
            haptic: PressHaptic.selection,
            semanticLabel: 'Forgot password?',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
              child: Text('Forgot password?',
                  style: AppTypography.chip.copyWith(color: context.palette.textMuted)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        PillButton(
          label: 'Log in',
          height: 56,
          expand: true,
          busy: authState.isLoading,
          onTap: authState.isLoading ? null : _onLogin,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AuthDivider(),
        const SizedBox(height: AppSpacing.lg),
        // Apple requires Sign in with Apple to appear at least as prominently
        // as other third-party sign-in options (Guideline 4.8), so it leads.
        if (AppleSignInButton.isSupported) ...[
          AppleSignInButton(onPressed: authState.isLoading ? null : _onAppleSignIn),
          const SizedBox(height: AppSpacing.xs),
        ],
        GoogleSignInButton(onPressed: authState.isLoading ? null : _onGoogleSignIn),
        const SizedBox(height: AppSpacing.lg),
        AuthFooterLink(
          leading: 'New here? ',
          action: 'Create an account',
          onTap: () => context.goNamed(RouteNames.signup),
        ),
      ],
    );
  }
}

/// Password resets need a backend endpoint (and an email sender) that Atlas
/// doesn't have yet, so instead of a button that silently does nothing this
/// explains honestly what still works.
Future<void> _showForgotPassword(BuildContext context) => showAtlasSheet<void>(
      context,
      builder: (context) {
        final p = context.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AtlasSpark(size: 36, animated: true),
              const SizedBox(height: AppSpacing.md),
              Text('Forgot your password?',
                  style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Resetting it from the app isn’t ready yet. If you first signed up with Google '
                'or Apple, use that button and you’ll go straight in. Your data on this phone '
                'is safe either way.',
                style: AppTypography.body.copyWith(color: p.textBody),
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: 'Got it',
                height: 56,
                expand: true,
                haptic: PressHaptic.selection,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
