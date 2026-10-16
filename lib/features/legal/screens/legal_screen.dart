import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/features/legal/providers/legal_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The legal documents (privacy, terms and refunds) behind a segmented pill.
///
/// In gate mode (the default) this is a required step: the user reads through
/// and accepts the whole set before continuing. Opened from Settings with
/// [readOnly] it is the same content with a back button and no gate.
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: kLegalDocs.length, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });
  bool _accepting = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    await ref.read(legalProvider.notifier).accept();
    // The router redirect moves us on once the accepted version updates.
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final legal = ref.watch(legalProvider);
    final gate = !widget.readOnly;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: readableInsets(context, top: AppSpacing.xs, bottom: 0),
              child: gate
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: ScreenHeader(
                        title: 'Before we begin',
                        leading: const AtlasSpark(size: 34, animated: true),
                      ),
                    )
                  : ScreenHeader(title: 'Legal', onBack: () => context.pop()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter + 4, AppSpacing.sm, AppSpacing.gutter + 4, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  gate
                      ? (legal.needsReacceptance
                          ? 'We’ve updated these documents. Please review and accept them to continue.'
                          : 'Please review these documents. You’ll need to accept them to use Atlas.')
                      : 'The documents you accepted, for reference.',
                  style: AppTypography.sans(size: 14, height: 1.45, color: p.textMuted),
                ),
              ),
            ),
            Padding(
              padding: readableInsets(context, top: AppSpacing.md, bottom: AppSpacing.xs),
              child: SegmentedPill(
                labels: [for (final d in kLegalDocs) d.label],
                index: _tabs.index,
                onChanged: (i) => _tabs.animateTo(i),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [for (final doc in kLegalDocs) _DocView(doc: doc)],
              ),
            ),
            if (gate)
              Container(
                decoration: BoxDecoration(
                  color: p.canvas,
                  border: Border(top: BorderSide(color: p.hairline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: readableInsets(context, top: AppSpacing.md, bottom: AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'By continuing you confirm you have read and agree to the Privacy '
                          'Policy, Terms of Service and Refund Policy.',
                          textAlign: TextAlign.center,
                          style: AppTypography.meta.copyWith(color: p.textMuted, height: 1.45),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PillButton(
                          label: 'I agree, continue',
                          icon: Symbols.check_rounded,
                          height: 56,
                          expand: true,
                          busy: _accepting,
                          onTap: _accepting ? null : _accept,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _DocView extends ConsumerWidget {
  const _DocView({required this.doc});
  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final content = ref.watch(legalDocContentProvider(doc.asset));

    return content.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.gutter),
        child: SkeletonList(count: 5, height: 80),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: ErrorRow(
          message: 'We couldn’t load this document.',
          onRetry: () => ref.invalidate(legalDocContentProvider(doc.asset)),
        ),
      ),
      data: (markdown) => Scrollbar(
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.sm, bottom: AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                color: p.paper,
                borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
              ),
              child: GptMarkdown(
                markdown,
                style: AppTypography.sans(size: 15, height: 1.6, color: p.textBody),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
