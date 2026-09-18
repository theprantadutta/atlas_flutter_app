import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/features/legal/providers/legal_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';

/// The legal documents — privacy, terms and refunds — behind a tab bar.
///
/// In gate mode (the default) this is a required step: the user picks through
/// the tabs and accepts the whole set before continuing. Opened from Settings
/// with [readOnly] it is the same content with a back button and no gate.
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: kLegalDocs.length, vsync: this);
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
    final theme = Theme.of(context);
    final legal = ref.watch(legalProvider);
    final gate = !widget.readOnly;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                  AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.readOnly) ...[
                    _BackButton(onTap: () => context.pop()),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gate ? 'Before we begin' : 'Legal',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gate
                              ? (legal.needsReacceptance
                                  ? 'We’ve updated these documents. Please review and accept them to continue.'
                                  : 'Please review these documents. You’ll need to accept them to use Atlas.')
                              : 'The documents you accepted, for reference.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
              child: _LegalTabBar(controller: _tabs),
            ),

            // ── Document ──
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final doc in kLegalDocs) _DocView(doc: doc),
                ],
              ),
            ),

            // ── Accept ──
            if (gate)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                      top: BorderSide(color: theme.colorScheme.outline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'By continuing you confirm you have read and agree to '
                          'the Privacy Policy, Terms of Service and Refund Policy.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        AppSpacing.gapSm,
                        AppButton(
                          label: 'I agree, continue',
                          icon: Icons.check_rounded,
                          isLoading: _accepting,
                          onPressed: _accepting ? null : _accept,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar ────────────────────────────────────────────────────────

class _LegalTabBar extends StatelessWidget {
  const _LegalTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.auroraGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        labelColor: const Color(0xFF10243B),
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: theme.textTheme.labelLarge,
        tabs: [
          for (final doc in kLegalDocs)
            Tab(
              height: 42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(doc.icon, size: 16),
                  const SizedBox(width: AppSpacing.xxs + 2),
                  Flexible(
                    child: Text(doc.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Document body ──────────────────────────────────────────────────

class _DocView extends ConsumerWidget {
  const _DocView({required this.doc});
  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final content = ref.watch(legalDocContentProvider(doc.asset));

    return content.when(
      loading: () => const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Text(
            'We couldn’t load this document. Please try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      data: (markdown) => Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md,
              AppSpacing.gutter, AppSpacing.xl),
          child: GptMarkdown(
            markdown,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ),
      ).animate(key: ValueKey(doc.id)).fadeIn(duration: AppMotion.fast),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(Icons.arrow_back_rounded,
              size: 22, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
