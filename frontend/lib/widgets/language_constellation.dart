import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Animated floating bubble chart where each language is a circle
/// sized proportionally to its byte count, colored by AppTheme.languageColor.
class LanguageConstellation extends StatefulWidget {
  final Map<String, dynamic> languages; // { "Dart": 45000, "JS": 12000 }

  const LanguageConstellation({super.key, required this.languages});

  @override
  State<LanguageConstellation> createState() => _LanguageConstellationState();
}

class _LanguageConstellationState extends State<LanguageConstellation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _buildBubbles();
  }

  @override
  void didUpdateWidget(covariant LanguageConstellation old) {
    super.didUpdateWidget(old);
    if (old.languages != widget.languages) _buildBubbles();
  }

  void _buildBubbles() {
    final total = widget.languages.values
        .fold<double>(0, (s, v) => s + (v as num).toDouble());
    if (total == 0) {
      _bubbles = [];
      return;
    }

    final sorted = widget.languages.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    // Max radius 70, min 18
    final maxBytes = (sorted.first.value as num).toDouble();
    _bubbles = sorted.map((e) {
      final bytes = (e.value as num).toDouble();
      final r = 18.0 + (bytes / maxBytes) * 52.0;
      final pct = (bytes / total * 100).toStringAsFixed(1);
      return _Bubble(
        label: e.key,
        percentage: pct,
        radius: r,
        color: AppTheme.languageColor(e.key),
      );
    }).toList();

    _layoutBubbles();
  }

  void _layoutBubbles() {
    if (_bubbles.isEmpty) return;
    // Simple circle-packing layout: pack left-to-right in a row
    // with slight vertical offset based on index for visual interest
    final rng = Random(99);
    double x = 0;
    for (var i = 0; i < _bubbles.length; i++) {
      final b = _bubbles[i];
      final yOffset = (rng.nextDouble() - 0.5) * 40;
      _bubbles[i] = b.copyWith(
        x: x + b.radius,
        y: 80 + yOffset,
        floatOffset: rng.nextDouble() * pi * 2,
        floatAmount: 4 + rng.nextDouble() * 8,
      );
      x += b.radius * 2 + 12;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbles.isEmpty) {
      return Center(
        child: Text('No language data available', style: AppTheme.bodySmall),
      );
    }

    final totalWidth = _bubbles.fold<double>(0, (s, b) => s + b.radius * 2 + 12);

    return SizedBox(
      height: 170,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: 170,
              child: CustomPaint(
                painter: _ConstellationPainter(
                  bubbles: _bubbles,
                  animValue: _controller.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bubble {
  final String label;
  final String percentage;
  final double radius;
  final Color color;
  final double x;
  final double y;
  final double floatOffset;
  final double floatAmount;

  const _Bubble({
    required this.label,
    required this.percentage,
    required this.radius,
    required this.color,
    this.x = 0,
    this.y = 0,
    this.floatOffset = 0,
    this.floatAmount = 6,
  });

  _Bubble copyWith({
    double? x,
    double? y,
    double? floatOffset,
    double? floatAmount,
  }) =>
      _Bubble(
        label: label,
        percentage: percentage,
        radius: radius,
        color: color,
        x: x ?? this.x,
        y: y ?? this.y,
        floatOffset: floatOffset ?? this.floatOffset,
        floatAmount: floatAmount ?? this.floatAmount,
      );
}

class _ConstellationPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double animValue;

  _ConstellationPainter({required this.bubbles, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final b in bubbles) {
      final floatY = sin(animValue * pi * 2 + b.floatOffset) * b.floatAmount;
      final cx = b.x;
      final cy = b.y + floatY;

      // Glow
      paint
        ..color = b.color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, cy), b.radius + 6, paint);

      // Main circle
      paint
        ..color = b.color.withValues(alpha: 0.85)
        ..maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), b.radius, paint);

      // Inner highlight ring
      paint
        ..color = b.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), b.radius - 2, paint);
      paint.style = PaintingStyle.fill;

      // Label: language name
      if (b.radius > 22) {
        textPainter
          ..text = TextSpan(
            text: b.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: b.radius > 40 ? 12 : 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          )
          ..layout(maxWidth: b.radius * 2 - 6);
        textPainter.paint(
          canvas,
          Offset(cx - textPainter.width / 2, cy - textPainter.height - 2),
        );

        // Percentage below label
        textPainter
          ..text = TextSpan(
            text: '${b.percentage}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: b.radius > 40 ? 10 : 8,
              fontWeight: FontWeight.w400,
            ),
          )
          ..layout(maxWidth: b.radius * 2 - 6);
        textPainter.paint(
          canvas,
          Offset(cx - textPainter.width / 2, cy + 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      old.animValue != animValue || old.bubbles != bubbles;
}
