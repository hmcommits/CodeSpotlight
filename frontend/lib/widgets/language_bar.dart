import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageBar extends StatelessWidget {
  final Map<String, dynamic> languages;
  final double height;
  final bool showLegend;

  const LanguageBar({
    super.key,
    required this.languages,
    this.height = 6,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();

    final total = languages.values.fold<int>(0, (s, v) => s + (v as int? ?? 0));
    if (total == 0) return const SizedBox.shrink();

    final sorted = languages.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Row(
        children: sorted.map((e) {
          final pct = (e.value as int) / total;
          return Flexible(
            flex: (pct * 1000).round(),
            child: Container(
              height: height,
              color: AppTheme.languageColor(e.key),
            ),
          );
        }).toList(),
      ),
    );

    if (!showLegend) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar,
        const SizedBox(height: 8),
        // Legend (top 4 only to avoid overflow)
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: sorted.take(4).map((e) {
            final pct = ((e.value as int) / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.languageColor(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('${e.key} $pct%', style: AppTheme.bodySmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
