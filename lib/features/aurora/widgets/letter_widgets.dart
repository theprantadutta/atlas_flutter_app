import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/providers/letter_tts_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "SUNDAY LETTER", from the day the letter was written.
String letterKicker(AuroraReflection r) => '${weekdayName(r.createdAt).toUpperCase()} LETTER';

/// "26 Jul to 2 Aug"
String letterRange(AuroraReflection r) => dayRange(r.periodStart, r.periodEnd);

/// The text read aloud: the letter as plain prose.
String letterSpeech(AuroraReflection r) => plainText(r.content);

/// A headline whose words light up in the sunrise gradient as they are read
/// aloud. [spokenUpTo] is a character offset into [text].
class SpokenHeadline extends StatelessWidget {
  const SpokenHeadline({
    super.key,
    required this.text,
    required this.style,
    this.spokenUpTo,
  });

  final String text;
  final TextStyle style;
  final int? spokenUpTo;

  @override
  Widget build(BuildContext context) {
    final upTo = spokenUpTo;
    if (upTo == null || upTo <= 0) return Text(text, style: style);
    return LayoutBuilder(builder: (context, c) {
      final shader = AppColors.sunriseText.createShader(
        Rect.fromLTWH(0, 0, c.maxWidth, (style.fontSize ?? 32) * 3.5),
      );
      final spans = <TextSpan>[];
      final words = RegExp(r'\S+\s*').allMatches(text);
      for (final w in words) {
        final spoken = w.end <= upTo + 1;
        spans.add(TextSpan(
          text: w.group(0),
          style: spoken ? style.copyWith(foreground: Paint()..shader = shader, color: null) : null,
        ));
      }
      return Text.rich(TextSpan(style: style, children: spans));
    });
  }
}

/// Listen / Pause for a letter, as a pill.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.reflection, this.height = 46});

  final AuroraReflection reflection;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(letterTtsProvider);
    final speech = letterSpeech(reflection);
    final playing = tts.playing && tts.textId == reflection.id;
    final minutes = listenMinutes(speech);
    return PillButton(
      label: playing ? 'Pause' : 'Listen · $minutes min',
      icon: playing ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
      height: height,
      haptic: PressHaptic.light,
      onTap: () {
        final n = ref.read(letterTtsProvider.notifier);
        playing ? n.pause() : n.play(reflection.id, speech);
      },
    );
  }
}
