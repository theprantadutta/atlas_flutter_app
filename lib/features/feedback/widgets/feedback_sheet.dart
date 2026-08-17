import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/core/config/store_config.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

/// Invites the user to say how Atlas is treating them.
///
/// The destination is the store listing rather than a support inbox. Atlas has
/// no feedback backend by design (the app is offline-first and stores nothing
/// it does not need), and a public review both reaches us and helps the next
/// person decide whether Atlas is for them.
Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FeedbackSheet(),
  );
}

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  static final _log = AppLog('Feedback');

  bool _opening = false;

  /// Hand the user to the store listing, where they can leave a review.
  ///
  /// The plugin's own listing intent is tried first because it lands inside the
  /// store app rather than a browser tab; a web URL is the fallback for devices
  /// without the store installed.
  Future<void> _openStoreListing() async {
    if (_opening) return;
    setState(() => _opening = true);

    var opened = false;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.openStoreListing(appStoreId: StoreConfig.appleAppId);
        opened = true;
      }
    } catch (e) {
      _log.w('Store listing intent failed, falling back to the web URL: $e');
    }

    if (!opened) {
      try {
        opened = await launchUrl(
          Uri.parse(StoreConfig.listingUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        _log.w('Could not open the store listing URL: $e');
      }
    }

    if (!mounted) return;
    setState(() => _opening = false);

    if (opened) {
      Navigator.of(context).pop();
    } else {
      AtlasToast.error(
        context,
        'Could not open ${StoreConfig.storeName} from here. You can search for '
        'Atlas there any time.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.auroraGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF10243B),
                size: 30,
              ),
            ),
          ).animate().fadeIn(duration: AppMotion.medium).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                curve: AppMotion.standard,
              ),
          AppSpacing.gapMd,
          Text(
            'How is Atlas treating you?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          AppSpacing.gapXs,
          Text(
            'Atlas is built by one person, and reviews are how it finds the '
            'people it can help. Tell us what is working, or what is not, and '
            'it goes straight onto the list.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: 'Write a review on ${StoreConfig.storeName}',
            icon: Icons.rate_review_outlined,
            isLoading: _opening,
            onPressed: _opening ? null : _openStoreListing,
          ),
          AppSpacing.gapXs,
          AppButton(
            label: 'Maybe later',
            variant: AppButtonVariant.ghost,
            onPressed: _opening ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
