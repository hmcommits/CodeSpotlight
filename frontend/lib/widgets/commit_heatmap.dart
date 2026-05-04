import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 52-week × 7-day GitHub-style commit heatmap using CustomPainter.
/// Expects [weeklyData] as a list of up to 52 lists (each with 7 day counts).
class CommitHeatmap extends StatefulWidget {
  final List<List<int>> weeklyData; // [week][day 0=Sun..6=Sat]
  final Color accentColor;

  const CommitHeatmap({
    super.key,
    required this.weeklyData,
    this.accentColor = AppTheme.primary,
  });

  @override
  State<CommitHeatmap> createState() => _CommitHeatmapState();
}

class _CommitHeatmapState extends State<CommitHeatmap> {
  Offset? _hover;
  int? _hovWeek;
  int? _hovDay;

  @override
  Widget build(BuildContext context) {
    const cellSize = 11.0;
    const cellGap = 3.0;
    const step = cellSize + cellGap;
    final weeks = widget.weeklyData.isNotEmpty ? widget.weeklyData.length : 52;
    final canvasW = weeks * step + cellGap;
    const canvasH = 7 * step + cellGap;

    final maxCommits = widget.weeklyData.isEmpty
        ? 1
        : widget.weeklyData
            .expand((w) => w)
            .fold<int>(1, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: [
            const SizedBox(width: 2),
            for (final label in ['Mon', '', 'Wed', '', 'Fri', '', ''])
              SizedBox(
                width: step,
                child: Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: canvasW,
          height: canvasH,
          child: MouseRegion(
            onHover: (e) {
              final col = (e.localPosition.dx / step).floor();
              final row = (e.localPosition.dy / step).floor();
              if (col >= 0 &&
                  col < weeks &&
                  row >= 0 &&
                  row < 7) {
                setState(() {
                  _hover = e.localPosition;
                  _hovWeek = col;
                  _hovDay = row;
                });
              }
            },
            onExit: (_) => setState(() {
              _hover = null;
              _hovWeek = null;
              _hovDay = null;
            }),
            child: CustomPaint(
              painter: _HeatmapPainter(
                weeklyData: widget.weeklyData,
                maxCommits: maxCommits,
                accentColor: widget.accentColor,
                hovWeek: _hovWeek,
                hovDay: _hovDay,
                cellSize: cellSize,
                cellGap: cellGap,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Legend
        Row(
          children: [
            Text('Less', style: AppTheme.labelSmall.copyWith(fontSize: 9, color: AppTheme.textMuted)),
            const SizedBox(width: 4),
            for (final alpha in [0.08, 0.25, 0.5, 0.75, 1.0])
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            Text('More', style: AppTheme.labelSmall.copyWith(fontSize: 9, color: AppTheme.textMuted)),
            const Spacer(),
            if (_hovWeek != null && _hovDay != null)
              _HoverTooltip(
                weeklyData: widget.weeklyData,
                week: _hovWeek!,
                day: _hovDay!,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<List<int>> weeklyData;
  final int maxCommits;
  final Color accentColor;
  final int? hovWeek;
  final int? hovDay;
  final double cellSize;
  final double cellGap;

  _HeatmapPainter({
    required this.weeklyData,
    required this.maxCommits,
    required this.accentColor,
    required this.hovWeek,
    required this.hovDay,
    required this.cellSize,
    required this.cellGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = cellSize + cellGap;
    final paint = Paint();
    final rr = RRect.fromLTRBR;

    for (var w = 0; w < weeklyData.length; w++) {
      for (var d = 0; d < 7 && d < weeklyData[w].length; d++) {
        final count = weeklyData[w][d];
        final ratio = maxCommits == 0 ? 0.0 : count / maxCommits;
        final alpha = count == 0 ? 0.08 : 0.15 + ratio * 0.85;

        final isHovered = w == hovWeek && d == hovDay;
        paint.color = isHovered
            ? accentColor.withValues(alpha: 1.0)
            : accentColor.withValues(alpha: alpha);

        final left = w * step + cellGap;
        final top = d * step + cellGap;
        canvas.drawRRect(
          rr(left, top, left + cellSize, top + cellSize, const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.hovWeek != hovWeek || old.hovDay != hovDay || old.weeklyData != weeklyData;
}

class _HoverTooltip extends StatelessWidget {
  final List<List<int>> weeklyData;
  final int week;
  final int day;

  const _HoverTooltip({
    required this.weeklyData,
    required this.week,
    required this.day,
  });

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final count = (week < weeklyData.length && day < weeklyData[week].length)
        ? weeklyData[week][day]
        : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '${_days[day]}, Week ${week + 1}: $count commit${count == 1 ? '' : 's'}',
        style: AppTheme.labelSmall.copyWith(fontSize: 9),
      ),
    );
  }
}

// ── Loading placeholder ────────────────────────────────────────────────────────
class CommitHeatmapLoading extends StatelessWidget {
  const CommitHeatmapLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text('Loading commit history…', style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Generates dummy heatmap data for a demo or empty state.
List<List<int>> generateDemoHeatmapData() {
  final rng = Random(42);
  return List.generate(
    52,
    (_) => List.generate(7, (_) => rng.nextBool() ? rng.nextInt(12) : 0),
  );
}
