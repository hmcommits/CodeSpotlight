import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'heartbeat_badge.dart';
import 'language_bar.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final langColor = AppTheme.languageColor(widget.project.primaryLanguage);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border(
                    left: BorderSide(color: langColor, width: 3),
                    top: BorderSide(
                      color: _hovered
                          ? langColor.withValues(alpha: 0.4)
                          : AppTheme.border,
                    ),
                    right: BorderSide(
                      color: _hovered
                          ? langColor.withValues(alpha: 0.2)
                          : AppTheme.border,
                    ),
                    bottom: BorderSide(
                      color: _hovered
                          ? langColor.withValues(alpha: 0.2)
                          : AppTheme.border,
                    ),
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: langColor.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ──────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: langColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.project.repo,
                            style: AppTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.project.liveUrl.isNotEmpty)
                          HeartbeatBadge(
                            status: widget.project.heartbeatStatus,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.owner,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Description ─────────────────────────────────────────
                    Text(
                      widget.project.description.isNotEmpty
                          ? widget.project.description
                          : 'No description available.',
                      style: AppTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // ── Language bar ─────────────────────────────────────────
                    LanguageBar(languages: widget.project.languages),
                    const SizedBox(height: 14),

                    // ── Footer ───────────────────────────────────────────────
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.star_rounded,
                          label: _formatNum(widget.project.stars),
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.fork_right_rounded,
                          label: _formatNum(widget.project.forks),
                          color: AppTheme.textSecondary,
                        ),
                        const Spacer(),
                        if (widget.project.aiStatus == 'done') const _AiBadge(),
                      ],
                    ),
                    if (widget.project.techStack.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.project.techStack.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(t, style: AppTheme.labelSmall),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTheme.labelSmall.copyWith(color: color)),
      ],
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text('AI', style: AppTheme.labelSmall.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Shimmer loading placeholder ───────────────────────────────────────────────
class LoadingBentoCard extends StatelessWidget {
  const LoadingBentoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 14, width: 120),
          const SizedBox(height: 10),
          _shimmerBox(height: 10, width: 200),
          const SizedBox(height: 6),
          _shimmerBox(height: 10, width: 160),
          const SizedBox(height: 16),
          _shimmerBox(height: 6, width: double.infinity),
          const SizedBox(height: 12),
          _shimmerBox(height: 10, width: 80),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppTheme.surfaceLight);
  }

  Widget _shimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
