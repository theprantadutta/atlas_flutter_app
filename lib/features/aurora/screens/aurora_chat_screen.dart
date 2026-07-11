import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// The immersive Aurora conversation. Pushed full-screen (above the nav shell)
/// so the composer isn't crowded by the floating nav bar. Optionally opens with
/// a suggested prompt pre-filled in the composer.
class AuroraChatScreen extends ConsumerStatefulWidget {
  const AuroraChatScreen({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  ConsumerState<AuroraChatScreen> createState() => _AuroraChatScreenState();
}

class _AuroraChatScreenState extends ConsumerState<AuroraChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      _input.text = seed;
      _input.selection =
          TextSelection.collapsed(offset: _input.text.length);
    }
    // Keep pinned to the newest message as the conversation grows.
    ref.listenManual(auroraChatProvider.select((s) => s.messages.length),
        (_, _) => _scrollToBottom());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await ref.read(auroraChatProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(auroraChatProvider);

    ref.listen(auroraChatProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(auroraChatProvider.notifier).clearPaywall();
        context.push('/paywall');
      }
    });
    ref.listen(auroraChatProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        ref.read(auroraChatProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                  AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
              child: AtlasHeader(
                title: 'Aurora',
                subtitle: 'Your gentle companion',
                onBack: () => context.pop(),
                trailing: const _AuroraMark(),
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const _ChatEmpty()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ChatBubble(message: chat.messages[i]),
                      ),
                    ),
            ),
            const AuroraUsageMeter(),
            _Composer(
              controller: _input,
              sending: chat.sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── The Aurora mark (a small living orb) ───────────────────────────

class _AuroraMark extends StatelessWidget {
  const _AuroraMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.auroraGradient,
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          size: 20, color: Color(0xFF10243B)),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.auroraGradient,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 34, color: Color(0xFF10243B)),
            ),
            AppSpacing.gapMd,
            Text('Talk it through',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall),
            AppSpacing.gapSm,
            Text(
              'Tell Aurora how you’re doing, ask for a gentle reset, or try '
              '“add a habit to read before bed”.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ).animate().fadeIn(duration: AppMotion.medium),
    );
  }
}

// ─── Chat bubbles ───────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;

    final bubble = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: isUser ? AppColors.primaryGradient : null,
        color: isUser ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSpacing.radiusLg),
          topRight: const Radius.circular(AppSpacing.radiusLg),
          bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLg : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusLg),
        ),
        border: isUser ? null : Border.all(color: theme.colorScheme.outline),
      ),
      child: message.pending
          ? const _TypingDots()
          : (isUser
              ? Text(message.content,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white))
              : GptMarkdown(
                  message.content,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
                )),
    );

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: bubble,
        ),
        if (message.created.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ...message.created.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: _CreatedChip(entity: c),
              )),
        ],
      ],
    ).animate().fadeIn(duration: AppMotion.fast).slideY(
        begin: 0.1, end: 0, curve: AppMotion.standard);
  }
}

class _CreatedChip extends StatelessWidget {
  const _CreatedChip({required this.entity});
  final AuroraCreatedEntity entity;

  IconData get _icon => switch (entity.type) {
        'habit' => Icons.repeat_rounded,
        'task' => Icons.check_circle_outline_rounded,
        'goal' => Icons.flag_rounded,
        _ => Icons.add_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Added ${entity.type}: ${entity.title}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4 + 0.5 * scale),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Composer ───────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Message Aurora…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _SendButton(sending: sending, onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: sending ? null : AppColors.auroraGradient,
          color: sending
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
        ),
        child: sending
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10243B)),
      ),
    );
  }
}
