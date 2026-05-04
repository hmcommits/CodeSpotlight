import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class HeartbeatBadge extends StatelessWidget {
  final String status; // "live" | "down" | "unknown"

  const HeartbeatBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'live' => AppTheme.success,
      'down' => AppTheme.error,
      _ => AppTheme.textMuted,
    };

    final label = switch (status) {
      'live' => 'Live',
      'down' => 'Down',
      _ => 'Unknown',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color, pulse: status == 'live'),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final bool pulse;

  const _Dot({required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
      ),
    );

    if (!pulse) return dot;

    return dot
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.4, 1.4),
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.4, 1.4),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}
