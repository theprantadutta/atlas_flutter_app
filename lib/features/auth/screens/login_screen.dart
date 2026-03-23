import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';

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

  void _onGoogleSignIn() {
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
                      const SizedBox(height: 48),

                      // ─── Logo / Branding ───
                      _buildHeader(theme),

                      const SizedBox(height: 40),

                      // ─── Form ───
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validatePassword,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onSubmitted: (_) => _onLogin(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── Login Button ───
                      AppButton(
                        label: 'Log In',
                        onPressed: authState.isLoading ? null : _onLogin,
                        isLoading: authState.isLoading,
                      ),

                      const SizedBox(height: 24),

                      // ─── OR Divider ───
                      _buildOrDivider(theme),

                      const SizedBox(height: 24),

                      // ─── Google Sign In ───
                      AppButton(
                        label: 'Continue with Google',
                        variant: AppButtonVariant.outline,
                        icon: Icons.g_mobiledata_rounded,
                        onPressed:
                            authState.isLoading ? null : _onGoogleSignIn,
                      ),

                      const Spacer(),

                      // ─── Sign Up Link ───
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.signup),
                              child: Text(
                                'Sign Up',
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
        // App icon / logo container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Atlas',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Level Up Your Life',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
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
          child: Divider(
            color: theme.colorScheme.outline,
          ),
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
          child: Divider(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
