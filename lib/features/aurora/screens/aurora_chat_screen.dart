import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart' show SendButton;
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Talking with Aurora. Your messages are ink, hers are paper; her
/// suggestions arrive as cards you can add with one tap.
class AuroraChatScreen extends ConsumerStatefulWidget {
  const AuroraChatScreen({super.key, this.initialPrompt});

  /// Sent as the first message (a starter, a nudge, the letter).
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
    ref.listenManual(auroraChatProvider.select((s) => s.messages.length), (_, _) => _scrollToBottom());
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ref.read(onlineProvider).value ?? true)) _sendText(seed);
      });
    }
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
        _scroll.position.maxScrollExtent + 200,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
    });
  }

  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    HapticFeedback.lightImpact();
    await ref.read(auroraChatProvider.notifier).send(t);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await _sendText(text);
  }

  Future<void> _more() async {
    final choice = await showActionSheet<String>(
      context,
      title: 'Aurora',
      actions: const [
        SheetAction(value: 'new', label: 'New conversation', icon: Symbols.refresh_rounded),
        SheetAction(value: 'voice', label: 'Aurora’s voice', icon: Symbols.tune_rounded),
      ],
    );
    if (!mounted) return;
    if (choice == 'new') ref.read(auroraChatProvider.notifier).reset();
    if (choice == 'voice') context.push('/aurora/settings');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chat = ref.watch(auroraChatProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final tone = ref.watch(auroraPreferencesProvider.select((s) => s.tone.label));

    ref.listen(auroraChatProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(auroraChatProvider.notifier).clearPaywall();
        context.push('/paywall');
      }
    });
    ref.listen(auroraChatProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        AtlasToast.error(context, err);
        ref.read(auroraChatProvider.notifier).clearError();
      }
    });

    // A conversation is the clearest case for a held column: on a tablet a
    // one-line reply would otherwise be a ribbon across the whole screen.
    return Scaffold(
      body: AdaptiveCenteredColumn(
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
              child: Row(children: [
                CircleIconButton.back(onTap: () => context.pop()),
                const SizedBox(width: 12),
                AtlasSpark(size: 34, animated: true, busy: chat.sending),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aurora', style: AppTypography.chatName.copyWith(color: p.textPrimary)),
                      Text(
                        chat.sending ? 'Thinking' : '$tone · knows your week',
                        style: AppTypography.meta.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Symbols.more_horiz_rounded,
                  semanticLabel: 'More',
                  background: Colors.transparent,
                  iconColor: p.textMuted,
                  onTap: _more,
                ),
              ]),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? _ChatEmpty(onPick: online ? _sendText : null)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MessageView(
                          index: i,
                          message: chat.messages[i],
                          done: chat.done,
                          onRevealed: () {
                            ref.read(auroraChatProvider.notifier).markRevealed(i);
                            _scrollToBottom();
                          },
                        ),
                      ),
                    ),
            ),
            _Composer(
              controller: _input,
              sending: chat.sending,
              online: online,
              quickReplies: chat.quickReplies,
              onSend: _send,
              onQuickReply: _sendText,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Messages ───────────────────────────────────────────────────────

class _MessageView extends ConsumerWidget {
  const _MessageView({
    required this.index,
    required this.message,
    required this.done,
    required this.onRevealed,
  });

  final int index;
  final ChatMessage message;
  final Set<String> done;
  final VoidCallback onRevealed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    if (message.role == ChatRole.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: _Arrive(
          fromComposer: true,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 270),
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              color: p.action,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(message.content, style: AppTypography.bubble.copyWith(color: p.onAction)),
          ),
        ),
      );
    }

    if (message.pending) {
      // Dots until the first words arrive, then the reply as it streams in.
      return Align(
        alignment: Alignment.centerLeft,
        child: _AuroraBubble(
          child: AnimatedSize(
            duration: AppMotion.instant,
            alignment: Alignment.topLeft,
            child: message.content.isEmpty
                ? const _TypingDots()
                : GptMarkdown(
                    message.content,
                    style: AppTypography.body.copyWith(color: p.textPrimary),
                  ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuroraBubble(
          child: _Reveal(
            text: message.content,
            animate: message.fresh,
            onDone: onRevealed,
          ),
        ),
        if (message.created.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final c in message.created) _CreatedNote(entity: c),
        ],
        if (message.suggestions.isNotEmpty && !message.fresh) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < message.suggestions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryFade(
                id: 'sugg-$index-${message.suggestions[i].title}',
                index: i,
                stagger: const Duration(milliseconds: 60),
                child: _SuggestionCard(
                  suggestion: message.suggestions[i],
                  done: done.contains(AuroraChatState.suggestionKey(index, message.suggestions[i])),
                  onAdd: () async {
                    final s = message.suggestions[i];
                    final n = ref.read(auroraChatProvider.notifier);
                    if (s.trackable) {
                      await n.addSuggestion(index, s);
                      if (context.mounted) AtlasToast.success(context, 'Added to Grow');
                    } else {
                      await n.remind(index, s);
                      if (context.mounted) AtlasToast.success(context, 'I’ll remind you in two hours');
                    }
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _AuroraBubble extends StatelessWidget {
  const _AuroraBubble({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: context.palette.paper,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: child,
      );
}

/// The user's bubble scales up from the composer (0.9 → 1) as it lands.
class _Arrive extends StatelessWidget {
  const _Arrive({required this.child, this.fromComposer = false});
  final Widget child;
  final bool fromComposer;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, fromComposer ? 24 * (1 - t) : 0),
          child: Transform.scale(
            scale: .9 + .1 * t,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Reveals a reply in word chunks over ~600ms (the API returns it whole),
/// then calls [onDone]. Markdown renders with italics, links in coral.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.text, required this.animate, required this.onDone});
  final String text;
  final bool animate;
  final VoidCallback onDone;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  late int _shown;
  Timer? _timer;
  late final List<int> _breaks = [
    for (final m in RegExp(r'\S+\s*').allMatches(widget.text)) m.end,
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.animate || _breaks.isEmpty) {
      _shown = _breaks.length;
      if (widget.animate) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    _shown = 0;
    const total = Duration(milliseconds: 600);
    final steps = math.min(_breaks.length, 24);
    final perStep = total ~/ steps;
    var step = 0;
    _timer = Timer.periodic(perStep, (t) {
      step++;
      if (!mounted) return t.cancel();
      setState(() => _shown = (_breaks.length * step / steps).ceil().clamp(0, _breaks.length));
      if (step >= steps) {
        t.cancel();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final text = reduce || _shown >= _breaks.length || _breaks.isEmpty
        ? widget.text
        : widget.text.substring(0, _breaks[math.max(0, _shown - 1)]);
    return AnimatedSize(
      duration: AppMotion.instant,
      alignment: Alignment.topLeft,
      child: GptMarkdown(
        text,
        style: AppTypography.body.copyWith(color: p.textPrimary),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  static const _colors = [AppColors.sunriseA, AppColors.sunriseB, AppColors.sunriseC];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: 'Aurora is typing',
      child: SizedBox(
        height: 22,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Transform.translate(
                  offset: Offset(
                      0,
                      reduce
                          ? 0
                          : -4 * math.max(0, math.sin((_c.value * 2 * math.pi) - i * .8))),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Aurora proposed something: a card with one tap to Add (habit / task) or
/// Remind me (an idea). The recommended one wears the sunrise.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.done, required this.onAdd});

  final AuroraSuggestion suggestion;
  final bool done;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = suggestion;
    final style = CategoryStyle.forItem(title: s.title, category: s.category);
    final kindLabel = switch (s.kind) { 'habit' => 'Habit', 'task' => 'Task', _ => 'Just for now' };
    final meta = [
      if (s.kind != 'idea') kindLabel,
      if (s.time != null) () {
        final parts = s.time!.split(':');
        final h = int.parse(parts[0]), m = int.parse(parts[1]);
        final h12 = h % 12 == 0 ? 12 : h % 12;
        return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'am' : 'pm'}';
      }() else if (s.kind == 'task') 'today',
      if (s.xp != null) '+${s.xp} XP',
      if (s.kind == 'idea') kindLabel,
    ].join(' · ');

    final borderColor = done
        ? AppColors.sunriseB.withValues(alpha: .6)
        : s.recommended
            ? p.recommendedBorder
            : Colors.transparent;

    final Widget pill;
    if (done) {
      pill = Container(
        key: const ValueKey('done'),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.trackable ? 'Added' : 'Set',
              style: AppTypography.sans(size: 12, weight: FontWeight.w800, height: 1, color: p.textPrimary)),
          const SizedBox(width: 4),
          AtlasIcon(Symbols.check_rounded, size: 16, color: p.textPrimary, weight: 600),
        ]),
      );
    } else {
      pill = PillButton(
        key: const ValueKey('add'),
        label: s.trackable ? 'Add' : 'Remind me',
        height: 34,
        variant: s.recommended && s.trackable
            ? PillVariant.gradient
            : s.trackable
                ? PillVariant.action
                : PillVariant.track,
        onTap: onAdd,
      );
    }

    return AnimatedContainer(
      duration: AppMotion.fast,
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          IconTile(style: style, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: AppTypography.sans(size: 14, weight: FontWeight.w700, color: p.textPrimary)),
                if (meta.isNotEmpty)
                  Text(meta, style: AppTypography.meta.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (c, a) => SizeTransition(
              sizeFactor: a,
              axis: Axis.horizontal,
              child: FadeTransition(opacity: a, child: c),
            ),
            child: pill,
          ),
        ],
      ),
    );
  }
}

/// A quiet line under a reply when Aurora created something on request.
class _CreatedNote extends StatelessWidget {
  const _CreatedNote({required this.entity});
  final AuroraCreatedEntity entity;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AtlasIcon(Symbols.check_circle_rounded, size: 16, filled: true, color: p.success),
        const SizedBox(width: 6),
        Flexible(
          child: Text('Added ${entity.type}: ${entity.title}',
              style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
        ),
      ]),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty({required this.onPick});
  final ValueChanged<String>? onPick;

  static const _ideas = ['How was my week?', 'Plan tomorrow', 'I feel stuck', 'Celebrate a small win'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.lg),
      children: [
        const Center(child: AtlasSpark(size: 72, animated: true)),
        const SizedBox(height: AppSpacing.lg),
        Text('What’s on your mind?',
            textAlign: TextAlign.center, style: AppTypography.section.copyWith(color: p.textPrimary)),
        const SizedBox(height: 6),
        Text('Aurora knows your week. Nothing here is graded.',
            textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: p.textMuted)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in _ideas)
              ChoiceChipPill(label: i, onTap: onPick == null ? null : () => onPick!(i)),
          ],
        ),
      ],
    );
  }
}

// ─── Composer ───────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.online,
    required this.quickReplies,
    required this.onSend,
    required this.onQuickReply,
  });

  final TextEditingController controller;
  final bool sending;
  final bool online;
  final List<String> quickReplies;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickReply;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final enabled = online && !sending;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, math.max(16, bottom) + 4),
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuroraUsageMeter(padding: EdgeInsets.only(bottom: 10)),
          if (!online)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                AtlasIcon(Symbols.cloud_off_rounded, size: 18, color: p.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Aurora is offline. Your plans still work.',
                      style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
                ),
              ]),
            )
          else
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final q in quickReplies) ...[
                    ChoiceChipPill(label: q, onTap: enabled ? () => onQuickReply(q) : null),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.only(left: 20, right: 6),
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: online,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => enabled ? onSend() : null,
                          style: AppTypography.sans(size: 15, color: p.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Message Aurora',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (online) _MicButton(controller: controller),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => SendButton(
                  onTap: enabled && value.text.trim().isNotEmpty ? onSend : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hold to talk: the words appear in the input as you speak. While held the
/// button grows to 1.15 and a soft sunrise ring pulses.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.controller});
  final TextEditingController controller;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  static final _speech = SpeechToText();
  static bool? _available;
  bool _listening = false;
  String _prefix = '';
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void dispose() {
    _pulse.dispose();
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      _available ??= await _speech.initialize(onError: (_) => _stop());
    } catch (_) {
      _available = false;
    }
    if (!mounted) return;
    if (_available != true) {
      AtlasToast.info(context, 'Voice input isn’t available on this device.');
      return;
    }
    HapticFeedback.mediumImpact();
    _prefix = widget.controller.text.trim();
    setState(() => _listening = true);
    if (!AppMotion.reduceMotion(context)) _pulse.repeat();
    await _speech.listen(
      onResult: (r) {
        final words = r.recognizedWords;
        final text = _prefix.isEmpty ? words : '$_prefix $words';
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _stop() async {
    if (!_listening) return;
    await _speech.stop();
    if (!mounted) return;
    _pulse.stop();
    setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: _listening ? 'Listening. Release to stop.' : 'Hold to talk',
      child: GestureDetector(
        onLongPressStart: (_) => _start(),
        onLongPressEnd: (_) => _stop(),
        onTap: () => AtlasToast.info(context, 'Hold the mic and speak.'),
        child: SizedBox.square(
          dimension: 44,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Stack(
              alignment: Alignment.center,
              children: [
                if (_listening)
                  Container(
                    width: 36 + 14 * _pulse.value,
                    height: 36 + 14 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.sunrise,
                    ),
                    foregroundDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.paper.withValues(alpha: .55 + .4 * _pulse.value),
                    ),
                  ),
                AnimatedScale(
                  scale: _listening ? 1.15 : 1,
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  child: child,
                ),
              ],
            ),
            child: AtlasIcon(Symbols.mic_rounded,
                size: 22, filled: _listening, color: _listening ? AppColors.sunriseB : p.textMuted),
          ),
        ),
      ),
    );
  }
}
