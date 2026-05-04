import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _allStacks = [
  'All',
  'AI/ML',
  'MERN',
  'React',
  'Flutter',
  'Web3',
  'Node.js',
  'Python',
  'TypeScript',
  'Go',
  'Rust',
];

class TechFilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TechFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _allStacks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = _allStacks[i];
          final isSelected = selected == label;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => onSelected(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.25)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
