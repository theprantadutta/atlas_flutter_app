import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Shared chrome for the auth screens: the canvas, the Atlas lockup with a
/// slowly shimmering spark, a 40 display title and a calm subtitle, then the
/// form. No hero art: the spark is the one alive thing on the page.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.isBusy = false,
    this.busyLabel = 'Signing you in…',
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool isBusy;

  /// Said under the spinning spark while [isBusy], so a sign-in that waits on
  /// Google and the server reads as progress rather than a frozen screen.
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AtlasLockup(height: 26, animated: true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title,
                              style: AppTypography.screenTitle.copyWith(color: p.textPrimary)),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle,
                            style: AppTypography.sans(
                                size: 16, weight: FontWeight.w500, height: 1.45, color: p.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
          if (isBusy)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: p.canvas.withValues(alpha: .86),
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      label: busyLabel,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AtlasSpark(size: 56, busy: true),
                          const SizedBox(height: AppSpacing.md),
                          Text(busyLabel,
                              style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A Daylight form field: a white pill with a leading Material Symbol, an
/// optional show/hide eye for passwords, and errors in coral beneath.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The label lives in semantics; visually the hint and icon say it.
    return Semantics(
      label: widget.label,
      child: TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: widget.onSubmitted,
      style: AppTypography.sans(size: 16, weight: FontWeight.w600, color: p.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 10),
          child: AtlasIcon(widget.icon, size: 20, color: p.textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        suffixIcon: widget.isPassword
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleIconButton(
                  icon: _obscured ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                  size: 44,
                  iconSize: 20,
                  background: Colors.transparent,
                  iconColor: p.textMuted,
                  semanticLabel: _obscured ? 'Show password' : 'Hide password',
                  onTap: () => setState(() => _obscured = !_obscured),
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        errorMaxLines: 2,
      ),
      ),
    );
  }
}

/// "or" between the form and the social buttons.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
        ),
        Expanded(child: Divider(color: p.hairline)),
      ],
    );
  }
}

/// "New here? Create an account"
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
  });

  final String leading;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: '$leading$action',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: leading, style: AppTypography.sans(size: 15, color: p.textMuted)),
            TextSpan(
              text: action,
              style: AppTypography.sans(size: 15, weight: FontWeight.w800, color: p.textPrimary),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// "Continue with Google": a 56 track pill, the same family as Apple's.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onPressed,
      haptic: PressHaptic.light,
      semanticLabel: 'Continue with Google',
      child: AnimatedOpacity(
        duration: AppMotion.instant,
        opacity: onPressed == null ? .5 : 1,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GoogleG(size: 20),
              const SizedBox(width: 10),
              Text('Continue with Google',
                  style: AppTypography.sans(size: 15, weight: FontWeight.w700, color: p.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four-colour Google "G", drawn (brand colours are Google's, not ours).
class _GoogleG extends StatelessWidget {
  const _GoogleG({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GPainter());
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * .2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = c;
    const toRad = 3.14159265 / 180;
    canvas.drawArc(rect, -40 * toRad, -100 * toRad, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -140 * toRad, -80 * toRad, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, -220 * toRad, -90 * toRad, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, -310 * toRad, -55 * toRad, false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
