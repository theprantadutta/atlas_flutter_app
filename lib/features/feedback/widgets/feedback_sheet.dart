import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/core/config/store_config.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Invites the user to say how Atlas is treating them.
///
/// The destination is the store listing rather than a support inbox. Atlas has
/// no feedback backend by design (the app is offline-first and stores nothing
/// it does not need), and a public review both reaches us and helps the next
/// person decide whether Atlas is for them.
Future<void> showFeedbackSheet(BuildContext context) {
  return showAtlasSheet<void>(context, builder: (_) => const FeedbackSheet());
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
        'Could not open ${StoreConfig.storeName} from here. You can search for Atlas there any time.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AtlasSpark(size: 64, animated: true)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'How is Atlas treating you?',
            textAlign: TextAlign.center,
            style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Atlas is built by one person, and reviews are how it finds the people it '
            'can help. Tell us what is working, or what is not, and it goes straight '
            'onto the list.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: p.textBody),
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: 'Write a review on ${StoreConfig.storeName}',
            icon: Symbols.rate_review_rounded,
            height: 56,
            expand: true,
            busy: _opening,
            onTap: _opening ? null : _openStoreListing,
          ),
          const SizedBox(height: AppSpacing.xs),
          PillButton(
            label: 'Maybe later',
            variant: PillVariant.track,
            height: 56,
            expand: true,
            haptic: PressHaptic.selection,
            onTap: _opening ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
