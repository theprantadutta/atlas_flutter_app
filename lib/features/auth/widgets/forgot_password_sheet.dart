import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/auth/auth_scaffold.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Forgot password, in three calm steps: your email, the 6-digit code from
/// the email plus a new password, then you're signed straight back in.
Future<void> showForgotPasswordSheet(BuildContext context, {String? email}) =>
    showAtlasSheet<void>(context, builder: (_) => _ForgotPasswordSheet(initialEmail: email));

enum _Step { email, code }

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({this.initialEmail});
  final String? initialEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();

  _Step _step = _Step.email;
  String? _ticket;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await ref.read(authServiceProvider).requestPasswordReset(_email.text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _ticket = ticket;
        _step = _Step.code;
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!(_codeForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(
            ticket: _ticket!,
            code: _code.text,
            newPassword: _password.text,
          );
      // Straight back in with the new password.
      await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      AtlasToast.success(context, 'New password set. Welcome back.');
    } catch (e) {
      if (mounted) setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onCode = _step == _Step.code;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: AnimatedSize(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: Alignment.centerLeft, child: AtlasSpark(size: 36, animated: true)),
            const SizedBox(height: AppSpacing.md),
            Text(onCode ? 'Check your email' : 'Forgot your password?',
                style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              onCode
                  ? 'If ${_email.text.trim()} has an Atlas account, a 6-digit code is on its way. '
                      'It works for 15 minutes.'
                  : 'We’ll email you a 6-digit code to choose a new one. Your data on this phone stays put.',
              style: AppTypography.body.copyWith(color: p.textBody),
            ),
            const SizedBox(height: AppSpacing.lg - 4),
            if (!onCode)
              Form(
                key: _emailForm,
                child: AuthField(
                  controller: _email,
                  hint: 'you@example.com',
                  icon: Symbols.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autofocus: _email.text.isEmpty,
                  validator: Validators.validateEmail,
                  onSubmitted: (_) => _sendCode(),
                ),
              )
            else
              Form(
                key: _codeForm,
                child: Column(
                  children: [
                    AuthField(
                      controller: _code,
                      hint: '6-digit code',
                      icon: Symbols.pin_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      autofocus: true,
                      validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter the 6 digits from the email',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AuthField(
                      controller: _password,
                      hint: 'New password',
                      icon: Symbols.lock_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: Validators.validatePassword,
                      onSubmitted: (_) => _reset(),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ErrorRow(message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg - 4),
            PillButton(
              label: onCode ? 'Set new password' : 'Email me a code',
              height: 56,
              expand: true,
              busy: _busy,
              onTap: onCode ? _reset : _sendCode,
            ),
            if (onCode) ...[
              const SizedBox(height: AppSpacing.xs),
              PillButton(
                label: 'Send a new code',
                variant: PillVariant.track,
                height: 52,
                expand: true,
                haptic: PressHaptic.selection,
                onTap: _busy
                    ? null
                    : () {
                        _code.clear();
                        _sendCode();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
