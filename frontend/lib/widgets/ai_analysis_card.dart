import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Parses and renders the 3-paragraph Gemini AI summary with section labels,
/// icons, and per-paragraph fade-in animation.
class AiAnalysisCard extends StatelessWidget {
  final String aiSummary;

  const AiAnalysisCard({super.key, required this.aiSummary});

  static const _sectionMeta = [
    (
      icon: Icons.lightbulb_outline_rounded,
      label: 'What It Does',
      color: Color(0xFF7C3AED),
    ),
    (
      icon: Icons.architecture_rounded,
      label: 'Technical Architecture',
      color: Color(0xFF0EA5E9),
    ),
    (
      icon: Icons.star_outline_rounded,
      label: 'What Makes It Stand Out',
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Split into paragraphs on blank lines or double newlines
    final paragraphs = aiSummary
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // If Gemini gave us only 1 block, split into thirds by sentence count
    final sections = _normalizeParagraphs(paragraphs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.primaryGradient.createShader(b),
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              'AI-Generated Analysis · gemini-2.5-flash',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sections
        ...List.generate(sections.length, (i) {
          final meta = i < _sectionMeta.length
              ? _sectionMeta[i]
              : _sectionMeta.last;
          return _SectionBlock(
            icon: meta.icon,
            label: meta.label,
            accentColor: meta.color,
            text: sections[i],
          )
              .animate(delay: (i * 120).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, curve: Curves.easeOut);
        }),
      ],
    );
  }

  /// Ensures we always have 3 clean sections regardless of how Gemini formats.
  List<String> _normalizeParagraphs(List<String> raw) {
    if (raw.isEmpty) return ['Analysis not available.'];
    if (raw.length >= 3) return raw.take(3).toList();

    // Only 1–2 paragraphs: try splitting by sentences to make 3
    final sentences = raw
        .join(' ')
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.length < 3) return raw;

    final chunkSize = (sentences.length / 3).ceil();
    return [
      sentences.take(chunkSize).join(' '),
      sentences.skip(chunkSize).take(chunkSize).join(' '),
      sentences.skip(chunkSize * 2).join(' '),
    ].where((s) => s.isNotEmpty).toList();
  }
}

class _SectionBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final String text;

  const _SectionBlock({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label row
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Body text — preserve sentence structure
          SelectableText(
            text,
            style: AppTheme.bodyMedium.copyWith(
              height: 1.65,
              color: AppTheme.textPrimary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pending state — shown while Gemini is still generating
class AiAnalysisPending extends StatelessWidget {
  const AiAnalysisPending({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini is analyzing this repository…',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reads file structure, key files, language breakdown — auto-updates.',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1800.ms, color: AppTheme.primary.withValues(alpha: 0.08));
  }
}

/// Failed state with retry button
class AiAnalysisFailed extends StatelessWidget {
  final VoidCallback onRetry;
  const AiAnalysisFailed({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI analysis could not be completed.',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('This may be a rate limit or model error.',
                    style: AppTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warning,
              side: const BorderSide(color: AppTheme.warning),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
