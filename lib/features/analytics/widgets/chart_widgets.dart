import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
//  1. XP Trend Line Chart
// ═══════════════════════════════════════════════════════════════════

class XpTrendChart extends StatelessWidget {
  final List<dynamic>? data;

  const XpTrendChart({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data == null || data!.isEmpty) {
      return _EmptyChartMessage(isDark: isDark);
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < data!.length; i++) {
      final value = data![i];
      final y = value is num ? value.toDouble() : 0.0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    final maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? AppColors.cardDark : AppColors.cardLight,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} XP',
                    TextStyle(
                      color: AppColors.xpPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.xpPrimary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.xpPrimary,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.xpPrimary.withValues(alpha: 0.3),
                    AppColors.xpPrimary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  2. Completion Bar Chart
// ═══════════════════════════════════════════════════════════════════

class CompletionBarChart extends StatelessWidget {
  final List<dynamic>? data;

  const CompletionBarChart({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data == null || data!.isEmpty) {
      return _EmptyChartMessage(isDark: isDark);
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < data!.length; i++) {
      final value = data![i];
      final y = value is num ? value.toDouble() : 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              color: AppColors.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: y * 1.3 + 1,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final idx = value.toInt();
                  return Text(
                    idx < labels.length ? labels[idx] : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? AppColors.cardDark : AppColors.cardLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} tasks',
                  TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  3. Category Pie Chart
// ═══════════════════════════════════════════════════════════════════

class CategoryPieChart extends StatelessWidget {
  final Map<String, int>? data;

  const CategoryPieChart({super.key, this.data});

  static const _categoryColors = <String, Color>{
    'health': AppColors.categoryHealth,
    'fitness': AppColors.categoryFitness,
    'mindfulness': AppColors.categoryMindfulness,
    'work': AppColors.categoryWork,
    'learning': AppColors.categoryLearning,
    'social': AppColors.categorySocial,
    'creativity': AppColors.categoryCreative,
    'personal': AppColors.info,
    'career': AppColors.primary,
    'education': AppColors.categoryLearning,
    'financial': AppColors.categoryFinance,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data == null || data!.isEmpty) {
      return _EmptyChartMessage(isDark: isDark);
    }

    final total = data!.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return _EmptyChartMessage(isDark: isDark);

    final entries = data!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.map((e) {
      final color = _categoryColors[e.key.toLowerCase()] ?? AppColors.info;
      final percentage = (e.value / total * 100);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${percentage.round()}%',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((e) {
            final color =
                _categoryColors[e.key.toLowerCase()] ?? AppColors.info;
            final label =
                e.key[0].toUpperCase() + e.key.substring(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$label (${e.value})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Empty Chart Placeholder
// ═══════════════════════════════════════════════════════════════════

class _EmptyChartMessage extends StatelessWidget {
  final bool isDark;

  const _EmptyChartMessage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 36,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No data available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
