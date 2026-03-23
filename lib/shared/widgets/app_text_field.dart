import 'package:flutter/material.dart';

/// A styled text form field with modern design.
///
/// Features:
/// - Filled background
/// - Smooth focus animation
/// - Password visibility toggle with animated eye icon
/// - Prefix and suffix icon support
/// - Error display
/// - Validator callback
/// - Label and hint text
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.initialValue,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final AutovalidateMode? autovalidateMode;
  final String? initialValue;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating label above the field
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: theme.textTheme.labelMedium!.copyWith(
              color: _hasFocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: _hasFocus ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: 8),
        ],

        // Animated container to show focus border glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            initialValue: widget.initialValue,
            obscureText: widget.isPassword ? _obscureText : false,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            autovalidateMode: widget.autovalidateMode,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              prefixIcon: widget.prefixIcon != null
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Icon(
                        widget.prefixIcon,
                        size: 22,
                        color: _hasFocus
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              prefixIconConstraints: widget.prefixIcon != null
                  ? const BoxConstraints(minWidth: 48, minHeight: 48)
                  : null,
              suffixIcon: _buildSuffixIcon(theme),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.isPassword) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(_obscureText),
              size: 22,
              color: _hasFocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
          splashRadius: 20,
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: widget.suffixIcon,
      );
    }

    return null;
  }
}
