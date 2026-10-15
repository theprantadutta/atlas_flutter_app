import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/pressable.dart';

/// The segmented control: a track (padding 5, full radius) with an ink pill
/// that slides between equal-width segments on the snappy spring.
class SegmentedPill extends StatefulWidget {
  const SegmentedPill({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<SegmentedPill> createState() => _SegmentedPillState();
}

class _SegmentedPillState extends State<SegmentedPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );

  @override
  void didUpdateWidget(SegmentedPill old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      if (AppMotion.reduceMotion(context)) {
        _pos.value = widget.index.toDouble();
      } else {
        _pos.animateWith(SpringSimulation(
          AppMotion.springSnappy,
          _pos.value,
          widget.index.toDouble(),
          _pos.velocity,
        ));
      }
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = widget.labels.length;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.track,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / n;
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _pos,
              builder: (context, _) => Positioned(
                left: _pos.value * segW,
                width: segW,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.action,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Pressable(
                      scale: .98,
                      haptic: PressHaptic.selection,
                      semanticLabel: widget.labels[i],
                      onTap: i == widget.index ? null : () => widget.onChanged(i),
                      child: Semantics(
                        selected: i == widget.index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.instant,
                            style: i == widget.index
                                ? AppTypography.navLabel.copyWith(color: p.onAction)
                                : AppTypography.button.copyWith(color: p.textMuted),
                            child: Text(widget.labels[i], textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
