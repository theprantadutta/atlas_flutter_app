import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Aurora — the AI companion. A weekly reflection over your real progress, plus
/// a calm conversational space. Premium unlocks unlimited chat + quick-add.
class AuroraScreen extends ConsumerStatefulWidget {
  const AuroraScreen({super.key});

  @override
  ConsumerState<AuroraScreen> createState() => _AuroraScreenState();
}

class _AuroraScreenState extends ConsumerState<AuroraScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

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

    // Route to the paywall when a free limit is hit (chat or reflection).
    ref.listen(auroraChatProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(auroraChatProvider.notifier).clearPaywall();
        context.push('/paywall');
      }
    });
    ref.listen(reflectionGenProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(reflectionGenProvider.notifier).clearPaywall();
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
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                    AppSpacing.gutter, AppSpacing.md),
                children: [
                  const _ReflectionCard(),
                  AppSpacing.gapLg,
                  if (chat.messages.isEmpty)
                    _ChatIntro()
                  else
                    ...chat.messages.map((m) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ChatBubble(message: m),
                        )),
                ],
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

  @override
  void initState() {
    super.initState();
    // Keep pinned to the newest message as the conversation grows.
    ref.listenManual(auroraChatProvider.select((s) => s.messages.length),
        (_, _) => _scrollToBottom());
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

// ─── Reflection card ────────────────────────────────────────────────

class _ReflectionCard extends ConsumerWidget {
  const _ReflectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reflectionAsync = ref.watch(latestReflectionProvider);
    final gen = ref.watch(reflectionGenProvider);

    return reflectionAsync.when(
      loading: () => const _ReflectionSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reflection) {
        if (reflection == null) {
          return AtlasCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Weekly reflection',
                        style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'When you’re ready, Aurora can look back over your week and '
                  'reflect with you — gently, never graded.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: gen.generating
                      ? 'Reflecting…'
                      : 'Reflect on my week',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: gen.generating,
                  onPressed: gen.generating
                      ? null
                      : () => ref.read(reflectionGenProvider.notifier).generate(),
                ),
              ],
            ),
          );
        }

        return AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.spa_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text('This week with Aurora',
                        style: theme.textTheme.titleLarge),
                  ),
                  if (reflection.modelTier == 'paid') const _DeepBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              GptMarkdown(
                reflection.content,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface, height: 1.55),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    _periodLabel(reflection),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: gen.generating
                        ? null
                        : () =>
                            ref.read(reflectionGenProvider.notifier).generate(),
                    icon: gen.generating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(gen.generating ? 'Reflecting…' : 'Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppMotion.medium);
      },
    );
  }

  String _periodLabel(AuroraReflection r) {
    String d(DateTime t) => '${t.month}/${t.day}';
    return 'Week of ${d(r.periodStart)} – ${d(r.periodEnd)}';
  }
}

class _DeepBadge extends StatelessWidget {
  const _DeepBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text('Deep',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF3A2A00),
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

class _ReflectionSkeleton extends StatelessWidget {
  const _ReflectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        );
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(140),
          const SizedBox(height: AppSpacing.xs),
          bar(double.infinity),
          bar(double.infinity),
          bar(220),
        ],
      ),
    );
  }
}

// ─── Chat ───────────────────────────────────────────────────────────

class _ChatIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Talk it through',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tell Aurora how you’re doing, or try “add a habit to read before bed”.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

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
        border: isUser
            ? null
            : Border.all(color: theme.colorScheme.outline),
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
    // MediaQuery (reduce-motion) must be read here, not in initState.
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
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
