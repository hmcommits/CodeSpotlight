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

    return Hero(
      tag: 'project-card-${widget.project.id}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.025 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              // All sides must be the SAME color when borderRadius is set — Flutter rule.
              // The left accent is drawn as a separate Positioned child inside the Stack.
              border: Border.all(
                color: _hovered
                    ? langColor.withValues(alpha: 0.35)
                    : AppTheme.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: langColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // ── Language accent bar (left edge) ────────────────────────────
                // Drawn inside Stack to bypass the non-uniform border color rule
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: langColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusCard),
                        bottomLeft: Radius.circular(AppTheme.radiusCard),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: langColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Card content ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: langColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: langColor.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.project.repo,
                                  style: AppTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.project.owner,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.project.liveUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: HeartbeatBadge(
                                status: widget.project.heartbeatStatus,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        widget.project.description.isNotEmpty
                            ? widget.project.description
                            : 'No description available.',
                        style: AppTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Language bar
                      if (widget.project.languages.isNotEmpty)
                        LanguageBar(languages: widget.project.languages),

                      const Spacer(),

                      // Stats footer
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.star_rounded,
                            label: _formatNum(widget.project.stars),
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.fork_right_rounded,
                            label: _formatNum(widget.project.forks),
                            color: AppTheme.textSecondary,
                          ),
                          const Spacer(),
                          // Video pill — shown when a demo video exists
                          if (widget.project.videoUrl.isNotEmpty) ...[ 
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      size: 10,
                                      color: Colors.red.withValues(alpha: 0.8)),
                                  const SizedBox(width: 3),
                                  Text('Demo',
                                      style: AppTheme.labelSmall.copyWith(
                                          color: Colors.red.withValues(
                                              alpha: 0.85),
                                          fontSize: 9)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _StatusBadge(aiStatus: widget.project.aiStatus),
                        ],
                      ),

                      // Tech stack chips
                      if (widget.project.techStack.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children:
                              widget.project.techStack.take(3).map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall),
                                border: Border.all(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.25),
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
              ],
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

// ── Stat chip ─────────────────────────────────────────────────────────────────
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
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTheme.labelSmall.copyWith(color: color)),
      ],
    );
  }
}

// ── AI / pending status badge ─────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String aiStatus;
  const _StatusBadge({required this.aiStatus});

  @override
  Widget build(BuildContext context) {
    if (aiStatus == 'done') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 9, color: Colors.white),
            const SizedBox(width: 3),
            Text('AI',
                style: AppTheme.labelSmall.copyWith(color: Colors.white)),
          ],
        ),
      );
    }

    if (aiStatus == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Analyzing',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1500.ms,
            color: AppTheme.primary.withValues(alpha: 0.3),
          );
    }

    // failed
    return const Icon(Icons.warning_amber_rounded,
        size: 14, color: AppTheme.warning);
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 14, width: 130),
          const SizedBox(height: 6),
          _shimmerBox(height: 10, width: 80),
          const SizedBox(height: 12),
          _shimmerBox(height: 10, width: double.infinity),
          const SizedBox(height: 5),
          _shimmerBox(height: 10, width: 200),
          const SizedBox(height: 14),
          _shimmerBox(height: 6, width: double.infinity),
          const Spacer(),
          _shimmerBox(height: 10, width: 100),
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
