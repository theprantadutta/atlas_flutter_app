import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../themes/app_colors.dart';

/// A centered error display widget with icon, message, and optional retry.
///
/// Features:
/// - Large error icon at top
/// - Error message text
/// - Optional retry button with refresh icon
/// - Fade-in animation
/// - Centered layout
class AppErrorDisplay extends StatelessWidget {
  const AppErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
    this.iconSize = 56,
    this.retryLabel = 'Try Again',
    this.title,
  });

  /// The error message to display.
  final String message;

  /// Called when the retry button is tapped. If null, no button is shown.
  final VoidCallback? onRetry;

  /// Icon displayed above the message.
  final IconData icon;

  /// Color of the icon. Defaults to [AppColors.error].
  final Color? iconColor;

  /// Size of the icon.
  final double iconSize;

  /// Label text on the retry button.
  final String retryLabel;

  /// Optional title text above the message.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? AppColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Error Icon ───
            Container(
              width: iconSize + 24,
              height: iconSize + 24,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 20),

            // ─── Title (optional) ───
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 8),
            ],

            // ─── Error Message ───
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms),

            // ─── Retry Button ───
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    delay: 250.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
